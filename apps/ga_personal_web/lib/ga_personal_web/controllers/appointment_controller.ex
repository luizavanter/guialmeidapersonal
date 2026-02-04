defmodule GaPersonalWeb.AppointmentController do
  use GaPersonalWeb, :controller

  alias GaPersonal.Schedule
  alias GaPersonal.Accounts

  action_fallback GaPersonalWeb.FallbackController

  # Trainer actions
  def index(conn, params) do
    trainer_id = conn.assigns.current_user_id
    appointments = Schedule.list_appointments(trainer_id, params)
    json(conn, %{data: Enum.map(appointments, &appointment_json/1)})
  end

  def show(conn, %{"id" => id}) do
    trainer_id = conn.assigns.current_user_id

    case Schedule.get_appointment_for_trainer(id, trainer_id) do
      {:ok, appointment} ->
        json(conn, %{data: appointment_json(appointment)})

      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :unauthorized} ->
        {:error, :forbidden}
    end
  end

  def create(conn, %{"appointment" => appointment_params}) do
    trainer_id = conn.assigns.current_user_id
    params = Map.put(appointment_params, "trainer_id", trainer_id)

    with {:ok, appointment} <- Schedule.create_appointment(params) do
      conn
      |> put_status(:created)
      |> json(%{data: appointment_json(appointment)})
    end
  end

  def update(conn, %{"id" => id, "appointment" => appointment_params}) do
    trainer_id = conn.assigns.current_user_id

    case Schedule.get_appointment_for_trainer(id, trainer_id) do
      {:ok, appointment} ->
        with {:ok, updated} <- Schedule.update_appointment(appointment, appointment_params) do
          json(conn, %{data: appointment_json(updated)})
        end

      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :unauthorized} ->
        {:error, :forbidden}
    end
  end

  def delete(conn, %{"id" => id}) do
    trainer_id = conn.assigns.current_user_id

    case Schedule.get_appointment_for_trainer(id, trainer_id) do
      {:ok, appointment} ->
        with {:ok, _} <- Schedule.delete_appointment(appointment) do
          send_resp(conn, :no_content, "")
        end

      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :unauthorized} ->
        {:error, :forbidden}
    end
  end

  # Student actions (read-only)
  def index_for_student(conn, params) do
    user = conn.assigns.current_user

    case Accounts.get_student_by_user_id(user.id) do
      nil ->
        {:error, :not_found}

      student ->
        appointments = Schedule.list_appointments_for_student(student.id, params)
        json(conn, %{data: Enum.map(appointments, &appointment_json/1)})
    end
  end

  def show_for_student(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    case Accounts.get_student_by_user_id(user.id) do
      nil ->
        {:error, :not_found}

      student ->
        case Schedule.get_appointment_for_student(id, student.id) do
          {:ok, appointment} ->
            json(conn, %{data: appointment_json(appointment)})

          {:error, :not_found} ->
            {:error, :not_found}

          {:error, :unauthorized} ->
            {:error, :forbidden}
        end
    end
  end

  defp appointment_json(appointment) do
    %{
      id: appointment.id,
      trainer_id: appointment.trainer_id,
      student_id: appointment.student_id,
      scheduled_at: appointment.scheduled_at,
      duration_minutes: appointment.duration_minutes,
      status: appointment.status,
      appointment_type: appointment.appointment_type,
      location: appointment.location,
      notes: appointment.notes
    }
  end
end
