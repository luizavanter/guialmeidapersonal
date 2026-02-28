defmodule GaPersonalWeb.StudentControllerTest do
  use GaPersonalWeb.ConnCase, async: true

  describe "authenticated trainer" do
    setup %{conn: conn} do
      setup_trainer_conn(%{conn: conn})
    end

    test "GET /api/v1/students lists trainer's students", %{conn: conn, trainer: trainer} do
      student_user = insert(:student_user)
      insert(:student_profile, user: student_user, trainer: trainer)

      conn = get(conn, "/api/v1/students")

      assert %{"data" => [student]} = json_response(conn, 200)
      assert student["trainer_id"] == trainer.id
    end

    test "GET /api/v1/students returns empty for no students", %{conn: conn} do
      conn = get(conn, "/api/v1/students")
      assert %{"data" => []} = json_response(conn, 200)
    end

    test "GET /api/v1/students/:id shows a student", %{conn: conn, trainer: trainer} do
      student_user = insert(:student_user)
      profile = insert(:student_profile, user: student_user, trainer: trainer)

      conn = get(conn, "/api/v1/students/#{profile.id}")

      assert %{"data" => student} = json_response(conn, 200)
      assert student["id"] == profile.id
      assert student["user"]["email"] == student_user.email
    end

    test "GET /api/v1/students/:id returns 404 for non-existent", %{conn: conn} do
      conn = get(conn, "/api/v1/students/#{Ecto.UUID.generate()}")
      assert json_response(conn, 404)
    end

    test "GET /api/v1/students/:id returns 403 for other trainer's student", %{conn: conn} do
      other_trainer = insert(:trainer)
      student_user = insert(:student_user)
      profile = insert(:student_profile, user: student_user, trainer: other_trainer)

      conn = get(conn, "/api/v1/students/#{profile.id}")
      assert json_response(conn, 403)
    end

    test "POST /api/v1/students creates a student", %{conn: conn} do
      params = %{
        student: %{
          email: "newstudent@example.com",
          password: "Student123!",
          full_name: "New Student",
          phone: "+5548999990000"
        }
      }

      conn = post(conn, "/api/v1/students", params)

      assert %{"data" => student} = json_response(conn, 201)
      assert student["user"]["email"] == "newstudent@example.com"
    end

    test "POST /api/v1/students returns error with invalid data", %{conn: conn} do
      conn = post(conn, "/api/v1/students", %{student: %{}})
      assert json_response(conn, 422)
    end

    test "PUT /api/v1/students/:id updates a student", %{conn: conn, trainer: trainer} do
      student_user = insert(:student_user)
      profile = insert(:student_profile, user: student_user, trainer: trainer)

      conn = put(conn, "/api/v1/students/#{profile.id}", %{student: %{notes: "Updated notes"}})

      assert %{"data" => student} = json_response(conn, 200)
      assert student["notes"] == "Updated notes"
    end

    test "DELETE /api/v1/students/:id deactivates a student", %{conn: conn, trainer: trainer} do
      student_user = insert(:student_user)
      profile = insert(:student_profile, user: student_user, trainer: trainer)

      conn = delete(conn, "/api/v1/students/#{profile.id}")
      assert response(conn, 204)
    end
  end

  describe "unauthenticated" do
    test "GET /api/v1/students returns 401", %{conn: conn} do
      conn = get(conn, "/api/v1/students")
      assert json_response(conn, 401)
    end

    test "POST /api/v1/students returns 401", %{conn: conn} do
      conn = post(conn, "/api/v1/students", %{student: %{}})
      assert json_response(conn, 401)
    end
  end
end
