defmodule GaPersonalWeb.PaymentController do
  use GaPersonalWeb, :controller

  alias GaPersonal.Finance
  alias GaPersonal.Accounts
  alias GaPersonal.Asaas.Charges
  import GaPersonalWeb.Helpers.StudentResolver, only: [resolve_and_verify_student: 2]

  require Logger

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
    student_id = Map.get(payment_params, "student_id")

    case resolve_and_verify_student(student_id, trainer_id) do
      {:ok, user_id} ->
        params = payment_params
        |> Map.put("student_id", user_id)
        |> Map.put("trainer_id", trainer_id)

        with {:ok, payment} <- Finance.create_payment(params) do
          conn
          |> put_status(:created)
          |> json(%{data: payment_json(payment)})
        end

      {:error, reason} ->
        {:error, reason}
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

  @doc """
  Creates a charge in Asaas for an existing payment.
  POST /api/v1/payments/:id/charge

  Params:
    - billing_type: "PIX", "BOLETO", or "CREDIT_CARD" (default: "PIX")
  """
  def create_charge(conn, %{"id" => id} = params) do
    trainer_id = conn.assigns.current_user_id
    billing_type = params["billing_type"] || "PIX"

    with {:ok, payment} <- Finance.get_payment_for_trainer(id, trainer_id),
         {:ok, student_profile} <- get_student_profile(payment.student_id),
         {:ok, asaas_customer_id} <- ensure_asaas_customer(student_profile),
         charge_params = Charges.build_charge_params(payment, asaas_customer_id, billing_type),
         {:ok, charge} <- Charges.create(charge_params) do
      # Update local payment with Asaas data
      asaas_attrs = %{
        asaas_charge_id: charge["id"],
        asaas_invoice_url: charge["invoiceUrl"],
        payment_method: Charges.billing_type_to_payment_method(billing_type)
      }

      # Fetch Pix QR code if billing type is PIX
      asaas_attrs =
        if billing_type == "PIX" do
          case Charges.get_pix_qr_code(charge["id"]) do
            {:ok, pix_data} ->
              asaas_attrs
              |> Map.put(:asaas_pix_qr_code, pix_data["encodedImage"])
              |> Map.put(:asaas_pix_payload, pix_data["payload"])

            _ ->
              asaas_attrs
          end
        else
          asaas_attrs
        end

      # Fetch boleto URL if billing type is BOLETO
      asaas_attrs =
        if billing_type == "BOLETO" do
          Map.put(asaas_attrs, :asaas_bankslip_url, charge["bankSlipUrl"])
        else
          asaas_attrs
        end

      case Finance.update_payment(payment, asaas_attrs) do
        {:ok, updated} ->
          json(conn, %{data: payment_json(updated), charge: charge_json(charge, asaas_attrs)})

        {:error, _} ->
          # Charge was created in Asaas but local update failed — return charge data anyway
          json(conn, %{data: payment_json(payment), charge: charge_json(charge, asaas_attrs)})
      end
    else
      {:error, :not_found} -> {:error, :not_found}
      {:error, :forbidden} -> {:error, :forbidden}
      {:error, :no_asaas_customer} ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: "Student does not have an Asaas customer. Ensure CPF is set."})
      {:error, reason} ->
        Logger.error("Failed to create Asaas charge: #{inspect(reason)}")
        conn |> put_status(:unprocessable_entity) |> json(%{error: "Failed to create charge", details: inspect(reason)})
    end
  end

  defp get_student_profile(student_user_id) do
    case Accounts.get_student_by_user_id(student_user_id) do
      nil -> {:error, :not_found}
      profile -> {:ok, profile}
    end
  end

  defp ensure_asaas_customer(student_profile) do
    case student_profile.asaas_customer_id do
      nil -> {:error, :no_asaas_customer}
      id -> {:ok, id}
    end
  end

  defp charge_json(charge, asaas_attrs) do
    %{
      asaas_charge_id: charge["id"],
      invoice_url: charge["invoiceUrl"],
      bankslip_url: charge["bankSlipUrl"],
      pix_qr_code: Map.get(asaas_attrs, :asaas_pix_qr_code),
      pix_payload: Map.get(asaas_attrs, :asaas_pix_payload),
      status: charge["status"]
    }
  end

  # Student action - view their own payment history
  def index_for_student(conn, params) do
    user = conn.assigns.current_user

    payments = Finance.list_payments_for_student(user.id, params)
    json(conn, %{data: Enum.map(payments, &payment_json/1)})
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

  defp student_json(%{student: %Ecto.Association.NotLoaded{}}), do: nil
  defp student_json(%{student: nil}), do: nil
  defp student_json(%{student: student}) do
    %{
      id: student.id,
      email: student.email,
      full_name: student.full_name
    }
  end

  defp subscription_info_json(%{subscription: subscription}) when not is_nil(subscription) do
    %{
      id: subscription.id,
      plan_id: subscription.plan_id,
      status: subscription.status
    }
  end

  defp subscription_info_json(_), do: nil
end
