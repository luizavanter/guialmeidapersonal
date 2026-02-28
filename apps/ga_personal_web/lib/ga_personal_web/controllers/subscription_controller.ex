defmodule GaPersonalWeb.SubscriptionController do
  use GaPersonalWeb, :controller

  alias GaPersonal.Finance
  alias GaPersonal.Accounts

  action_fallback GaPersonalWeb.FallbackController

  # Trainer actions
  def index(conn, params) do
    trainer_id = conn.assigns.current_user_id
    subscriptions = Finance.list_subscriptions(trainer_id, params)
    json(conn, %{data: Enum.map(subscriptions, &subscription_json/1)})
  end

  def show(conn, %{"id" => id}) do
    trainer_id = conn.assigns.current_user_id

    case Finance.get_subscription_for_trainer(id, trainer_id) do
      {:ok, subscription} ->
        json(conn, %{data: subscription_json(subscription)})

      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :unauthorized} ->
        {:error, :forbidden}
    end
  end

  def create(conn, %{"subscription" => subscription_params}) do
    trainer_id = conn.assigns.current_user_id
    params = Map.put(subscription_params, "trainer_id", trainer_id)

    with {:ok, subscription} <- Finance.create_subscription(params) do
      conn
      |> put_status(:created)
      |> json(%{data: subscription_json(subscription)})
    end
  end

  def update(conn, %{"id" => id, "subscription" => subscription_params}) do
    trainer_id = conn.assigns.current_user_id

    case Finance.get_subscription_for_trainer(id, trainer_id) do
      {:ok, subscription} ->
        with {:ok, updated} <- Finance.update_subscription(subscription, subscription_params) do
          json(conn, %{data: subscription_json(updated)})
        end

      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :unauthorized} ->
        {:error, :forbidden}
    end
  end

  def delete(conn, %{"id" => id}) do
    trainer_id = conn.assigns.current_user_id

    case Finance.get_subscription_for_trainer(id, trainer_id) do
      {:ok, subscription} ->
        reason = "Cancelled by trainer"

        with {:ok, _} <- Finance.cancel_subscription(subscription, reason) do
          send_resp(conn, :no_content, "")
        end

      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :unauthorized} ->
        {:error, :forbidden}
    end
  end

  # Student action - view their own subscription
  def show_for_student(conn, _params) do
    user = conn.assigns.current_user

    case Accounts.get_student_by_user_id(user.id) do
      nil ->
        {:error, :not_found}

      student ->
        case Finance.get_subscription_for_student(student.id) do
          nil ->
            {:error, :not_found}

          subscription ->
            json(conn, %{data: subscription_json(subscription)})
        end
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

  defp student_json(%{student: %Ecto.Association.NotLoaded{}}), do: nil
  defp student_json(%{student: nil}), do: nil
  defp student_json(%{student: student}) do
    %{
      id: student.id,
      email: student.email,
      full_name: student.full_name
    }
  end

  defp plan_info_json(%{plan: plan}) when not is_nil(plan) do
    %{
      id: plan.id,
      name: plan.name,
      price_cents: plan.price_cents
    }
  end

  defp plan_info_json(_), do: nil
end
