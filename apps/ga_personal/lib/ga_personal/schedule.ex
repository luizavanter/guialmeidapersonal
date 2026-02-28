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

  @doc """
  Gets a time slot with ownership verification.
  """
  def get_time_slot_for_trainer(id, trainer_id) do
    case Repo.get(TimeSlot, id) do
      nil -> {:error, :not_found}
      %TimeSlot{trainer_id: ^trainer_id} = slot -> {:ok, slot}
      %TimeSlot{} -> {:error, :unauthorized}
    end
  end

  def get_time_slot_for_trainer!(id, trainer_id) do
    slot = get_time_slot!(id)
    if slot.trainer_id == trainer_id, do: slot, else: raise(Ecto.NoResultsError, queryable: TimeSlot)
  end

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

  @doc """
  Gets an appointment with ownership verification.
  Returns {:ok, appointment} if the appointment belongs to the trainer,
  {:error, :not_found} if appointment doesn't exist,
  or {:error, :unauthorized} if appointment belongs to another trainer.
  """
  def get_appointment_for_trainer(id, trainer_id) do
    case get_appointment!(id) do
      nil ->
        {:error, :not_found}

      %Appointment{trainer_id: ^trainer_id} = appointment ->
        {:ok, appointment}

      %Appointment{} ->
        {:error, :unauthorized}
    end
  rescue
    Ecto.NoResultsError -> {:error, :not_found}
  end

  def get_appointment_for_trainer!(id, trainer_id) do
    appointment = get_appointment!(id)
    if appointment.trainer_id == trainer_id, do: appointment, else: raise(Ecto.NoResultsError, queryable: Appointment)
  end

  @doc """
  Gets an appointment for a student (read-only access).
  """
  def get_appointment_for_student(id, student_id) do
    case get_appointment!(id) do
      nil ->
        {:error, :not_found}

      %Appointment{student_id: ^student_id} = appointment ->
        {:ok, appointment}

      %Appointment{} ->
        {:error, :unauthorized}
    end
  rescue
    Ecto.NoResultsError -> {:error, :not_found}
  end

  @doc """
  Lists appointments for a specific student.
  """
  def list_appointments_for_student(student_id, filters \\ %{}) do
    query = from a in Appointment,
      where: a.student_id == ^student_id,
      preload: [:trainer],
      order_by: [desc: a.scheduled_at]

    query
    |> apply_appointment_filters(filters)
    |> Repo.all()
  end

  def create_appointment(attrs \\ %{}) do
    result =
      %Appointment{}
      |> Appointment.changeset(attrs)
      |> Repo.insert()

    case result do
      {:ok, appointment} ->
        if appointment.student_id do
          GaPersonal.NotificationService.on_appointment_created(appointment, appointment.student_id)
        end
        {:ok, appointment}

      error ->
        error
    end
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
    result = update_appointment(appointment, %{
      status: "cancelled",
      cancellation_reason: reason,
      cancelled_at: DateTime.utc_now()
    })

    case result do
      {:ok, cancelled} ->
        if cancelled.student_id do
          GaPersonal.NotificationService.on_appointment_cancelled(cancelled, cancelled.student_id, reason)
        end
        {:ok, cancelled}

      error ->
        error
    end
  end

  @doc """
  Find an appointment by searching for text in the notes field.
  Used for Cal.com integration to find appointments by their Cal.com UID.
  """
  def find_appointment_by_notes_containing(text) when is_binary(text) do
    from(a in Appointment,
      where: ilike(a.notes, ^"%#{text}%"),
      limit: 1
    )
    |> Repo.one()
  end
end
