defmodule GaPersonal.GCS.Client do
  @moduledoc """
  Google Cloud Storage client for media file operations.
  Uses Goth for authentication and Req for HTTP requests.

  On Cloud Run, Goth auto-discovers the service account from the metadata server.
  For local development, set GOOGLE_APPLICATION_CREDENTIALS env var.
  """

  require Logger

  @gcs_base_url "https://storage.googleapis.com"
  @signed_url_ttl 900

  def generate_signed_upload_url(gcs_path, content_type, opts \\ []) do
    ttl = Keyword.get(opts, :ttl, @signed_url_ttl)

    case generate_signed_url(gcs_path, "PUT", ttl, content_type) do
      {:ok, url} -> {:ok, url}
      {:error, reason} -> {:error, reason}
    end
  end

  def generate_signed_download_url(gcs_path, opts \\ []) do
    ttl = Keyword.get(opts, :ttl, @signed_url_ttl)

    case generate_signed_url(gcs_path, "GET", ttl) do
      {:ok, url} -> {:ok, url}
      {:error, reason} -> {:error, reason}
    end
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

    case get_service_account_credentials() do
      {:ok, %{client_email: client_email, private_key: private_key}} ->
        now = DateTime.utc_now()
        datestamp = Calendar.strftime(now, "%Y%m%d")
        timestamp = Calendar.strftime(now, "%Y%m%dT%H%M%SZ")
        credential_scope = "#{datestamp}/auto/storage/goog4_request"
        credential = "#{client_email}/#{credential_scope}"

        host = "#{bucket}.storage.googleapis.com"
        resource = "/#{gcs_path}"

        headers = %{"host" => host}
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

        canonical_headers =
          headers
          |> Enum.sort_by(&elem(&1, 0))
          |> Enum.map(fn {k, v} -> "#{k}:#{v}\n" end)
          |> Enum.join()

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

        case sign_string(string_to_sign, private_key) do
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

  defp sign_string(string, private_key) do
    try do
      [pem_entry | _] = :public_key.pem_decode(private_key)
      key = :public_key.pem_entry_decode(pem_entry)
      signature = :public_key.sign(string, :sha256, key)
      {:ok, Base.encode16(signature, case: :lower)}
    rescue
      e ->
        Logger.error("Failed to sign GCS URL: #{inspect(e)}")
        {:error, :signing_failed}
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

  defp get_service_account_credentials do
    case Application.get_env(:ga_personal, :gcs)[:credentials_json] do
      nil ->
        # On Cloud Run, try to get from metadata server via Goth config
        case Application.get_env(:ga_personal, :goth_credentials) do
          nil -> {:error, :no_credentials}
          creds when is_map(creds) ->
            {:ok, %{
              client_email: creds["client_email"],
              private_key: creds["private_key"]
            }}
        end

      json_string when is_binary(json_string) ->
        creds = Jason.decode!(json_string)
        {:ok, %{
          client_email: creds["client_email"],
          private_key: creds["private_key"]
        }}
    end
  end

  defp bucket do
    Application.get_env(:ga_personal, :gcs)[:bucket] || "ga-personal-media"
  end
end
