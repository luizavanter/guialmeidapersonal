defmodule GaPersonalWeb.WorkoutPlanController do
  use GaPersonalWeb, :controller

  alias GaPersonal.Workouts
  alias GaPersonal.Guardian

  action_fallback GaPersonalWeb.FallbackController

  def index(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    workout_plans = Workouts.list_workout_plans(user.id, params)
    json(conn, %{data: Enum.map(workout_plans, &workout_plan_json/1)})
  end

  def show(conn, %{"id" => id}) do
    workout_plan = Workouts.get_workout_plan!(id)
    json(conn, %{data: workout_plan_json(workout_plan)})
  end

  def create(conn, %{"workout_plan" => workout_plan_params}) do
    user = Guardian.Plug.current_resource(conn)
    params = Map.put(workout_plan_params, "trainer_id", user.id)

    with {:ok, workout_plan} <- Workouts.create_workout_plan(params) do
      conn
      |> put_status(:created)
      |> json(%{data: workout_plan_json(workout_plan)})
    end
  end

  def update(conn, %{"id" => id, "workout_plan" => workout_plan_params}) do
    workout_plan = Workouts.get_workout_plan!(id)

    with {:ok, updated} <- Workouts.update_workout_plan(workout_plan, workout_plan_params) do
      json(conn, %{data: workout_plan_json(updated)})
    end
  end

  def delete(conn, %{"id" => id}) do
    workout_plan = Workouts.get_workout_plan!(id)

    with {:ok, _} <- Workouts.delete_workout_plan(workout_plan) do
      send_resp(conn, :no_content, "")
    end
  end

  defp workout_plan_json(workout_plan) do
    %{
      id: workout_plan.id,
      trainer_id: workout_plan.trainer_id,
      student_id: workout_plan.student_id,
      name: workout_plan.name,
      description: workout_plan.description,
      status: workout_plan.status,
      is_template: workout_plan.is_template,
      start_date: workout_plan.start_date,
      end_date: workout_plan.end_date,
      inserted_at: workout_plan.inserted_at,
      updated_at: workout_plan.updated_at,
      workout_exercises: workout_exercises_json(workout_plan)
    }
  end

  defp workout_exercises_json(%{workout_exercises: exercises}) when is_list(exercises) do
    Enum.map(exercises, fn we ->
      %{
        id: we.id,
        exercise_id: we.exercise_id,
        sets: we.sets,
        reps: we.reps,
        rest_seconds: we.rest_seconds,
        order: we.order,
        notes: we.notes,
        exercise: if(we.exercise, do: exercise_json(we.exercise), else: nil)
      }
    end)
  end

  defp workout_exercises_json(_), do: []

  defp exercise_json(exercise) do
    %{
      id: exercise.id,
      name: exercise.name,
      category: exercise.category
    }
  end
end
