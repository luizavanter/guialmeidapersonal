defmodule GaPersonalWeb.GoalController do
  use GaPersonalWeb, :controller

  alias GaPersonal.Evolution
  alias GaPersonal.Accounts

  action_fallback GaPersonalWeb.FallbackController

  # Trainer actions - manage goals for their students
  def index(conn, %{"student_id" => student_id} = params) do
    trainer_id = conn.assigns.current_user_id

    case Accounts.get_student_for_trainer(student_id, trainer_id) do
      {:ok, _student} ->
        goals = Evolution.list_goals(student_id, params)
        json(conn, %{data: Enum.map(goals, &goal_json/1)})

      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :unauthorized} ->
        {:error, :forbidden}
    end
  end

  def index(conn, _params) do
    {:error, :bad_request, "student_id is required"}
  end

  def show(conn, %{"id" => id}) do
    trainer_id = conn.assigns.current_user_id

    case Evolution.get_goal_for_trainer(id, trainer_id) do
      {:ok, goal} ->
        json(conn, %{data: goal_json(goal)})

      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :unauthorized} ->
        {:error, :forbidden}
    end
  end

  def create(conn, %{"goal" => goal_params}) do
    trainer_id = conn.assigns.current_user_id
    student_id = Map.get(goal_params, "student_id")

    case Accounts.get_student_for_trainer(student_id, trainer_id) do
      {:ok, _student} ->
        with {:ok, goal} <- Evolution.create_goal(goal_params) do
          conn
          |> put_status(:created)
          |> json(%{data: goal_json(goal)})
        end

      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :unauthorized} ->
        {:error, :forbidden}
    end
  end

  def update(conn, %{"id" => id, "goal" => goal_params}) do
    trainer_id = conn.assigns.current_user_id

    case Evolution.get_goal_for_trainer(id, trainer_id) do
      {:ok, goal} ->
        with {:ok, updated} <- Evolution.update_goal(goal, goal_params) do
          json(conn, %{data: goal_json(updated)})
        end

      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :unauthorized} ->
        {:error, :forbidden}
    end
  end

  def delete(conn, %{"id" => id}) do
    trainer_id = conn.assigns.current_user_id

    case Evolution.get_goal_for_trainer(id, trainer_id) do
      {:ok, goal} ->
        with {:ok, _} <- Evolution.delete_goal(goal) do
          send_resp(conn, :no_content, "")
        end

      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :unauthorized} ->
        {:error, :forbidden}
    end
  end

  # Student actions (read-only with progress update capability)
  def index_for_student(conn, params) do
    user = conn.assigns.current_user

    case Accounts.get_student_by_user_id(user.id) do
      nil ->
        {:error, :not_found}

      student ->
        goals = Evolution.list_goals(student.id, params)
        json(conn, %{data: Enum.map(goals, &goal_json/1)})
    end
  end

  def show_for_student(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    case Accounts.get_student_by_user_id(user.id) do
      nil ->
        {:error, :not_found}

      student ->
        case Evolution.get_goal_for_student(id, student.id) do
          {:ok, goal} ->
            json(conn, %{data: goal_json(goal)})

          {:error, :not_found} ->
            {:error, :not_found}

          {:error, :unauthorized} ->
            {:error, :forbidden}
        end
    end
  end

  def update_progress(conn, %{"id" => id, "current_value" => current_value}) do
    user = conn.assigns.current_user

    case Accounts.get_student_by_user_id(user.id) do
      nil ->
        {:error, :not_found}

      student ->
        case Evolution.get_goal_for_student(id, student.id) do
          {:ok, goal} ->
            # Students can only update their current progress value
            with {:ok, updated} <- Evolution.update_goal(goal, %{current_value: current_value}) do
              json(conn, %{data: goal_json(updated)})
            end

          {:error, :not_found} ->
            {:error, :not_found}

          {:error, :unauthorized} ->
            {:error, :forbidden}
        end
    end
  end

  def update_progress(conn, _params) do
    {:error, :bad_request, "current_value is required"}
  end

  defp goal_json(goal) do
    %{
      id: goal.id,
      student_id: goal.student_id,
      goal_type: goal.goal_type,
      title: goal.title,
      description: goal.description,
      target_value: goal.target_value,
      current_value: goal.current_value,
      unit: goal.unit,
      status: goal.status,
      target_date: goal.target_date,
      achieved_at: goal.achieved_at,
      inserted_at: goal.inserted_at,
      updated_at: goal.updated_at
    }
  end
end
