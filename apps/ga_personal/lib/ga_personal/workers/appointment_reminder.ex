defmodule GaPersonal.Workers.AppointmentReminder do
  @moduledoc """
  Oban cron worker that runs daily at 6 AM.
  Finds appointments scheduled for tomorrow and sends reminder emails + notifications.
  """
  use Oban.Worker, queue: :scheduled, max_attempts: 1

  alias GaPersonal.{Repo, Mailer}
  alias GaPersonal.Schedule.Appointment
  alias GaPersonal.Emails.UserEmail
  alias GaPersonal.Messaging
  import Ecto.Query

  @impl Oban.Worker
  def perform(_job) do
    tomorrow_start = Date.utc_today() |> Date.add(1) |> DateTime.new!(~T[00:00:00], "Etc/UTC")
    tomorrow_end = Date.utc_today() |> Date.add(2) |> DateTime.new!(~T[00:00:00], "Etc/UTC")

    appointments =
      from(a in Appointment,
        where: a.scheduled_at >= ^tomorrow_start and a.scheduled_at < ^tomorrow_end,
        where: a.status == "scheduled",
        preload: [:student, :trainer]
      )
      |> Repo.all()

    Enum.each(appointments, fn appointment ->
      send_reminder(appointment)
    end)

    :ok
  end

  defp send_reminder(appointment) do
    student = appointment.student
    if student do
      appointment_data = %{
        date: DateTime.to_date(appointment.scheduled_at),
        time: DateTime.to_time(appointment.scheduled_at),
        duration: appointment.duration_minutes,
        location: appointment.location,
        trainer_name: if(appointment.trainer, do: appointment.trainer.full_name, else: "Trainer")
      }

      # Send email
      student
      |> UserEmail.appointment_reminder(appointment_data)
      |> Mailer.deliver()

      # Create in-app notification
      Messaging.create_notification(%{
        user_id: student.id,
        type: "appointment_reminder",
        title: "Lembrete: Treino Amanhã",
        body: "Você tem treino agendado amanhã às #{Calendar.strftime(appointment.scheduled_at, "%H:%M")}",
        action_url: "/schedule",
        delivery_method: "in_app"
      })
    end
  rescue
    e -> require(Logger); Logger.error("Failed to send appointment reminder: #{inspect(e)}")
  end
end
