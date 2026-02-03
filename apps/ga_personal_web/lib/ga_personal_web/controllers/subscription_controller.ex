defmodule GaPersonalWeb.SubscriptionController do
  use GaPersonalWeb, :controller

  alias GaPersonal.Finance
  alias GaPersonal.Guardian

  action_fallback GaPersonalWeb.FallbackController

  def index(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    subscriptions = Finance.list_subscriptions(user.id, params)
    json(conn, %{data: Enum.map(subscriptions, &subscription_json/1)})
  end

  def show(conn, %{"id" => id}) do
    subscription = Finance.get_subscription!(id)
    json(conn, %{data: subscription_json(subscription)})
  end

  def create(conn, %{"subscription" => subscription_params}) do
    user = Guardian.Plug.current_resource(conn)
    params = Map.put(subscription_params, "trainer_id", user.id)

    with {:ok, subscription} <- Finance.create_subscription(params) do
      conn
      |> put_status(:created)
      |> json(%{data: subscription_json(subscription)})
    end
  end

  def update(conn, %{"id" => id, "subscription" => subscription_params}) do
    subscription = Finance.get_subscription!(id)

    with {:ok, updated} <- Finance.update_subscription(subscription, subscription_params) do
      json(conn, %{data: subscription_json(updated)})
    end
  end

  def delete(conn, %{"id" => id}) do
    subscription = Finance.get_subscription!(id)
    reason = "Deleted by trainer"

    with {:ok, _} <- Finance.cancel_subscription(subscription, reason) do
      send_resp(conn, :no_content, "")
    end
  end

  defp subscription_json(subscription) do
    %{
      id: subscription.id,
      trainer_id: subscription.trainer_id,
      student_id: subscription.student_id,
      plan_id: subscription.plan_id,
      status: subscription.status,
      start_date: subscription.start_date,
      end_date: subscription.end_date,
      cancelled_at: subscription.cancelled_at,
      cancellation_reason: subscription.cancellation_reason,
      inserted_at: subscription.inserted_at,
      updated_at: subscription.updated_at,
      student: student_json(subscription),
      plan: plan_info_json(subscription)
    }
  end

  defp student_json(%{student: student}) when not is_nil(student) do
    %{
      id: student.id,
      user_id: student.user_id
    }
  end

  defp student_json(_), do: nil

  defp plan_info_json(%{plan: plan}) when not is_nil(plan) do
    %{
      id: plan.id,
      name: plan.name,
      price_cents: plan.price_cents
    }
  end

  defp plan_info_json(_), do: nil
end
