defmodule GaPersonalWeb.WorkoutLogController do
  use GaPersonalWeb, :controller

  alias GaPersonal.Workouts
  alias GaPersonal.Accounts

  action_fallback GaPersonalWeb.FallbackController

  # Student actions - students can only access their own workout logs
  def index(conn, params) do
    user = conn.assigns.current_user

    case Accounts.get_student_by_user_id(user.id) do
      nil ->
        {:error, :not_found}

      student ->
        workout_logs = Workouts.list_workout_logs(student.id, params)
        json(conn, %{data: Enum.map(workout_logs, &workout_log_json/1)})
    end
  end

  def show(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    case Accounts.get_student_by_user_id(user.id) do
      nil ->
        {:error, :not_found}

      student ->
        case Workouts.get_workout_log_for_student(id, student.id) do
          {:ok, workout_log} ->
            json(conn, %{data: workout_log_json(workout_log)})

          {:error, :not_found} ->
            {:error, :not_found}

          {:error, :unauthorized} ->
            {:error, :forbidden}
        end
    end
  end

  def create(conn, %{"workout_log" => workout_log_params}) do
    user = conn.assigns.current_user

    case Accounts.get_student_by_user_id(user.id) do
      nil ->
        {:error, :not_found}

      student ->
        # Ensure the student can only create logs for themselves
        params = Map.put(workout_log_params, "student_id", student.id)

        with {:ok, workout_log} <- Workouts.create_workout_log(params) do
          conn
          |> put_status(:created)
          |> json(%{data: workout_log_json(workout_log)})
        end
    end
  end

  defp workout_log_json(workout_log) do
    %{
      id: workout_log.id,
      student_id: workout_log.student_id,
      exercise_id: workout_log.exercise_id,
      workout_plan_id: workout_log.workout_plan_id,
      sets_completed: workout_log.sets_completed,
      reps_completed: workout_log.reps_completed,
      weight_used: workout_log.weight_used,
      duration_seconds: workout_log.duration_seconds,
      notes: workout_log.notes,
      completed_at: workout_log.completed_at,
      exercise: if(Map.get(workout_log, :exercise), do: exercise_json(workout_log.exercise), else: nil),
      workout_plan: if(Map.get(workout_log, :workout_plan), do: workout_plan_json(workout_log.workout_plan), else: nil)
    }
  end

  defp exercise_json(exercise) do
    %{
      id: exercise.id,
      name: exercise.name,
      category: exercise.category
    }
  end

  defp workout_plan_json(workout_plan) do
    %{
      id: workout_plan.id,
      name: workout_plan.name
    }
  end
end
