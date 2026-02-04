defmodule GaPersonalWeb.PaymentController do
  use GaPersonalWeb, :controller

  alias GaPersonal.Finance
  alias GaPersonal.Accounts

  action_fallback GaPersonalWeb.FallbackController

  # Trainer actions
  def index(conn, params) do
    trainer_id = conn.assigns.current_user_id
    payments = Finance.list_payments(trainer_id, params)
    json(conn, %{data: Enum.map(payments, &payment_json/1)})
  end

  def show(conn, %{"id" => id}) do
    trainer_id = conn.assigns.current_user_id

    case Finance.get_payment_for_trainer(id, trainer_id) do
      {:ok, payment} ->
        json(conn, %{data: payment_json(payment)})

      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :unauthorized} ->
        {:error, :forbidden}
    end
  end

  def create(conn, %{"payment" => payment_params}) do
    trainer_id = conn.assigns.current_user_id
    params = Map.put(payment_params, "trainer_id", trainer_id)

    with {:ok, payment} <- Finance.create_payment(params) do
      conn
      |> put_status(:created)
      |> json(%{data: payment_json(payment)})
    end
  end

  def update(conn, %{"id" => id, "payment" => payment_params}) do
    trainer_id = conn.assigns.current_user_id

    case Finance.get_payment_for_trainer(id, trainer_id) do
      {:ok, payment} ->
        with {:ok, updated} <- Finance.update_payment(payment, payment_params) do
          json(conn, %{data: payment_json(updated)})
        end

      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :unauthorized} ->
        {:error, :forbidden}
    end
  end

  # Student action - view their own payment history
  def index_for_student(conn, params) do
    user = conn.assigns.current_user

    case Accounts.get_student_by_user_id(user.id) do
      nil ->
        {:error, :not_found}

      student ->
        payments = Finance.list_payments_for_student(student.id, params)
        json(conn, %{data: Enum.map(payments, &payment_json/1)})
    end
  end

  defp payment_json(payment) do
    %{
      id: payment.id,
      trainer_id: payment.trainer_id,
      student_id: payment.student_id,
      subscription_id: payment.subscription_id,
      amount_cents: payment.amount_cents,
      currency: payment.currency,
      status: payment.status,
      payment_method: payment.payment_method,
      payment_date: payment.payment_date,
      due_date: payment.due_date,
      reference_number: payment.reference_number,
      notes: payment.notes,
      inserted_at: payment.inserted_at,
      updated_at: payment.updated_at,
      student: student_json(payment),
      subscription: subscription_info_json(payment)
    }
  end

  defp student_json(%{student: student}) when not is_nil(student) do
    %{
      id: student.id,
      user_id: student.user_id
    }
  end

  defp student_json(_), do: nil

  defp subscription_info_json(%{subscription: subscription}) when not is_nil(subscription) do
    %{
      id: subscription.id,
      plan_id: subscription.plan_id,
      status: subscription.status
    }
  end

  defp subscription_info_json(_), do: nil
end
