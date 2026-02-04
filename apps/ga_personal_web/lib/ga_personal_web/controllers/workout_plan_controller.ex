defmodule GaPersonalWeb.WorkoutPlanController do
  use GaPersonalWeb, :controller

  alias GaPersonal.Workouts
  alias GaPersonal.Accounts

  action_fallback GaPersonalWeb.FallbackController

  # Trainer actions
  def index(conn, params) do
    trainer_id = conn.assigns.current_user_id
    workout_plans = Workouts.list_workout_plans(trainer_id, params)
    json(conn, %{data: Enum.map(workout_plans, &workout_plan_json/1)})
  end

  def show(conn, %{"id" => id}) do
    trainer_id = conn.assigns.current_user_id

    case Workouts.get_workout_plan_for_trainer(id, trainer_id) do
      {:ok, workout_plan} ->
        json(conn, %{data: workout_plan_json(workout_plan)})

      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :unauthorized} ->
        {:error, :forbidden}
    end
  end

  def create(conn, %{"workout_plan" => workout_plan_params}) do
    trainer_id = conn.assigns.current_user_id
    params = Map.put(workout_plan_params, "trainer_id", trainer_id)

    with {:ok, workout_plan} <- Workouts.create_workout_plan(params) do
      conn
      |> put_status(:created)
      |> json(%{data: workout_plan_json(workout_plan)})
    end
  end

  def update(conn, %{"id" => id, "workout_plan" => workout_plan_params}) do
    trainer_id = conn.assigns.current_user_id

    case Workouts.get_workout_plan_for_trainer(id, trainer_id) do
      {:ok, workout_plan} ->
        with {:ok, updated} <- Workouts.update_workout_plan(workout_plan, workout_plan_params) do
          json(conn, %{data: workout_plan_json(updated)})
        end

      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :unauthorized} ->
        {:error, :forbidden}
    end
  end

  def delete(conn, %{"id" => id}) do
    trainer_id = conn.assigns.current_user_id

    case Workouts.get_workout_plan_for_trainer(id, trainer_id) do
      {:ok, workout_plan} ->
        with {:ok, _} <- Workouts.delete_workout_plan(workout_plan) do
          send_resp(conn, :no_content, "")
        end

      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :unauthorized} ->
        {:error, :forbidden}
    end
  end

  # Student actions (read-only)
  def index_for_student(conn, params) do
    user = conn.assigns.current_user

    case Accounts.get_student_by_user_id(user.id) do
      nil ->
        {:error, :not_found}

      student ->
        workout_plans = Workouts.list_workout_plans_for_student(student.id, params)
        json(conn, %{data: Enum.map(workout_plans, &workout_plan_json/1)})
    end
  end

  def show_for_student(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    case Accounts.get_student_by_user_id(user.id) do
      nil ->
        {:error, :not_found}

      student ->
        case Workouts.get_workout_plan_for_student(id, student.id) do
          {:ok, workout_plan} ->
            json(conn, %{data: workout_plan_json(workout_plan)})

          {:error, :not_found} ->
            {:error, :not_found}

          {:error, :unauthorized} ->
            {:error, :forbidden}
        end
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
      started_at: workout_plan.started_at,
      completed_at: workout_plan.completed_at,
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
        order_in_workout: we.order_in_workout,
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
