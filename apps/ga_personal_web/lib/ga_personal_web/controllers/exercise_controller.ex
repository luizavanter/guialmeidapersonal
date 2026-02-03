defmodule GaPersonalWeb.ExerciseController do
  use GaPersonalWeb, :controller

  alias GaPersonal.Workouts
  alias GaPersonal.Guardian

  action_fallback GaPersonalWeb.FallbackController

  def index(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    exercises = Workouts.list_exercises(user.id)
    json(conn, %{data: Enum.map(exercises, &exercise_json/1)})
  end

  def show(conn, %{"id" => id}) do
    exercise = Workouts.get_exercise!(id)
    json(conn, %{data: exercise_json(exercise)})
  end

  def create(conn, %{"exercise" => exercise_params}) do
    user = Guardian.Plug.current_resource(conn)
    params = Map.put(exercise_params, "trainer_id", user.id)

    with {:ok, exercise} <- Workouts.create_exercise(params) do
      conn
      |> put_status(:created)
      |> json(%{data: exercise_json(exercise)})
    end
  end

  def update(conn, %{"id" => id, "exercise" => exercise_params}) do
    exercise = Workouts.get_exercise!(id)

    with {:ok, updated} <- Workouts.update_exercise(exercise, exercise_params) do
      json(conn, %{data: exercise_json(updated)})
    end
  end

  def delete(conn, %{"id" => id}) do
    exercise = Workouts.get_exercise!(id)

    with {:ok, _} <- Workouts.delete_exercise(exercise) do
      send_resp(conn, :no_content, "")
    end
  end

  defp exercise_json(exercise) do
    %{
      id: exercise.id,
      name: exercise.name,
      description: exercise.description,
      category: exercise.category,
      muscle_groups: exercise.muscle_groups,
      equipment_needed: exercise.equipment_needed,
      difficulty_level: exercise.difficulty_level,
      video_url: exercise.video_url,
      thumbnail_url: exercise.thumbnail_url,
      instructions: exercise.instructions,
      is_public: exercise.is_public
    }
  end
end
