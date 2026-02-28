defmodule GaPersonal.Messaging do
  @moduledoc """
  The Messaging context - handles messages and notifications.
  """

  import Ecto.Query, warn: false
  alias GaPersonal.Repo
  alias GaPersonal.Messaging.{Message, Notification}

  ## Message functions

  def list_messages(user_id) do
    from(m in Message,
      where: m.sender_id == ^user_id or m.recipient_id == ^user_id,
      preload: [:sender, :recipient],
      order_by: [desc: m.inserted_at]
    )
    |> Repo.all()
  end

  def list_inbox(user_id) do
    from(m in Message,
      where: m.recipient_id == ^user_id,
      preload: [:sender],
      order_by: [desc: m.inserted_at]
    )
    |> Repo.all()
  end

  def list_sent(user_id) do
    from(m in Message,
      where: m.sender_id == ^user_id,
      preload: [:recipient],
      order_by: [desc: m.inserted_at]
    )
    |> Repo.all()
  end

  def get_message!(id) do
    Message
    |> Repo.get!(id)
    |> Repo.preload([:sender, :recipient])
  end

  def create_message(attrs \\ %{}) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, message} -> {:ok, Repo.preload(message, [:sender, :recipient])}
      error -> error
    end
  end

  def mark_as_read(%Message{} = message) do
    message
    |> Message.changeset(%{is_read: true, read_at: DateTime.utc_now()})
    |> Repo.update()
  end

  def delete_message(%Message{} = message) do
    Repo.delete(message)
  end

  ## Notification functions

  def list_notifications(user_id) do
    from(n in Notification,
      where: n.user_id == ^user_id,
      order_by: [desc: n.inserted_at]
    )
    |> Repo.all()
  end

  def list_unread_notifications(user_id) do
    from(n in Notification,
      where: n.user_id == ^user_id and n.is_read == false,
      order_by: [desc: n.inserted_at]
    )
    |> Repo.all()
  end

  def create_notification(attrs \\ %{}) do
    %Notification{}
    |> Notification.changeset(attrs)
    |> Repo.insert()
  end

  def mark_notification_as_read(%Notification{} = notification) do
    notification
    |> Notification.changeset(%{is_read: true, read_at: DateTime.utc_now()})
    |> Repo.update()
  end

  def mark_all_notifications_as_read(user_id) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    from(n in Notification,
      where: n.user_id == ^user_id and n.is_read == false
    )
    |> Repo.update_all(set: [is_read: true, read_at: now])
  end

  def delete_notification(%Notification{} = notification) do
    Repo.delete(notification)
  end
end
