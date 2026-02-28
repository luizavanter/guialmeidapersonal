defmodule GaPersonal.Asaas.Client do
  @moduledoc """
  Base HTTP client for Asaas API.
  Uses Req (built on Finch) for HTTP requests.

  Configuration:
    - ASAAS_API_KEY: API key for authentication
    - ASAAS_ENVIRONMENT: "sandbox" or "production"
  """

  require Logger

  @sandbox_url "https://sandbox.asaas.com/api/v3"
  @production_url "https://api.asaas.com/v3"

  def get(path, opts \\ []) do
    request(:get, path, opts)
  end

  def post(path, body, opts \\ []) do
    request(:post, path, Keyword.put(opts, :body, body))
  end

  def put(path, body, opts \\ []) do
    request(:put, path, Keyword.put(opts, :body, body))
  end

  def delete(path, opts \\ []) do
    request(:delete, path, opts)
  end

  defp request(method, path, opts) do
    url = base_url() <> path
    api_key = api_key()

    unless api_key do
      Logger.error("Asaas API key not configured")
      {:error, :api_key_not_configured}
    else
      body = Keyword.get(opts, :body)
      query = Keyword.get(opts, :query, [])

      req_opts = [
        method: method,
        url: url,
        headers: [
          {"access_token", api_key},
          {"content-type", "application/json"},
          {"accept", "application/json"}
        ],
        connect_options: [timeout: 15_000],
        receive_timeout: 30_000
      ]

      req_opts =
        if body, do: Keyword.put(req_opts, :json, body), else: req_opts

      req_opts =
        if query != [], do: Keyword.put(req_opts, :params, query), else: req_opts

      case Req.request(req_opts) do
        {:ok, %Req.Response{status: status, body: response_body}} when status in 200..299 ->
          {:ok, response_body}

        {:ok, %Req.Response{status: status, body: response_body}} ->
          Logger.warning("Asaas API error: #{status} - #{inspect(response_body)}")
          {:error, %{status: status, body: response_body}}

        {:error, reason} ->
          Logger.error("Asaas API request failed: #{inspect(reason)}")
          {:error, reason}
      end
    end
  end

  defp base_url do
    case environment() do
      "production" -> @production_url
      _ -> @sandbox_url
    end
  end

  defp api_key do
    Application.get_env(:ga_personal, :asaas)[:api_key]
  end

  defp environment do
    Application.get_env(:ga_personal, :asaas)[:environment] || "sandbox"
  end
end
