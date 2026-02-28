defmodule GaPersonal.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        GaPersonal.Repo,
        {DNSCluster, query: Application.get_env(:ga_personal, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: GaPersonal.PubSub},
        # Finch HTTP client for Swoosh/Resend email delivery
        {Finch, name: Swoosh.Finch},
        {Oban, Application.fetch_env!(:ga_personal, Oban)}
      ] ++ goth_child_spec()

    store_goth_credentials()

    Supervisor.start_link(children, strategy: :one_for_one, name: GaPersonal.Supervisor)
  end

  defp goth_child_spec do
    cond do
      System.get_env("GOOGLE_APPLICATION_CREDENTIALS") ->
        [{Goth, name: GaPersonal.Goth, source: {:default, []}}]

      System.get_env("GCS_CREDENTIALS_JSON") ->
        credentials = Jason.decode!(System.get_env("GCS_CREDENTIALS_JSON"))
        [{Goth, name: GaPersonal.Goth, source: {:service_account, credentials}}]

      true ->
        # On Cloud Run, default credentials are available via metadata server
        # In dev without credentials, skip Goth startup
        if System.get_env("K_SERVICE") do
          [{Goth, name: GaPersonal.Goth, source: {:default, []}}]
        else
          []
        end
    end
  end

  defp store_goth_credentials do
    if json = System.get_env("GCS_CREDENTIALS_JSON") do
      Application.put_env(:ga_personal, :goth_credentials, Jason.decode!(json))
    end
  end
end
