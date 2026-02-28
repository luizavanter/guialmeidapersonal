defmodule GaPersonal.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      GaPersonal.Repo,
      {DNSCluster, query: Application.get_env(:ga_personal, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: GaPersonal.PubSub},
      # Finch HTTP client for Swoosh/Resend email delivery
      {Finch, name: Swoosh.Finch},
      {Oban, Application.fetch_env!(:ga_personal, Oban)}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: GaPersonal.Supervisor)
  end
end
