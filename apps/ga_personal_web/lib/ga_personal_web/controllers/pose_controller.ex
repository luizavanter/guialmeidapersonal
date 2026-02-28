defmodule GaPersonalWeb.PoseController do
  use GaPersonalWeb, :controller

  alias GaPersonal.Pose
  alias GaPersonal.Accounts

  action_fallback GaPersonalWeb.FallbackController

  @doc "POST /api/v1/pose/results — Student saves pose analysis results"
  def create(conn, %{"pose" => pose_params}) do
    user = conn.assigns.current_user
    trainer_id = resolve_trainer_id(user)

    params = pose_params
    |> Map.put("student_id", user.id)
    |> Map.put("trainer_id", trainer_id)

    case Pose.create_result(params) do
      {:ok, result} ->
        conn |> put_status(:created) |> json(%{data: pose_json(result)})

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, changeset}
    end
  end

  @doc "GET /api/v1/pose/results — Trainer lists pose results"
  def index(conn, params) do
    trainer_id = conn.assigns.current_user_id
    filters = Map.take(params, ["analysis_type", "exercise_name", "student_id"])
    results = Pose.list_results_for_trainer(trainer_id, filters)
    json(conn, %{data: Enum.map(results, &pose_json/1)})
  end

  @doc "GET /api/v1/pose/results/:id"
  def show(conn, %{"id" => id}) do
    trainer_id = conn.assigns.current_user_id

    case Pose.get_result_for_trainer(id, trainer_id) do
      {:ok, result} -> json(conn, %{data: pose_json(result)})
      {:error, :not_found} -> {:error, :not_found}
      {:error, :unauthorized} -> {:error, :forbidden}
    end
  end

  @doc "GET /api/v1/students/:student_id/pose — Student's pose history"
  def student_history(conn, %{"student_id" => student_id} = params) do
    _trainer_id = conn.assigns.current_user_id
    filters = Map.take(params, ["analysis_type", "exercise_name"])
    results = Pose.list_results(student_id, filters)
    json(conn, %{data: Enum.map(results, &pose_json/1)})
  end

  @doc "GET /api/v1/student/pose/results — Student's own results"
  def my_results(conn, params) do
    user = conn.assigns.current_user
    filters = Map.take(params, ["analysis_type", "exercise_name"])
    results = Pose.list_results(user.id, filters)
    json(conn, %{data: Enum.map(results, &pose_json/1)})
  end

  @doc "GET /api/v1/student/pose/results/:id"
  def show_for_student(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    case Pose.get_result_for_student(id, user.id) do
      {:ok, result} -> json(conn, %{data: pose_json(result)})
      {:error, :not_found} -> {:error, :not_found}
      {:error, :unauthorized} -> {:error, :forbidden}
    end
  end

  defp pose_json(result) do
    %{
      id: result.id,
      analysis_type: result.analysis_type,
      exercise_name: result.exercise_name,
      keypoints_data: result.keypoints_data,
      scores: result.scores,
      feedback: result.feedback,
      overall_score: result.overall_score,
      student_id: result.student_id,
      trainer_id: result.trainer_id,
      inserted_at: result.inserted_at
    }
  end

  defp resolve_trainer_id(%{role: role} = user) when role in [:trainer, :admin, "trainer", "admin"], do: user.id
  defp resolve_trainer_id(user) do
    case Accounts.get_student_by_user_id(user.id) do
      nil -> user.id
      student -> student.trainer_id
    end
  end
end
