defmodule GaPersonalWeb.BodyAssessmentController do
  use GaPersonalWeb, :controller

  alias GaPersonal.Evolution
  alias GaPersonal.Guardian

  action_fallback GaPersonalWeb.FallbackController

  def index(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    student_id = Map.get(params, "student_id", user.id)
    assessments = Evolution.list_body_assessments(student_id)
    json(conn, %{data: Enum.map(assessments, &body_assessment_json/1)})
  end

  def show(conn, %{"id" => id}) do
    assessment = Evolution.get_body_assessment!(id)
    json(conn, %{data: body_assessment_json(assessment)})
  end

  def create(conn, %{"body_assessment" => assessment_params}) do
    user = Guardian.Plug.current_resource(conn)
    params = Map.put(assessment_params, "assessor_id", user.id)

    with {:ok, assessment} <- Evolution.create_body_assessment(params) do
      conn
      |> put_status(:created)
      |> json(%{data: body_assessment_json(assessment)})
    end
  end

  def update(conn, %{"id" => id, "body_assessment" => assessment_params}) do
    assessment = Evolution.get_body_assessment!(id)

    with {:ok, updated} <- Evolution.update_body_assessment(assessment, assessment_params) do
      json(conn, %{data: body_assessment_json(updated)})
    end
  end

  def delete(conn, %{"id" => id}) do
    assessment = Evolution.get_body_assessment!(id)

    with {:ok, _} <- Evolution.delete_body_assessment(assessment) do
      send_resp(conn, :no_content, "")
    end
  end

  defp body_assessment_json(assessment) do
    %{
      id: assessment.id,
      student_id: assessment.student_id,
      assessor_id: assessment.assessor_id,
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
