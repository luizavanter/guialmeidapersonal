defmodule GaPersonal.Workers.AutoBillingWorker do
  @moduledoc """
  Oban cron worker that runs daily at 8 AM.
  Checks active subscriptions with upcoming billing dates and
  automatically creates Asaas charges + local payment records.
  """
  use Oban.Worker, queue: :scheduled, max_attempts: 1

  require Logger

  alias GaPersonal.{Repo, Finance}
  alias GaPersonal.Finance.{Subscription, Payment}
  alias GaPersonal.Accounts
  alias GaPersonal.Asaas.Charges
  import Ecto.Query

  @impl Oban.Worker
  def perform(_job) do
    if asaas_configured?() do
      process_upcoming_billings()
    else
      Logger.info("AutoBillingWorker: Asaas not configured, skipping")
    end

    :ok
  end

  defp process_upcoming_billings do
    today = Date.utc_today()
    billing_date = Date.add(today, 3)

    subscriptions =
      from(s in Subscription,
        where: s.status == "active",
        where: s.next_billing_date <= ^billing_date,
        where: s.auto_renew == true,
        preload: [:student, :plan]
      )
      |> Repo.all()

    Logger.info("AutoBillingWorker: Found #{length(subscriptions)} subscriptions to bill")

    Enum.each(subscriptions, fn subscription ->
      create_charge_for_subscription(subscription)
    end)
  end

  defp create_charge_for_subscription(subscription) do
    # Check if payment already exists for this billing period
    if payment_exists_for_period?(subscription) do
      Logger.info("AutoBillingWorker: Payment already exists for subscription #{subscription.id}")
      return_ok()
    else
      do_create_charge(subscription)
    end
  rescue
    e ->
      Logger.error("AutoBillingWorker: Failed for subscription #{subscription.id}: #{inspect(e)}")
  end

  defp do_create_charge(subscription) do
    student_profile = Accounts.get_student_by_user_id(subscription.student_id)

    unless student_profile && student_profile.asaas_customer_id do
      Logger.warning("AutoBillingWorker: Student #{subscription.student_id} has no Asaas customer")
      return_ok()
    else
      amount_cents = subscription.plan.price_cents
      due_date = subscription.next_billing_date || Date.utc_today()

      # Create local payment record first
      payment_attrs = %{
        "student_id" => subscription.student_id,
        "trainer_id" => subscription.trainer_id,
        "subscription_id" => subscription.id,
        "amount_cents" => amount_cents,
        "currency" => "BRL",
        "status" => "pending",
        "payment_method" => "pix",
        "due_date" => due_date
      }

      case Finance.create_payment(payment_attrs) do
        {:ok, payment} ->
          # Create Asaas charge
          billing_type = "PIX"
          charge_params = Charges.build_charge_params(payment, student_profile.asaas_customer_id, billing_type)

          case Charges.create(charge_params) do
            {:ok, charge} ->
              Finance.update_payment(payment, %{
                asaas_charge_id: charge["id"],
                asaas_invoice_url: charge["invoiceUrl"]
              })

              # Advance next billing date
              advance_billing_date(subscription)

              Logger.info("AutoBillingWorker: Created charge #{charge["id"]} for subscription #{subscription.id}")

            {:error, reason} ->
              Logger.error("AutoBillingWorker: Asaas charge failed: #{inspect(reason)}")
          end

        {:error, reason} ->
          Logger.error("AutoBillingWorker: Failed to create payment: #{inspect(reason)}")
      end
    end
  end

  defp payment_exists_for_period?(subscription) do
    from(p in Payment,
      where: p.subscription_id == ^subscription.id,
      where: p.due_date == ^subscription.next_billing_date,
      where: p.status in ["pending", "completed"]
    )
    |> Repo.exists?()
  end

  defp advance_billing_date(subscription) do
    next_date =
      case subscription.plan.duration_days do
        days when is_integer(days) and days > 0 ->
          Date.add(subscription.next_billing_date || Date.utc_today(), days)

        _ ->
          Date.add(subscription.next_billing_date || Date.utc_today(), 30)
      end

    Finance.update_subscription(subscription, %{next_billing_date: next_date})
  end

  defp asaas_configured? do
    Application.get_env(:ga_personal, :asaas)[:api_key] != nil
  end

  defp return_ok, do: :ok
end
