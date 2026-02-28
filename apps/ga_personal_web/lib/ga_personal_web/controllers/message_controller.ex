defmodule GaPersonalWeb.MessageController do
  use GaPersonalWeb, :controller

  alias GaPersonal.Messaging

  action_fallback GaPersonalWeb.FallbackController

  def index(conn, _params) do
    user_id = conn.assigns.current_user_id
    messages = Messaging.list_messages(user_id)
    json(conn, %{data: Enum.map(messages, &message_json/1)})
  end

  def inbox(conn, _params) do
    user_id = conn.assigns.current_user_id
    messages = Messaging.list_inbox(user_id)
    json(conn, %{data: Enum.map(messages, &message_json/1)})
  end

  def sent(conn, _params) do
    user_id = conn.assigns.current_user_id
    messages = Messaging.list_sent(user_id)
    json(conn, %{data: Enum.map(messages, &message_json/1)})
  end

  def show(conn, %{"id" => id}) do
    user_id = conn.assigns.current_user_id
    message = Messaging.get_message!(id)

    # Users can only view messages they sent or received
    if message.sender_id == user_id or message.recipient_id == user_id do
      # Auto-mark as read if recipient is viewing
      if message.recipient_id == user_id and not message.is_read do
        Messaging.mark_as_read(message)
      end

      json(conn, %{data: message_json(message)})
    else
      {:error, :forbidden}
    end
  end

  def create(conn, %{"message" => message_params}) do
    user_id = conn.assigns.current_user_id
    params = Map.put(message_params, "sender_id", user_id)

    with {:ok, message} <- Messaging.create_message(params) do
      conn
      |> put_status(:created)
      |> json(%{data: message_json(message)})
    end
  end

  def mark_read(conn, %{"id" => id}) do
    user_id = conn.assigns.current_user_id
    message = Messaging.get_message!(id)

    if message.recipient_id == user_id do
      {:ok, updated} = Messaging.mark_as_read(message)
      json(conn, %{data: message_json(updated)})
    else
      {:error, :forbidden}
    end
  end

  def delete(conn, %{"id" => id}) do
    user_id = conn.assigns.current_user_id
    message = Messaging.get_message!(id)

    # Users can only delete messages they sent
    if message.sender_id == user_id do
      with {:ok, _} <- Messaging.delete_message(message) do
        send_resp(conn, :no_content, "")
      end
    else
      {:error, :forbidden}
    end
  end

  defp message_json(message) do
    %{
      id: message.id,
      sender_id: message.sender_id,
      recipient_id: message.recipient_id,
      subject: message.subject,
      body: message.body,
      is_read: message.is_read,
      read_at: message.read_at,
      inserted_at: message.inserted_at,
      sender: user_json(message, :sender),
      recipient: user_json(message, :recipient)
    }
  end

  defp user_json(message, field) do
    case Map.get(message, field) do
      %Ecto.Association.NotLoaded{} -> nil
      nil -> nil
      user ->
        %{
          id: user.id,
          full_name: user.full_name,
          email: user.email
        }
    end
  end
end
