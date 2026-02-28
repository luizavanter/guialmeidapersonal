defmodule GaPersonal.Workers.PaymentDueReminder do
  @moduledoc """
  Oban cron worker that runs daily at 6 AM.
  Finds payments due in 3 days and overdue payments, sending reminders.
  """
  use Oban.Worker, queue: :scheduled, max_attempts: 1

  alias GaPersonal.{Repo, Mailer}
  alias GaPersonal.Finance.Payment
  alias GaPersonal.Emails.UserEmail
  alias GaPersonal.Messaging
  import Ecto.Query

  @impl Oban.Worker
  def perform(_job) do
    send_upcoming_reminders()
    send_overdue_notifications()
    :ok
  end

  defp send_upcoming_reminders do
    due_date = Date.utc_today() |> Date.add(3)

    from(p in Payment,
      where: p.due_date == ^due_date and p.status == "pending",
      preload: [:student, :trainer]
    )
    |> Repo.all()
    |> Enum.each(&send_due_reminder/1)
  end

  defp send_overdue_notifications do
    today = Date.utc_today()

    from(p in Payment,
      where: p.due_date < ^today and p.status == "pending",
      preload: [:student, :trainer]
    )
    |> Repo.all()
    |> Enum.each(&send_overdue_notice/1)
  end

  defp send_due_reminder(payment) do
    if payment.student do
      payment_data = %{
        amount_cents: payment.amount_cents,
        due_date: payment.due_date,
        currency: payment.currency || "BRL"
      }

      payment.student
      |> UserEmail.payment_reminder(payment_data)
      |> Mailer.deliver()

      Messaging.create_notification(%{
        user_id: payment.student_id,
        type: "payment_due",
        title: "Pagamento próximo do vencimento",
        body: "Seu pagamento de R$ #{format_cents(payment.amount_cents)} vence em 3 dias",
        action_url: "/payments",
        delivery_method: "in_app"
      })
    end
  rescue
    e -> require(Logger); Logger.error("Failed to send payment reminder: #{inspect(e)}")
  end

  defp send_overdue_notice(payment) do
    if payment.trainer do
      Messaging.create_notification(%{
        user_id: payment.trainer_id,
        type: "payment_overdue",
        title: "Pagamento em atraso",
        body: "Pagamento de R$ #{format_cents(payment.amount_cents)} está em atraso (vencimento: #{payment.due_date})",
        action_url: "/finance/payments",
        delivery_method: "in_app"
      })
    end
  rescue
    e -> require(Logger); Logger.error("Failed to send overdue notice: #{inspect(e)}")
  end

  defp format_cents(cents) when is_integer(cents) do
    :erlang.float_to_binary(cents / 100, decimals: 2)
  end

  defp format_cents(_), do: "0.00"
end
