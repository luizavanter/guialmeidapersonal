defmodule GaPersonalWeb.BodyAssessmentController do
  use GaPersonalWeb, :controller

  alias GaPersonal.Evolution
  alias GaPersonal.Accounts
  import GaPersonalWeb.Helpers.StudentResolver, only: [resolve_and_verify_student: 2]

  action_fallback GaPersonalWeb.FallbackController

  # Trainer actions - manage assessments for their students
  def index(conn, %{"student_id" => student_id}) do
    trainer_id = conn.assigns.current_user_id

    case resolve_and_verify_student(student_id, trainer_id) do
      {:ok, user_id} ->
        assessments = Evolution.list_body_assessments(user_id)
        json(conn, %{data: Enum.map(assessments, &body_assessment_json/1)})

      {:error, reason} ->
        {:error, reason}
    end
  end

  def index(conn, _params) do
    {:error, :bad_request, "student_id is required"}
  end

  def show(conn, %{"id" => id}) do
    trainer_id = conn.assigns.current_user_id

    case Evolution.get_body_assessment_for_trainer(id, trainer_id) do
      {:ok, assessment} ->
        json(conn, %{data: body_assessment_json(assessment)})

      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :unauthorized} ->
        {:error, :forbidden}
    end
  end

  def create(conn, %{"body_assessment" => assessment_params}) do
    trainer_id = conn.assigns.current_user_id
    student_id = Map.get(assessment_params, "student_id")

    case resolve_and_verify_student(student_id, trainer_id) do
      {:ok, user_id} ->
        params = assessment_params
        |> Map.put("student_id", user_id)
        |> Map.put("trainer_id", trainer_id)

        with {:ok, assessment} <- Evolution.create_body_assessment(params) do
          conn
          |> put_status(:created)
          |> json(%{data: body_assessment_json(assessment)})
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  def update(conn, %{"id" => id, "body_assessment" => assessment_params}) do
    trainer_id = conn.assigns.current_user_id

    case Evolution.get_body_assessment_for_trainer(id, trainer_id) do
      {:ok, assessment} ->
        with {:ok, updated} <- Evolution.update_body_assessment(assessment, assessment_params) do
          json(conn, %{data: body_assessment_json(updated)})
        end

      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :unauthorized} ->
        {:error, :forbidden}
    end
  end

  def delete(conn, %{"id" => id}) do
    trainer_id = conn.assigns.current_user_id

    case Evolution.get_body_assessment_for_trainer(id, trainer_id) do
      {:ok, assessment} ->
        with {:ok, _} <- Evolution.delete_body_assessment(assessment) do
          send_resp(conn, :no_content, "")
        end

      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :unauthorized} ->
        {:error, :forbidden}
    end
  end

  # Student actions (read-only)
  def index_for_student(conn, _params) do
    user = conn.assigns.current_user

    assessments = Evolution.list_body_assessments(user.id)
    json(conn, %{data: Enum.map(assessments, &body_assessment_json/1)})
  end

  def show_for_student(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    case Evolution.get_body_assessment_for_student(id, user.id) do
      {:ok, assessment} ->
        json(conn, %{data: body_assessment_json(assessment)})

      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :unauthorized} ->
        {:error, :forbidden}
    end
  end

  defp body_assessment_json(assessment) do
    %{
      id: assessment.id,
      student_id: assessment.student_id,
      trainer_id: assessment.trainer_id,
      assessment_date: assessment.assessment_date,
      weight_kg: assessment.weight_kg,
      height_cm: assessment.height_cm,
      body_fat_percentage: assessment.body_fat_percentage,
      muscle_mass_kg: assessment.muscle_mass_kg,
      chest_cm: assessment.chest_cm,
      waist_cm: assessment.waist_cm,
      hips_cm: assessment.hips_cm,
      left_arm_cm: assessment.left_arm_cm,
      right_arm_cm: assessment.right_arm_cm,
      left_thigh_cm: assessment.left_thigh_cm,
      right_thigh_cm: assessment.right_thigh_cm,
      notes: assessment.notes,
      evolution_photos: photos_json(assessment)
    }
  end

  defp photos_json(%{evolution_photos: photos}) when is_list(photos) do
    Enum.map(photos, fn photo ->
      %{
        id: photo.id,
        photo_url: photo.photo_url,
        photo_type: photo.photo_type,
        taken_at: photo.taken_at
      }
    end)
  end

  defp photos_json(_), do: []
end
