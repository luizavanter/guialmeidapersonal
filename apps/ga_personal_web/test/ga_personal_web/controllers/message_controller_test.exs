defmodule GaPersonalWeb.MessageControllerTest do
  use GaPersonalWeb.ConnCase, async: true

  describe "authenticated user" do
    setup %{conn: conn} do
      setup_trainer_conn(%{conn: conn})
    end

    test "GET /api/v1/messages lists messages", %{conn: conn, trainer: trainer} do
      student = insert(:student_user)
      insert(:message, sender: trainer, recipient: student)

      conn = get(conn, "/api/v1/messages")

      assert %{"data" => messages} = json_response(conn, 200)
      assert length(messages) == 1
    end

    test "POST /api/v1/messages creates a message", %{conn: conn} do
      recipient = insert(:student_user)

      params = %{
        message: %{
          recipient_id: recipient.id,
          subject: "Training Update",
          body: "Your new workout plan is ready"
        }
      }

      conn = post(conn, "/api/v1/messages", params)

      assert %{"data" => message} = json_response(conn, 201)
      assert message["body"] == "Your new workout plan is ready"
    end

    test "POST /api/v1/messages returns error without body", %{conn: conn} do
      recipient = insert(:student_user)
      params = %{message: %{recipient_id: recipient.id}}

      conn = post(conn, "/api/v1/messages", params)
      assert json_response(conn, 422)
    end

    test "PUT /api/v1/messages/:id/read marks as read", %{conn: conn, trainer: trainer} do
      student = insert(:student_user)
      message = insert(:message, sender: student, recipient: trainer)

      conn = put(conn, "/api/v1/messages/#{message.id}/read")

      assert %{"data" => updated} = json_response(conn, 200)
      assert updated["is_read"] == true
    end
  end

  describe "unauthenticated" do
    test "GET /api/v1/messages returns 401", %{conn: conn} do
      conn = get(conn, "/api/v1/messages")
      assert json_response(conn, 401)
    end
  end
end
