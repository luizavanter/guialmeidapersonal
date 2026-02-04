defmodule GaPersonalWeb.ExerciseController do
  use GaPersonalWeb, :controller

  alias GaPersonal.Workouts

  action_fallback GaPersonalWeb.FallbackController

  def index(conn, _params) do
    trainer_id = conn.assigns.current_user_id
    exercises = Workouts.list_exercises(trainer_id)
    json(conn, %{data: Enum.map(exercises, &exercise_json/1)})
  end

  def show(conn, %{"id" => id}) do
    trainer_id = conn.assigns.current_user_id

    case Workouts.get_exercise_for_trainer(id, trainer_id) do
      {:ok, exercise} ->
        json(conn, %{data: exercise_json(exercise)})

      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :unauthorized} ->
        {:error, :forbidden}
    end
  end

  def create(conn, %{"exercise" => exercise_params}) do
    trainer_id = conn.assigns.current_user_id
    params = Map.put(exercise_params, "trainer_id", trainer_id)

    with {:ok, exercise} <- Workouts.create_exercise(params) do
      conn
      |> put_status(:created)
      |> json(%{data: exercise_json(exercise)})
    end
  end

  def update(conn, %{"id" => id, "exercise" => exercise_params}) do
    trainer_id = conn.assigns.current_user_id

    case Workouts.get_exercise_for_trainer(id, trainer_id) do
      {:ok, exercise} ->
        # Only allow editing own exercises (not public ones from other trainers)
        if exercise.trainer_id == trainer_id do
          with {:ok, updated} <- Workouts.update_exercise(exercise, exercise_params) do
            json(conn, %{data: exercise_json(updated)})
          end
        else
          {:error, :forbidden}
        end

      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :unauthorized} ->
        {:error, :forbidden}
    end
  end

  def delete(conn, %{"id" => id}) do
    trainer_id = conn.assigns.current_user_id

    case Workouts.get_exercise_for_trainer(id, trainer_id) do
      {:ok, exercise} ->
        # Only allow deleting own exercises
        if exercise.trainer_id == trainer_id do
          with {:ok, _} <- Workouts.delete_exercise(exercise) do
            send_resp(conn, :no_content, "")
          end
        else
          {:error, :forbidden}
        end

      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :unauthorized} ->
        {:error, :forbidden}
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
