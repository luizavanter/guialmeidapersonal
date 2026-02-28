defmodule GaPersonal.Workers.EmailWorker do
  @moduledoc """
  Oban worker for sending emails asynchronously with retries.
  """
  use Oban.Worker, queue: :mailers, max_attempts: 3

  alias GaPersonal.{Mailer, Accounts}
  alias GaPersonal.Emails.UserEmail

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"type" => type} = args}) do
    case type do
      "welcome" ->
        send_to_user(args, &UserEmail.welcome/1)

      "appointment_confirmation" ->
        send_with_data(args, &UserEmail.appointment_confirmation/2)

      "appointment_reminder" ->
        send_with_data(args, &UserEmail.appointment_reminder/2)

      "appointment_cancelled" ->
        send_with_data(args, &UserEmail.appointment_cancelled/2)

      "payment_reminder" ->
        send_with_data(args, &UserEmail.payment_reminder/2)

      "payment_received" ->
        send_with_data(args, &UserEmail.payment_received/2)

      "new_workout_plan" ->
        send_with_data(args, &UserEmail.new_workout_plan/2)

      "assessment_scheduled" ->
        send_with_data(args, &UserEmail.assessment_scheduled/2)

      _ ->
        {:error, "Unknown email type: #{type}"}
    end
  end

  defp send_to_user(%{"user_id" => user_id}, email_fn) do
    case Accounts.get_user(user_id) do
      nil -> {:error, "User not found: #{user_id}"}
      user ->
        user
        |> email_fn.()
        |> Mailer.deliver()

        :ok
    end
  end

  defp send_with_data(%{"user_id" => user_id, "data" => data}, email_fn) do
    case Accounts.get_user(user_id) do
      nil -> {:error, "User not found: #{user_id}"}
      user ->
        user
        |> email_fn.(atomize_keys(data))
        |> Mailer.deliver()

        :ok
    end
  end

  defp atomize_keys(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {String.to_existing_atom(k), v} end)
  rescue
    ArgumentError -> map
  end

  # Enqueue helpers

  def enqueue_welcome(user_id) do
    %{type: "welcome", user_id: user_id}
    |> new()
    |> Oban.insert()
  end

  def enqueue_appointment_confirmation(user_id, appointment_data) do
    %{type: "appointment_confirmation", user_id: user_id, data: appointment_data}
    |> new()
    |> Oban.insert()
  end

  def enqueue_appointment_cancelled(user_id, appointment_data) do
    %{type: "appointment_cancelled", user_id: user_id, data: appointment_data}
    |> new()
    |> Oban.insert()
  end

  def enqueue_payment_received(user_id, payment_data) do
    %{type: "payment_received", user_id: user_id, data: payment_data}
    |> new()
    |> Oban.insert()
  end

  def enqueue_new_workout_plan(user_id, plan_data) do
    %{type: "new_workout_plan", user_id: user_id, data: plan_data}
    |> new()
    |> Oban.insert()
  end
end
