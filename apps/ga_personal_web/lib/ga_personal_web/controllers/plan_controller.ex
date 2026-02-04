defmodule GaPersonalWeb.PlanController do
  use GaPersonalWeb, :controller

  alias GaPersonal.Finance

  action_fallback GaPersonalWeb.FallbackController

  def index(conn, _params) do
    trainer_id = conn.assigns.current_user_id
    plans = Finance.list_plans(trainer_id)
    json(conn, %{data: Enum.map(plans, &plan_json/1)})
  end

  def show(conn, %{"id" => id}) do
    trainer_id = conn.assigns.current_user_id

    case Finance.get_plan_for_trainer(id, trainer_id) do
      {:ok, plan} ->
        json(conn, %{data: plan_json(plan)})

      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :unauthorized} ->
        {:error, :forbidden}
    end
  end

  def create(conn, %{"plan" => plan_params}) do
    trainer_id = conn.assigns.current_user_id
    params = Map.put(plan_params, "trainer_id", trainer_id)

    with {:ok, plan} <- Finance.create_plan(params) do
      conn
      |> put_status(:created)
      |> json(%{data: plan_json(plan)})
    end
  end

  def update(conn, %{"id" => id, "plan" => plan_params}) do
    trainer_id = conn.assigns.current_user_id

    case Finance.get_plan_for_trainer(id, trainer_id) do
      {:ok, plan} ->
        with {:ok, updated} <- Finance.update_plan(plan, plan_params) do
          json(conn, %{data: plan_json(updated)})
        end

      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :unauthorized} ->
        {:error, :forbidden}
    end
  end

  def delete(conn, %{"id" => id}) do
    trainer_id = conn.assigns.current_user_id

    case Finance.get_plan_for_trainer(id, trainer_id) do
      {:ok, plan} ->
        with {:ok, _} <- Finance.delete_plan(plan) do
          send_resp(conn, :no_content, "")
        end

      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :unauthorized} ->
        {:error, :forbidden}
    end
  end

  defp plan_json(plan) do
    %{
      id: plan.id,
      trainer_id: plan.trainer_id,
      name: plan.name,
      description: plan.description,
      price_cents: plan.price_cents,
      currency: plan.currency,
      duration_days: plan.duration_days,
      sessions_per_week: plan.sessions_per_week,
      features: plan.features,
      is_active: plan.is_active,
      inserted_at: plan.inserted_at,
      updated_at: plan.updated_at
    }
  end
end
