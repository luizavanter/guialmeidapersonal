defmodule GaPersonalWeb.Plugs.RateLimit do
  @moduledoc """
  Rate limiting plug using Hammer.
  Limits requests per IP address on configured endpoints.
  """

  import Plug.Conn

  @default_limit 60
  @default_period 60_000

  def init(opts) do
    %{
      limit: Keyword.get(opts, :limit, @default_limit),
      period: Keyword.get(opts, :period, @default_period),
      key_prefix: Keyword.get(opts, :key_prefix, "api")
    }
  end

  def call(conn, %{limit: limit, period: period, key_prefix: key_prefix}) do
    ip = conn.remote_ip |> :inet.ntoa() |> to_string()
    key = "#{key_prefix}:#{ip}"

    case Hammer.check_rate(key, period, limit) do
      {:allow, _count} ->
        conn

      {:deny, _limit} ->
        retry_after = div(period, 1000)

        conn
        |> put_resp_header("retry-after", to_string(retry_after))
        |> put_status(:too_many_requests)
        |> Phoenix.Controller.json(%{
          errors: %{message: "Too many requests. Please try again later."}
        })
        |> halt()
    end
  end
end
