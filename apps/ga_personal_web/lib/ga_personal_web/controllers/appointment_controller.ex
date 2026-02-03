defmodule GaPersonalWeb.AppointmentController do
  use GaPersonalWeb, :controller

  alias GaPersonal.Schedule
  alias GaPersonal.Guardian

  action_fallback GaPersonalWeb.FallbackController

  def index(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    appointments = Schedule.list_appointments(user.id, params)
    json(conn, %{data: Enum.map(appointments, &appointment_json/1)})
  end

  def show(conn, %{"id" => id}) do
    appointment = Schedule.get_appointment!(id)
    json(conn, %{data: appointment_json(appointment)})
  end

  def create(conn, %{"appointment" => appointment_params}) do
    user = Guardian.Plug.current_resource(conn)
    params = Map.put(appointment_params, "trainer_id", user.id)

    with {:ok, appointment} <- Schedule.create_appointment(params) do
      conn
      |> put_status(:created)
      |> json(%{data: appointment_json(appointment)})
    end
  end

  def update(conn, %{"id" => id, "appointment" => appointment_params}) do
    appointment = Schedule.get_appointment!(id)

    with {:ok, updated} <- Schedule.update_appointment(appointment, appointment_params) do
      json(conn, %{data: appointment_json(updated)})
    end
  end

  def delete(conn, %{"id" => id}) do
    appointment = Schedule.get_appointment!(id)

    with {:ok, _} <- Schedule.delete_appointment(appointment) do
      send_resp(conn, :no_content, "")
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
