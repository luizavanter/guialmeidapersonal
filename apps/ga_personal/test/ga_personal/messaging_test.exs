defmodule GaPersonal.MessagingTest do
  use GaPersonal.DataCase, async: true

  alias GaPersonal.Messaging
  alias GaPersonal.Messaging.{Message, Notification}

  describe "messages" do
    setup do
      trainer = insert(:trainer)
      student = insert(:student_user)
      %{trainer: trainer, student: student}
    end

    test "list_messages/1 returns messages for user", %{trainer: trainer, student: student} do
      insert(:message, sender: trainer, recipient: student)
      assert length(Messaging.list_messages(trainer.id)) == 1
      assert length(Messaging.list_messages(student.id)) == 1
    end

    test "list_inbox/1 returns received messages", %{trainer: trainer, student: student} do
      insert(:message, sender: trainer, recipient: student)
      assert length(Messaging.list_inbox(student.id)) == 1
      assert Messaging.list_inbox(trainer.id) == []
    end

    test "list_sent/1 returns sent messages", %{trainer: trainer, student: student} do
      insert(:message, sender: trainer, recipient: student)
      assert length(Messaging.list_sent(trainer.id)) == 1
      assert Messaging.list_sent(student.id) == []
    end

    test "create_message/1 with valid data", %{trainer: trainer, student: student} do
      attrs = %{
        sender_id: trainer.id,
        recipient_id: student.id,
        body: "Hello, how are you?"
      }

      assert {:ok, %Message{body: "Hello, how are you?"}} = Messaging.create_message(attrs)
    end

    test "create_message/1 without body returns error", %{trainer: trainer, student: student} do
      attrs = %{sender_id: trainer.id, recipient_id: student.id}
      assert {:error, %Ecto.Changeset{}} = Messaging.create_message(attrs)
    end

    test "mark_as_read/1 marks message as read", %{trainer: trainer, student: student} do
      message = insert(:message, sender: trainer, recipient: student)
      assert {:ok, %Message{is_read: true} = read} = Messaging.mark_as_read(message)
      assert read.read_at != nil
    end

    test "delete_message/1 deletes the message", %{trainer: trainer, student: student} do
      message = insert(:message, sender: trainer, recipient: student)
      assert {:ok, %Message{}} = Messaging.delete_message(message)
    end
  end

  describe "notifications" do
    setup do
      user = insert(:student_user)
      %{user: user}
    end

    test "list_notifications/1 returns all notifications", %{user: user} do
      insert(:notification, user: user)
      assert length(Messaging.list_notifications(user.id)) == 1
    end

    test "list_unread_notifications/1 returns only unread", %{user: user} do
      insert(:notification, user: user, is_read: false)
      insert(:notification, user: user, is_read: true)
      assert length(Messaging.list_unread_notifications(user.id)) == 1
    end

    test "create_notification/1 with valid data", %{user: user} do
      attrs = %{
        user_id: user.id,
        type: "payment_due",
        title: "Payment Due",
        body: "Your payment is due tomorrow",
        delivery_method: "in_app"
      }

      assert {:ok, %Notification{title: "Payment Due"}} = Messaging.create_notification(attrs)
    end

    test "create_notification/1 with invalid delivery_method returns error", %{user: user} do
      attrs = %{user_id: user.id, type: "test", title: "Test", body: "Test", delivery_method: "pigeon"}
      assert {:error, %Ecto.Changeset{}} = Messaging.create_notification(attrs)
    end

    test "mark_notification_as_read/1 marks as read", %{user: user} do
      notification = insert(:notification, user: user)
      assert {:ok, %Notification{is_read: true}} = Messaging.mark_notification_as_read(notification)
    end

    test "delete_notification/1 deletes the notification", %{user: user} do
      notification = insert(:notification, user: user)
      assert {:ok, %Notification{}} = Messaging.delete_notification(notification)
    end
  end
end
