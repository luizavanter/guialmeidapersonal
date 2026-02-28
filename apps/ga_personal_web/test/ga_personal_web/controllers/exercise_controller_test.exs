defmodule GaPersonalWeb.ExerciseControllerTest do
  use GaPersonalWeb.ConnCase, async: true

  describe "authenticated trainer" do
    setup %{conn: conn} do
      setup_trainer_conn(%{conn: conn})
    end

    test "GET /api/v1/exercises lists exercises", %{conn: conn, trainer: trainer} do
      insert(:exercise, trainer: trainer, name: "Squat")

      conn = get(conn, "/api/v1/exercises")

      assert %{"data" => exercises} = json_response(conn, 200)
      assert length(exercises) >= 1
      assert Enum.any?(exercises, &(&1["name"] == "Squat"))
    end

    test "POST /api/v1/exercises creates an exercise", %{conn: conn} do
      params = %{
        exercise: %{
          name: "Deadlift",
          category: "strength",
          difficulty_level: "advanced",
          muscle_groups: ["back", "glutes", "hamstrings"],
          equipment_needed: ["barbell"],
          instructions: "Keep back straight"
        }
      }

      conn = post(conn, "/api/v1/exercises", params)

      assert %{"data" => exercise} = json_response(conn, 201)
      assert exercise["name"] == "Deadlift"
      assert exercise["category"] == "strength"
    end

    test "POST /api/v1/exercises returns error with invalid data", %{conn: conn} do
      conn = post(conn, "/api/v1/exercises", %{exercise: %{name: ""}})
      assert json_response(conn, 422)
    end

    test "PUT /api/v1/exercises/:id updates an exercise", %{conn: conn, trainer: trainer} do
      exercise = insert(:exercise, trainer: trainer)

      conn = put(conn, "/api/v1/exercises/#{exercise.id}", %{exercise: %{name: "Updated Exercise"}})

      assert %{"data" => updated} = json_response(conn, 200)
      assert updated["name"] == "Updated Exercise"
    end

    test "DELETE /api/v1/exercises/:id deletes an exercise", %{conn: conn, trainer: trainer} do
      exercise = insert(:exercise, trainer: trainer)

      conn = delete(conn, "/api/v1/exercises/#{exercise.id}")
      assert response(conn, 204)
    end

    test "cannot modify another trainer's exercise", %{conn: conn} do
      other_trainer = insert(:trainer)
      exercise = insert(:exercise, trainer: other_trainer, is_public: false)

      conn = put(conn, "/api/v1/exercises/#{exercise.id}", %{exercise: %{name: "Hacked"}})
      assert json_response(conn, 403) || json_response(conn, 404)
    end
  end

  describe "unauthenticated" do
    test "GET /api/v1/exercises returns 401", %{conn: conn} do
      conn = get(conn, "/api/v1/exercises")
      assert json_response(conn, 401)
    end
  end
end
