defmodule GaPersonal.Workers.WeeklyTrainerSummary do
  @moduledoc """
  Oban cron worker that runs every Monday at 7 AM.
  Sends a weekly summary email to all active trainers with
  upcoming appointments, pending payments, and student stats.
  """
  use Oban.Worker, queue: :scheduled, max_attempts: 1

  alias GaPersonal.{Repo, Mailer}
  alias GaPersonal.Accounts.User
  alias GaPersonal.Schedule.Appointment
  alias GaPersonal.Finance.Payment
  alias GaPersonal.Accounts.StudentProfile
  import Ecto.Query

  @impl Oban.Worker
  def perform(_job) do
    trainers =
      from(u in User, where: u.role == "trainer" and u.active == true)
      |> Repo.all()

    Enum.each(trainers, &send_summary/1)
    :ok
  end

  defp send_summary(trainer) do
    week_start = Date.utc_today()
    week_end = Date.add(week_start, 7)

    upcoming_appointments = count_upcoming_appointments(trainer.id, week_start, week_end)
    pending_payments = count_pending_payments(trainer.id)
    active_students = count_active_students(trainer.id)

    summary_data = %{
      trainer_name: trainer.full_name,
      week_start: week_start,
      week_end: week_end,
      upcoming_appointments: upcoming_appointments,
      pending_payments: pending_payments,
      active_students: active_students
    }

    trainer
    |> build_summary_email(summary_data)
    |> Mailer.deliver()
  rescue
    e -> require(Logger); Logger.error("Failed to send weekly summary for #{trainer.id}: #{inspect(e)}")
  end

  defp count_upcoming_appointments(trainer_id, start_date, end_date) do
    start_dt = DateTime.new!(start_date, ~T[00:00:00], "Etc/UTC")
    end_dt = DateTime.new!(end_date, ~T[00:00:00], "Etc/UTC")

    from(a in Appointment,
      where: a.trainer_id == ^trainer_id,
      where: a.scheduled_at >= ^start_dt and a.scheduled_at < ^end_dt,
      where: a.status == "scheduled"
    )
    |> Repo.aggregate(:count)
  end

  defp count_pending_payments(trainer_id) do
    from(p in Payment,
      where: p.trainer_id == ^trainer_id and p.status == "pending"
    )
    |> Repo.aggregate(:count)
  end

  defp count_active_students(trainer_id) do
    from(sp in StudentProfile,
      where: sp.trainer_id == ^trainer_id and sp.status == "active"
    )
    |> Repo.aggregate(:count)
  end

  defp build_summary_email(trainer, data) do
    config = Application.get_env(:ga_personal, :mailer_from, [])
    from_name = config[:name] || "GA Personal"
    from_email = config[:email] || "noreply@guialmeidapersonal.esp.br"

    Swoosh.Email.new()
    |> Swoosh.Email.to({trainer.full_name, trainer.email})
    |> Swoosh.Email.from({from_name, from_email})
    |> Swoosh.Email.subject("📊 Resumo Semanal — GA Personal")
    |> Swoosh.Email.html_body(summary_html(data))
    |> Swoosh.Email.text_body(summary_text(data))
  end

  defp summary_html(data) do
    """
    <div style="font-family: 'Outfit', sans-serif; max-width: 600px; margin: 0 auto; background: #0A0A0A; color: #F5F5F0; padding: 32px;">
      <h1 style="color: #C4F53A; font-size: 24px; margin-bottom: 24px;">Resumo Semanal</h1>
      <p>Olá #{data.trainer_name},</p>
      <p>Aqui está o resumo da sua semana (#{format_date(data.week_start)} — #{format_date(data.week_end)}):</p>
      <div style="background: #1A1A1A; border-radius: 8px; padding: 20px; margin: 20px 0;">
        <div style="display: flex; justify-content: space-between; margin-bottom: 12px;">
          <span>Aulas agendadas:</span>
          <strong style="color: #C4F53A;">#{data.upcoming_appointments}</strong>
        </div>
        <div style="display: flex; justify-content: space-between; margin-bottom: 12px;">
          <span>Pagamentos pendentes:</span>
          <strong style="color: #{if data.pending_payments > 0, do: "#F87171", else: "#C4F53A"};">#{data.pending_payments}</strong>
        </div>
        <div style="display: flex; justify-content: space-between;">
          <span>Alunos ativos:</span>
          <strong style="color: #C4F53A;">#{data.active_students}</strong>
        </div>
      </div>
      <a href="https://admin.guialmeidapersonal.esp.br" style="display: inline-block; background: #C4F53A; color: #0A0A0A; padding: 12px 24px; border-radius: 6px; text-decoration: none; font-weight: 600;">Abrir Painel</a>
      <p style="color: #888; font-size: 12px; margin-top: 32px;">GA Personal — Treinamento & Performance</p>
    </div>
    """
  end

  defp summary_text(data) do
    """
    Resumo Semanal — GA Personal

    Olá #{data.trainer_name},

    Semana #{format_date(data.week_start)} — #{format_date(data.week_end)}:
    - Aulas agendadas: #{data.upcoming_appointments}
    - Pagamentos pendentes: #{data.pending_payments}
    - Alunos ativos: #{data.active_students}

    Acesse: https://admin.guialmeidapersonal.esp.br
    """
  end

  defp format_date(date), do: Calendar.strftime(date, "%d/%m/%Y")
end
