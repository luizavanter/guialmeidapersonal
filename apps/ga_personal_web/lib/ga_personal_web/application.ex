defmodule GaPersonalWeb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      GaPersonalWeb.Telemetry,
      # Start a worker by calling: GaPersonalWeb.Worker.start_link(arg)
      # {GaPersonalWeb.Worker, arg},
      # Start to serve requests, typically the last entry
      GaPersonalWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: GaPersonalWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    GaPersonalWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
