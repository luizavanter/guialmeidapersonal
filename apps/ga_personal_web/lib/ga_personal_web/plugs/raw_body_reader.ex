defmodule GaPersonalWeb.Plugs.RawBodyReader do
  @moduledoc """
  A custom body reader that caches the raw body in conn.assigns for webhook
  signature verification.

  ## Usage

  In endpoint.ex, use this module as the body_reader for Plug.Parsers:

      plug Plug.Parsers,
        parsers: [:urlencoded, :multipart, :json],
        pass: ["*/*"],
        body_reader: {GaPersonalWeb.Plugs.RawBodyReader, :read_body, []},
        json_decoder: Phoenix.json_library()

  The raw body will be available in `conn.assigns.raw_body` for routes
  that need it (like webhook signature verification).
  """

  @doc """
  Reads the body from the connection and caches it in assigns.

  This is used as a custom body reader for Plug.Parsers.
  """
  def read_body(conn, opts) do
    {:ok, body, conn} = Plug.Conn.read_body(conn, opts)
    conn = Plug.Conn.assign(conn, :raw_body, body)
    {:ok, body, conn}
  end
end
