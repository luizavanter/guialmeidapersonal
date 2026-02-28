defmodule GaPersonalWeb.PrivacyController do
  use GaPersonalWeb, :controller

  alias GaPersonal.Privacy

  action_fallback GaPersonalWeb.FallbackController

  def grant_consent(conn, %{"consent" => %{"consent_type" => consent_type}}) do
    user = conn.assigns.current_user

    conn_info = %{
      ip_address: conn.remote_ip |> :inet.ntoa() |> to_string(),
      user_agent: Plug.Conn.get_req_header(conn, "user-agent") |> List.first()
    }

    case Privacy.record_consent(user.id, consent_type, conn_info) do
      {:ok, consent} ->
        conn
        |> put_status(:created)
        |> json(%{data: consent_json(consent)})

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, changeset}
    end
  end

  def revoke_consent(conn, %{"type" => consent_type}) do
    user = conn.assigns.current_user

    case Privacy.revoke_consent(user.id, consent_type) do
      {:ok, :revoked} ->
        json(conn, %{message: "Consent revoked"})
    end
  end

  def export_data(conn, _params) do
    user = conn.assigns.current_user

    case Privacy.export_user_data(user.id) do
      {:ok, data} ->
        json(conn, %{data: data})
    end
  end

  def delete_data(conn, _params) do
    user = conn.assigns.current_user

    case Privacy.delete_user_data(user.id) do
      {:ok, :deleted} ->
        json(conn, %{message: "User data deletion initiated"})
    end
  end

  defp consent_json(consent) do
    %{
      id: consent.id,
      consent_type: consent.consent_type,
      granted: consent.granted,
      granted_at: consent.granted_at,
      revoked_at: consent.revoked_at,
      inserted_at: consent.inserted_at
    }
  end
end
