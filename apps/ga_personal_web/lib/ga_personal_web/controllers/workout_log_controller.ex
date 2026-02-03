defmodule GaPersonalWeb.WorkoutLogController do
  use GaPersonalWeb, :controller

  alias GaPersonal.Workouts
  alias GaPersonal.Repo
  alias GaPersonal.Guardian

  action_fallback GaPersonalWeb.FallbackController

  def index(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    student_id = Map.get(params, "student_id", user.id)
    workout_logs = Workouts.list_workout_logs(student_id, params)
    json(conn, %{data: Enum.map(workout_logs, &workout_log_json/1)})
  end

  def show(conn, %{"id" => id}) do
    workout_log = Workouts.WorkoutLog
    |> Repo.get!(id)
    |> Repo.preload([:exercise, :workout_plan])

    json(conn, %{data: workout_log_json(workout_log)})
  end

  def create(conn, %{"workout_log" => workout_log_params}) do
    with {:ok, workout_log} <- Workouts.create_workout_log(workout_log_params) do
      conn
      |> put_status(:created)
      |> json(%{data: workout_log_json(workout_log)})
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
