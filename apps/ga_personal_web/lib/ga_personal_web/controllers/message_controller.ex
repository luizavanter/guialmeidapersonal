defmodule GaPersonalWeb.MessageController do
  use GaPersonalWeb, :controller

  alias GaPersonal.Messaging
  alias GaPersonal.Guardian

  action_fallback GaPersonalWeb.FallbackController

  def index(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    messages = Messaging.list_messages(user.id)
    json(conn, %{data: Enum.map(messages, &message_json/1)})
  end

  def inbox(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    messages = Messaging.list_inbox(user.id)
    json(conn, %{data: Enum.map(messages, &message_json/1)})
  end

  def sent(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    messages = Messaging.list_sent(user.id)
    json(conn, %{data: Enum.map(messages, &message_json/1)})
  end

  def show(conn, %{"id" => id}) do
    message = Messaging.get_message!(id)
    json(conn, %{data: message_json(message)})
  end

  def create(conn, %{"message" => message_params}) do
    user = Guardian.Plug.current_resource(conn)
    params = Map.put(message_params, "sender_id", user.id)

    with {:ok, message} <- Messaging.create_message(params) do
      conn
      |> put_status(:created)
      |> json(%{data: message_json(message)})
    end
  end

  def delete(conn, %{"id" => id}) do
    message = Messaging.get_message!(id)

    with {:ok, _} <- Messaging.delete_message(message) do
      send_resp(conn, :no_content, "")
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
    user = Map.get(message, field)
    if user do
      %{
        id: user.id,
        full_name: user.full_name,
        email: user.email
      }
    else
      nil
    end
  end
end
