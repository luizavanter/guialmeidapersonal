defmodule GaPersonal.NotificationService do
  @moduledoc """
  Centralized service for dual delivery notifications (email + in-app).
  All event-driven notifications should go through this module.
  """

  alias GaPersonal.Messaging
  alias GaPersonal.Workers.EmailWorker

  def on_student_created(user) do
    EmailWorker.enqueue_welcome(user.id)

    Messaging.create_notification(%{
      user_id: user.id,
      type: "welcome",
      title: "Bem-vindo ao GA Personal!",
      body: "Sua conta foi criada com sucesso. Acesse o portal do aluno para ver seus treinos.",
      action_url: "/dashboard",
      delivery_method: "in_app"
    })
  end

  def on_appointment_created(appointment, student_id) do
    data = %{
      date: DateTime.to_date(appointment.scheduled_at) |> Date.to_iso8601(),
      time: DateTime.to_time(appointment.scheduled_at) |> Time.to_iso8601(),
      duration: appointment.duration_minutes,
      location: appointment.location || ""
    }

    EmailWorker.enqueue_appointment_confirmation(student_id, data)

    Messaging.create_notification(%{
      user_id: student_id,
      type: "appointment_confirmation",
      title: "Treino Agendado",
      body: "Novo treino agendado para #{data.date} às #{data.time}",
      action_url: "/schedule",
      delivery_method: "in_app"
    })
  end

  def on_appointment_cancelled(appointment, student_id, reason) do
    data = %{
      date: DateTime.to_date(appointment.scheduled_at) |> Date.to_iso8601(),
      time: DateTime.to_time(appointment.scheduled_at) |> Time.to_iso8601(),
      reason: reason || ""
    }

    EmailWorker.enqueue_appointment_cancelled(student_id, data)

    Messaging.create_notification(%{
      user_id: student_id,
      type: "appointment_cancelled",
      title: "Treino Cancelado",
      body: "Seu treino de #{data.date} foi cancelado#{if reason, do: ": #{reason}", else: ""}",
      action_url: "/schedule",
      delivery_method: "in_app"
    })
  end

  def on_payment_received(payment) do
    if payment.student_id do
      data = %{
        amount_cents: payment.amount_cents,
        payment_method: payment.payment_method || "pix",
        payment_date: (payment.payment_date || Date.utc_today()) |> Date.to_iso8601()
      }

      EmailWorker.enqueue_payment_received(payment.student_id, data)

      Messaging.create_notification(%{
        user_id: payment.student_id,
        type: "payment_received",
        title: "Pagamento Confirmado",
        body: "Seu pagamento foi confirmado com sucesso",
        action_url: "/payments",
        delivery_method: "in_app"
      })
    end
  end

  def on_workout_plan_assigned(plan, student_id) do
    data = %{
      plan_name: plan.name,
      description: plan.description || ""
    }

    EmailWorker.enqueue_new_workout_plan(student_id, data)

    Messaging.create_notification(%{
      user_id: student_id,
      type: "workout_assigned",
      title: "Novo Plano de Treino",
      body: "Um novo plano de treino foi atribuído: #{plan.name}",
      action_url: "/workouts",
      delivery_method: "in_app"
    })
  end
end
