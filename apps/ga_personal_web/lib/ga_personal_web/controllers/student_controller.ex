defmodule GaPersonalWeb.StudentController do
  use GaPersonalWeb, :controller

  alias GaPersonal.Accounts

  action_fallback GaPersonalWeb.FallbackController

  def index(conn, params) do
    trainer_id = conn.assigns.current_user_id
    students = Accounts.list_students(trainer_id, params)

    json(conn, %{data: Enum.map(students, &student_json/1)})
  end

  def show(conn, %{"id" => id}) do
    trainer_id = conn.assigns.current_user_id

    case Accounts.get_student_for_trainer(id, trainer_id) do
      {:ok, student} ->
        json(conn, %{data: student_json(student)})

      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :unauthorized} ->
        {:error, :forbidden}
    end
  end

  def create(conn, %{"student" => student_params}) do
    trainer_id = conn.assigns.current_user_id

    with {:ok, student} <- Accounts.create_student(trainer_id, student_params) do
      conn
      |> put_status(:created)
      |> json(%{data: student_json(student)})
    end
  end

  def update(conn, %{"id" => id, "student" => student_params}) do
    trainer_id = conn.assigns.current_user_id

    case Accounts.get_student_for_trainer(id, trainer_id) do
      {:ok, student} ->
        with {:ok, updated_student} <- Accounts.update_student_profile(student, student_params) do
          json(conn, %{data: student_json(updated_student)})
        end

      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :unauthorized} ->
        {:error, :forbidden}
    end
  end

  def delete(conn, %{"id" => id}) do
    trainer_id = conn.assigns.current_user_id

    case Accounts.get_student_for_trainer(id, trainer_id) do
      {:ok, student} ->
        with {:ok, _} <- Accounts.deactivate_student(student) do
          send_resp(conn, :no_content, "")
        end

      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :unauthorized} ->
        {:error, :forbidden}
    end
  end

  defp student_json(student) do
    %{
      id: student.id,
      user_id: student.user_id,
      trainer_id: student.trainer_id,
      date_of_birth: student.date_of_birth,
      gender: student.gender,
      emergency_contact_name: student.emergency_contact_name,
      emergency_contact_phone: student.emergency_contact_phone,
      medical_conditions: student.medical_conditions,
      goals_description: student.goals_description,
      notes: student.notes,
      status: student.status,
      user: if(student.user, do: user_json(student.user), else: nil)
    }
  end

  defp user_json(user) do
    %{
      id: user.id,
      email: user.email,
      full_name: user.full_name,
      phone: user.phone
    }
  end
end
