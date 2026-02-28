defmodule GaPersonalWeb.HealthController do
  use GaPersonalWeb, :controller

  alias GaPersonal.Repo

  def check(conn, _params) do
    checks = %{
      database: check_database(),
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      version: Application.spec(:ga_personal, :vsn) |> to_string()
    }

    status = if checks.database == :ok, do: :ok, else: :service_unavailable

    conn
    |> put_status(status)
    |> json(%{
      status: if(status == :ok, do: "healthy", else: "unhealthy"),
      checks: %{
        database: to_string(checks.database)
      },
      timestamp: checks.timestamp,
      version: checks.version
    })
  end

  defp check_database do
    case Repo.query("SELECT 1") do
      {:ok, _} -> :ok
      {:error, _} -> :error
    end
  rescue
    _ -> :error
  end
end
