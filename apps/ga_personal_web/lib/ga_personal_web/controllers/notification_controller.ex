defmodule GaPersonalWeb.NotificationController do
  use GaPersonalWeb, :controller

  alias GaPersonal.Messaging
  alias GaPersonal.Messaging.Notification
  alias GaPersonal.Repo
  alias GaPersonal.Guardian

  action_fallback GaPersonalWeb.FallbackController

  def index(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    notifications = Messaging.list_notifications(user.id)
    json(conn, %{data: Enum.map(notifications, &notification_json/1)})
  end

  def show(conn, %{"id" => id}) do
    notification = Repo.get!(Notification, id)
    json(conn, %{data: notification_json(notification)})
  end

  def update(conn, %{"id" => id, "notification" => notification_params}) do
    notification = Repo.get!(Notification, id)

    with {:ok, updated} <- Messaging.mark_notification_as_read(notification) do
      updated = if notification_params != %{}, do: updated, else: updated
      json(conn, %{data: notification_json(updated)})
    end
  end

  def delete(conn, %{"id" => id}) do
    notification = Repo.get!(Notification, id)

    with {:ok, _} <- Messaging.delete_notification(notification) do
      send_resp(conn, :no_content, "")
    end
  end

  def mark_read(conn, %{"id" => id}) do
    notification = Repo.get!(Notification, id)

    with {:ok, updated} <- Messaging.mark_notification_as_read(notification) do
      json(conn, %{data: notification_json(updated)})
    end
  end

  defp notification_json(notification) do
    %{
      id: notification.id,
      user_id: notification.user_id,
      notification_type: notification.notification_type,
      title: notification.title,
      message: notification.message,
      data: notification.data,
      is_read: notification.is_read,
      read_at: notification.read_at,
      inserted_at: notification.inserted_at
    }
  end
end
