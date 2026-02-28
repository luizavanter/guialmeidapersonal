defmodule GaPersonal.Asaas.Charges do
  @moduledoc """
  Asaas Charges (Cobranças) API.
  Creates and manages payment charges via Pix, Boleto, or Credit Card.
  """

  alias GaPersonal.Asaas.Client

  @doc """
  Creates a new charge in Asaas.

  Required fields:
    - customer: Asaas customer ID
    - billingType: "PIX", "BOLETO", or "CREDIT_CARD"
    - value: Amount in BRL (float, e.g. 150.00)
    - dueDate: Due date as "YYYY-MM-DD" string

  Optional fields:
    - description, externalReference, installmentCount, installmentValue, etc.
  """
  def create(attrs) when is_map(attrs) do
    Client.post("/payments", attrs)
  end

  @doc """
  Gets a charge by Asaas ID.
  """
  def get(charge_id) when is_binary(charge_id) do
    Client.get("/payments/#{charge_id}")
  end

  @doc """
  Gets the Pix QR code for a charge.
  Returns the QR code image (base64) and copy-paste payload.
  """
  def get_pix_qr_code(charge_id) when is_binary(charge_id) do
    Client.get("/payments/#{charge_id}/pixQrCode")
  end

  @doc """
  Gets the boleto identification line for a charge.
  """
  def get_identification_field(charge_id) when is_binary(charge_id) do
    Client.get("/payments/#{charge_id}/identificationField")
  end

  @doc """
  Cancels/deletes a charge in Asaas.
  """
  def cancel(charge_id) when is_binary(charge_id) do
    Client.delete("/payments/#{charge_id}")
  end

  @doc """
  Refunds a charge (full or partial).
  """
  def refund(charge_id, value \\ nil) when is_binary(charge_id) do
    body = if value, do: %{"value" => value}, else: %{}
    Client.post("/payments/#{charge_id}/refund", body)
  end

  @doc """
  Lists charges for a customer.
  """
  def list_by_customer(customer_id, opts \\ []) do
    query = Keyword.merge([customer: customer_id], opts)
    Client.get("/payments", query: query)
  end

  @doc """
  Builds charge params from a local payment record and student profile.

  billing_type: "PIX", "BOLETO", or "CREDIT_CARD"
  """
  def build_charge_params(payment, asaas_customer_id, billing_type) do
    %{
      "customer" => asaas_customer_id,
      "billingType" => billing_type,
      "value" => payment.amount_cents / 100,
      "dueDate" => Date.to_iso8601(payment.due_date || Date.utc_today()),
      "description" => "GA Personal - Pagamento #{payment.id}",
      "externalReference" => payment.id
    }
  end

  @doc """
  Maps Asaas billing type to local payment_method.
  """
  def billing_type_to_payment_method(billing_type) do
    case billing_type do
      "PIX" -> "pix"
      "BOLETO" -> "boleto"
      "CREDIT_CARD" -> "credit_card"
      _ -> "pix"
    end
  end

  @doc """
  Maps local payment_method to Asaas billing type.
  """
  def payment_method_to_billing_type(payment_method) do
    case payment_method do
      "pix" -> "PIX"
      "boleto" -> "BOLETO"
      "credit_card" -> "CREDIT_CARD"
      _ -> "PIX"
    end
  end
end
