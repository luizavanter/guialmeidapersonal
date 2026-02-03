defmodule GaPersonalWeb.PaymentController do
  use GaPersonalWeb, :controller

  alias GaPersonal.Finance
  alias GaPersonal.Finance.Payment
  alias GaPersonal.Repo
  alias GaPersonal.Guardian

  action_fallback GaPersonalWeb.FallbackController

  def index(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    payments = Finance.list_payments(user.id, params)
    json(conn, %{data: Enum.map(payments, &payment_json/1)})
  end

  def show(conn, %{"id" => id}) do
    payment = Payment
    |> Repo.get!(id)
    |> Repo.preload([:student, :subscription])

    json(conn, %{data: payment_json(payment)})
  end

  def create(conn, %{"payment" => payment_params}) do
    user = Guardian.Plug.current_resource(conn)
    params = Map.put(payment_params, "trainer_id", user.id)

    with {:ok, payment} <- Finance.create_payment(params) do
      conn
      |> put_status(:created)
      |> json(%{data: payment_json(payment)})
    end
  end

  def update(conn, %{"id" => id, "payment" => payment_params}) do
    payment = Repo.get!(Payment, id)

    with {:ok, updated} <- Finance.update_payment(payment, payment_params) do
      json(conn, %{data: payment_json(updated)})
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
      external_reference: payment.external_reference,
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
