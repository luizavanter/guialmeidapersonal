defmodule GaPersonal.Schedule do
  @moduledoc """
  The Schedule context - handles time slots and appointments.
  """

  import Ecto.Query, warn: false
  alias GaPersonal.Repo
  alias GaPersonal.Schedule.{TimeSlot, Appointment}

  ## TimeSlot functions

  def list_time_slots(trainer_id) do
    from(ts in TimeSlot,
      where: ts.trainer_id == ^trainer_id,
      order_by: [ts.day_of_week, ts.start_time]
    )
    |> Repo.all()
  end

  def get_time_slot!(id), do: Repo.get!(TimeSlot, id)

  def create_time_slot(attrs \\ %{}) do
    %TimeSlot{}
    |> TimeSlot.changeset(attrs)
    |> Repo.insert()
  end

  def update_time_slot(%TimeSlot{} = time_slot, attrs) do
    time_slot
    |> TimeSlot.changeset(attrs)
    |> Repo.update()
  end

  def delete_time_slot(%TimeSlot{} = time_slot) do
    Repo.delete(time_slot)
  end

  ## Appointment functions

  def list_appointments(trainer_id, filters \\ %{}) do
    query = from a in Appointment,
      where: a.trainer_id == ^trainer_id,
      preload: [:student],
      order_by: [desc: a.scheduled_at]

    query
    |> apply_appointment_filters(filters)
    |> Repo.all()
  end

  defp apply_appointment_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {:status, status}, query ->
        from a in query, where: a.status == ^status

      {:student_id, student_id}, query ->
        from a in query, where: a.student_id == ^student_id

      {:date_from, date_from}, query ->
        from a in query, where: a.scheduled_at >= ^date_from

      {:date_to, date_to}, query ->
        from a in query, where: a.scheduled_at <= ^date_to

      _, query ->
        query
    end)
  end

  def get_appointment!(id) do
    Appointment
    |> Repo.get!(id)
    |> Repo.preload([:trainer, :student])
  end

  def create_appointment(attrs \\ %{}) do
    %Appointment{}
    |> Appointment.changeset(attrs)
    |> Repo.insert()
  end

  def update_appointment(%Appointment{} = appointment, attrs) do
    appointment
    |> Appointment.changeset(attrs)
    |> Repo.update()
  end

  def delete_appointment(%Appointment{} = appointment) do
    Repo.delete(appointment)
  end

  def cancel_appointment(%Appointment{} = appointment, reason) do
    update_appointment(appointment, %{
      status: "cancelled",
      cancellation_reason: reason,
      cancelled_at: DateTime.utc_now()
    })
  end
end
