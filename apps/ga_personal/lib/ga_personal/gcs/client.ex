defmodule GaPersonal.GCS.Client do
  @moduledoc """
  Google Cloud Storage client for media file operations.
  Uses Goth for authentication and Req for HTTP requests.

  On Cloud Run, uses IAM signBlob API for V4 signed URLs.
  For local development, set GCS_CREDENTIALS_JSON env var.
  """

  require Logger

  @gcs_base_url "https://storage.googleapis.com"
  @signed_url_ttl 900

  def generate_signed_upload_url(gcs_path, content_type, opts \\ []) do
    ttl = Keyword.get(opts, :ttl, @signed_url_ttl)
    generate_signed_url(gcs_path, "PUT", ttl, content_type)
  end

  def generate_signed_download_url(gcs_path, opts \\ []) do
    ttl = Keyword.get(opts, :ttl, @signed_url_ttl)
    generate_signed_url(gcs_path, "GET", ttl)
  end

  def delete_object(gcs_path) do
    bucket = bucket()

    case get_access_token() do
      {:ok, token} ->
        url = "#{@gcs_base_url}/storage/v1/b/#{bucket}/o/#{URI.encode(gcs_path, &URI.char_unreserved?/1)}"

        case Req.request(method: :delete, url: url, headers: [{"authorization", "Bearer #{token}"}]) do
          {:ok, %Req.Response{status: status}} when status in [200, 204] ->
            :ok

          {:ok, %Req.Response{status: 404}} ->
            {:error, :not_found}

          {:ok, %Req.Response{status: status, body: body}} ->
            Logger.warning("GCS delete error: #{status} - #{inspect(body)}")
            {:error, %{status: status, body: body}}

          {:error, reason} ->
            Logger.error("GCS delete request failed: #{inspect(reason)}")
            {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  def object_exists?(gcs_path) do
    bucket = bucket()

    case get_access_token() do
      {:ok, token} ->
        url = "#{@gcs_base_url}/storage/v1/b/#{bucket}/o/#{URI.encode(gcs_path, &URI.char_unreserved?/1)}"

        case Req.request(method: :head, url: url, headers: [{"authorization", "Bearer #{token}"}]) do
          {:ok, %Req.Response{status: 200}} -> true
          _ -> false
        end

      {:error, _} ->
        false
    end
  end

  # V4 signed URL generation
  defp generate_signed_url(gcs_path, http_method, ttl, content_type \\ nil) do
    bucket = bucket()
    now = DateTime.utc_now()
    datestamp = Calendar.strftime(now, "%Y%m%d")
    timestamp = Calendar.strftime(now, "%Y%m%dT%H%M%SZ")

    case get_signing_identity() do
      {:ok, identity} ->
        credential_scope = "#{datestamp}/auto/storage/goog4_request"
        credential = "#{identity.client_email}/#{credential_scope}"

        host = "#{bucket}.storage.googleapis.com"
        resource = "/#{gcs_path}"

        signed_headers = "host"

        query_params = %{
          "X-Goog-Algorithm" => "GOOG4-RSA-SHA256",
          "X-Goog-Credential" => credential,
          "X-Goog-Date" => timestamp,
          "X-Goog-Expires" => to_string(ttl),
          "X-Goog-SignedHeaders" => signed_headers
        }

        query_params =
          if content_type do
            Map.put(query_params, "Content-Type", content_type)
          else
            query_params
          end

        canonical_query_string =
          query_params
          |> Enum.sort_by(&elem(&1, 0))
          |> Enum.map(fn {k, v} -> "#{URI.encode(k, &URI.char_unreserved?/1)}=#{URI.encode(v, &URI.char_unreserved?/1)}" end)
          |> Enum.join("&")

        canonical_headers = "host:#{host}\n"

        canonical_request = Enum.join([
          http_method,
          resource,
          canonical_query_string,
          canonical_headers,
          signed_headers,
          "UNSIGNED-PAYLOAD"
        ], "\n")

        string_to_sign = Enum.join([
          "GOOG4-RSA-SHA256",
          timestamp,
          credential_scope,
          :crypto.hash(:sha256, canonical_request) |> Base.encode16(case: :lower)
        ], "\n")

        case sign_bytes(string_to_sign, identity) do
          {:ok, signature} ->
            signed_url = "https://#{host}#{resource}?#{canonical_query_string}&X-Goog-Signature=#{signature}"
            {:ok, signed_url}

          {:error, reason} ->
            {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Sign using local private key
  defp sign_bytes(string, %{private_key: private_key}) when is_binary(private_key) do
    try do
      [pem_entry | _] = :public_key.pem_decode(private_key)
      key = :public_key.pem_entry_decode(pem_entry)
      signature = :public_key.sign(string, :sha256, key)
      {:ok, Base.encode16(signature, case: :lower)}
    rescue
      e ->
        Logger.error("Failed to sign GCS URL locally: #{inspect(e)}")
        {:error, :signing_failed}
    end
  end

  # Sign using IAM signBlob API (for Cloud Run / metadata server auth)
  defp sign_bytes(string, %{client_email: client_email, use_iam: true}) do
    case get_access_token() do
      {:ok, token} ->
        url = "https://iam.googleapis.com/v1/projects/-/serviceAccounts/#{client_email}:signBlob"
        body = Jason.encode!(%{bytesToSign: Base.encode64(string)})

        case Req.request(
          method: :post,
          url: url,
          headers: [
            {"authorization", "Bearer #{token}"},
            {"content-type", "application/json"}
          ],
          body: body
        ) do
          {:ok, %Req.Response{status: 200, body: %{"signedBlob" => signed_blob}}} ->
            signature = signed_blob |> Base.decode64!() |> Base.encode16(case: :lower)
            {:ok, signature}

          {:ok, %Req.Response{status: status, body: resp_body}} ->
            Logger.error("IAM signBlob failed: #{status} - #{inspect(resp_body)}")
            {:error, :signing_failed}

          {:error, reason} ->
            Logger.error("IAM signBlob request failed: #{inspect(reason)}")
            {:error, :signing_failed}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_access_token do
    case Goth.fetch(GaPersonal.Goth) do
      {:ok, %{token: token}} -> {:ok, token}
      {:error, reason} ->
        Logger.error("Failed to get GCS access token: #{inspect(reason)}")
        {:error, :auth_failed}
    end
  end

  # Get signing identity — either from local credentials or Cloud Run metadata
  defp get_signing_identity do
    cond do
      # Local credentials with private key
      creds = Application.get_env(:ga_personal, :goth_credentials) ->
        {:ok, %{
          client_email: creds["client_email"],
          private_key: creds["private_key"]
        }}

      # Cloud Run — use IAM signBlob API
      System.get_env("K_SERVICE") ->
        case get_service_account_email() do
          {:ok, email} ->
            {:ok, %{client_email: email, use_iam: true}}

          {:error, reason} ->
            {:error, reason}
        end

      true ->
        {:error, :no_credentials}
    end
  end

  # Get service account email from metadata server (Cloud Run)
  defp get_service_account_email do
    url = "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/email"

    case Req.request(method: :get, url: url, headers: [{"metadata-flavor", "Google"}]) do
      {:ok, %Req.Response{status: 200, body: email}} when is_binary(email) ->
        {:ok, email}

      {:ok, resp} ->
        Logger.error("Failed to get SA email from metadata: #{inspect(resp)}")
        {:error, :metadata_unavailable}

      {:error, reason} ->
        Logger.error("Metadata server request failed: #{inspect(reason)}")
        {:error, :metadata_unavailable}
    end
  end

  defp bucket do
    Application.get_env(:ga_personal, :gcs)[:bucket] || "ga-personal-media"
  end
end
