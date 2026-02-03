defmodule GaPersonalWeb.GoalController do
  use GaPersonalWeb, :controller

  alias GaPersonal.Evolution
  alias GaPersonal.Guardian

  action_fallback GaPersonalWeb.FallbackController

  def index(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    student_id = Map.get(params, "student_id", user.id)
    goals = Evolution.list_goals(student_id, params)
    json(conn, %{data: Enum.map(goals, &goal_json/1)})
  end

  def show(conn, %{"id" => id}) do
    goal = Evolution.get_goal!(id)
    json(conn, %{data: goal_json(goal)})
  end

  def create(conn, %{"goal" => goal_params}) do
    with {:ok, goal} <- Evolution.create_goal(goal_params) do
      conn
      |> put_status(:created)
      |> json(%{data: goal_json(goal)})
    end
  end

  def update(conn, %{"id" => id, "goal" => goal_params}) do
    goal = Evolution.get_goal!(id)

    with {:ok, updated} <- Evolution.update_goal(goal, goal_params) do
      json(conn, %{data: goal_json(updated)})
    end
  end

  def delete(conn, %{"id" => id}) do
    goal = Evolution.get_goal!(id)

    with {:ok, _} <- Evolution.delete_goal(goal) do
      send_resp(conn, :no_content, "")
    end
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
