defmodule GaPersonal.AI.Client do
  @moduledoc """
  Centralized Claude API client for AI analysis features.
  Supports text and multimodal (image + text) messages.
  Uses Req for HTTP requests, following the Asaas.Client pattern.

  Configuration:
    - ANTHROPIC_API_KEY: API key for authentication
  """

  require Logger

  @api_url "https://api.anthropic.com/v1/messages"
  @api_version "2023-06-01"

  @model_haiku "claude-haiku-4-5-20251001"
  @model_sonnet "claude-haiku-4-5-20251001"

  @doc """
  Sends a text-only message to Claude.
  """
  def chat(prompt, opts \\ []) do
    model = Keyword.get(opts, :model, :haiku)
    max_tokens = Keyword.get(opts, :max_tokens, 4096)
    system = Keyword.get(opts, :system)

    messages = [%{role: "user", content: prompt}]
    request(messages, model, max_tokens, system)
  end

  @doc """
  Sends an image + text message to Claude for visual analysis.
  `image_data` should be a base64-encoded string.
  `media_type` should be "image/jpeg", "image/png", or "image/webp".
  """
  def analyze_image(image_data, media_type, prompt, opts \\ []) do
    model = Keyword.get(opts, :model, :haiku)
    max_tokens = Keyword.get(opts, :max_tokens, 4096)
    system = Keyword.get(opts, :system)

    messages = [
      %{
        role: "user",
        content: [
          %{
            type: "image",
            source: %{
              type: "base64",
              media_type: media_type,
              data: image_data
            }
          },
          %{type: "text", text: prompt}
        ]
      }
    ]

    request(messages, model, max_tokens, system)
  end

  @doc """
  Sends an image from a URL to Claude for analysis.
  Downloads the image first, then sends as base64.
  """
  def analyze_image_url(image_url, media_type, prompt, opts \\ []) do
    case download_image(image_url) do
      {:ok, image_bytes} ->
        image_data = Base.encode64(image_bytes)
        analyze_image(image_data, media_type, prompt, opts)

      {:error, reason} ->
        {:error, {:download_failed, reason}}
    end
  end

  defp request(messages, model, max_tokens, system) do
    api_key = api_key()

    unless api_key do
      Logger.error("Anthropic API key not configured")
      {:error, :api_key_not_configured}
    else
      body = %{
        model: resolve_model(model),
        max_tokens: max_tokens,
        messages: messages
      }

      body = if system, do: Map.put(body, :system, system), else: body

      start_time = System.monotonic_time(:millisecond)

      case Req.request(
        method: :post,
        url: @api_url,
        headers: [
          {"x-api-key", api_key},
          {"anthropic-version", @api_version},
          {"content-type", "application/json"}
        ],
        json: body,
        connect_options: [timeout: 30_000],
        receive_timeout: 120_000
      ) do
        {:ok, %Req.Response{status: 200, body: response_body}} ->
          elapsed = System.monotonic_time(:millisecond) - start_time

          text_content =
            response_body
            |> Map.get("content", [])
            |> Enum.find(%{}, &(&1["type"] == "text"))
            |> Map.get("text", "")

          usage = Map.get(response_body, "usage", %{})
          tokens_used = Map.get(usage, "input_tokens", 0) + Map.get(usage, "output_tokens", 0)

          {:ok, %{
            text: text_content,
            model: response_body["model"],
            tokens_used: tokens_used,
            input_tokens: Map.get(usage, "input_tokens", 0),
            output_tokens: Map.get(usage, "output_tokens", 0),
            processing_time_ms: elapsed
          }}

        {:ok, %Req.Response{status: 429}} ->
          Logger.warning("Claude API rate limited")
          {:error, :rate_limited}

        {:ok, %Req.Response{status: status, body: response_body}} ->
          Logger.warning("Claude API error: #{status} - #{inspect(response_body)}")
          {:error, %{status: status, body: response_body}}

        {:error, reason} ->
          Logger.error("Claude API request failed: #{inspect(reason)}")
          {:error, reason}
      end
    end
  end

  defp download_image(url) do
    case Req.request(method: :get, url: url, receive_timeout: 30_000) do
      {:ok, %Req.Response{status: 200, body: body}} -> {:ok, body}
      {:ok, %Req.Response{status: status}} -> {:error, {:http_status, status}}
      {:error, reason} -> {:error, reason}
    end
  end

  defp resolve_model(:haiku), do: @model_haiku
  defp resolve_model(:sonnet), do: @model_sonnet
  defp resolve_model(model) when is_binary(model), do: model

  defp api_key do
    Application.get_env(:ga_personal, :anthropic)[:api_key]
  end
end
