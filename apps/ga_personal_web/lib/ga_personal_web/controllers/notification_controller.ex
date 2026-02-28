defmodule GaPersonalWeb.NotificationController do
  use GaPersonalWeb, :controller

  alias GaPersonal.Messaging
  alias GaPersonal.Messaging.Notification
  alias GaPersonal.Repo

  action_fallback GaPersonalWeb.FallbackController

  def index(conn, _params) do
    user_id = conn.assigns.current_user_id
    notifications = Messaging.list_notifications(user_id)
    json(conn, %{data: Enum.map(notifications, &notification_json/1)})
  end

  def show(conn, %{"id" => id}) do
    user_id = conn.assigns.current_user_id
    notification = Repo.get!(Notification, id)

    # Users can only view their own notifications
    if notification.user_id == user_id do
      json(conn, %{data: notification_json(notification)})
    else
      {:error, :forbidden}
    end
  end

  def update(conn, %{"id" => id, "notification" => notification_params}) do
    user_id = conn.assigns.current_user_id
    notification = Repo.get!(Notification, id)

    # Users can only update their own notifications
    if notification.user_id == user_id do
      with {:ok, updated} <- Messaging.mark_notification_as_read(notification) do
        updated = if notification_params != %{}, do: updated, else: updated
        json(conn, %{data: notification_json(updated)})
      end
    else
      {:error, :forbidden}
    end
  end

  def delete(conn, %{"id" => id}) do
    user_id = conn.assigns.current_user_id
    notification = Repo.get!(Notification, id)

    # Users can only delete their own notifications
    if notification.user_id == user_id do
      with {:ok, _} <- Messaging.delete_notification(notification) do
        send_resp(conn, :no_content, "")
      end
    else
      {:error, :forbidden}
    end
  end

  def mark_read(conn, %{"id" => id}) do
    user_id = conn.assigns.current_user_id
    notification = Repo.get!(Notification, id)

    # Users can only mark their own notifications as read
    if notification.user_id == user_id do
      with {:ok, updated} <- Messaging.mark_notification_as_read(notification) do
        json(conn, %{data: notification_json(updated)})
      end
    else
      {:error, :forbidden}
    end
  end

  def mark_all_read(conn, _params) do
    user_id = conn.assigns.current_user_id
    {count, _} = Messaging.mark_all_notifications_as_read(user_id)
    json(conn, %{data: %{marked_read: count}})
  end

  defp notification_json(notification) do
    %{
      id: notification.id,
      user_id: notification.user_id,
      type: notification.type,
      title: notification.title,
      body: notification.body,
      data: notification.data,
      is_read: notification.is_read,
      read_at: notification.read_at,
      inserted_at: notification.inserted_at
    }
  end
end
