defmodule GaPersonalWeb.AIAnalysisController do
  use GaPersonalWeb, :controller

  alias GaPersonal.AIAnalysis
  alias GaPersonal.Privacy

  action_fallback GaPersonalWeb.FallbackController

  @doc "POST /api/v1/ai/analyze/visual"
  def analyze_visual(conn, %{"analysis" => %{"media_file_id" => media_file_id, "student_id" => student_id}}) do
    trainer_id = conn.assigns.current_user_id

    case AIAnalysis.request_visual_analysis(media_file_id, student_id, trainer_id) do
      {:ok, record} ->
        Privacy.log_access(trainer_id, "ai_analyze", "ai_analysis", record.id, conn_info(conn))
        conn |> put_status(:created) |> json(%{data: analysis_json(record)})

      {:error, :rate_limited} ->
        conn |> put_status(:too_many_requests) |> json(%{error: "Rate limit exceeded. Max 10 analyses per hour."})

      {:error, %Ecto.Changeset{} = changeset} -> {:error, changeset}
    end
  end

  @doc "POST /api/v1/ai/analyze/trends"
  def analyze_trends(conn, %{"analysis" => %{"student_id" => student_id}} = params) do
    trainer_id = conn.assigns.current_user_id
    opts = Map.get(params["analysis"], "options", %{})

    case AIAnalysis.request_trends_analysis(student_id, trainer_id, opts) do
      {:ok, record} ->
        Privacy.log_access(trainer_id, "ai_analyze", "ai_analysis", record.id, conn_info(conn))
        conn |> put_status(:created) |> json(%{data: analysis_json(record)})

      {:error, :rate_limited} ->
        conn |> put_status(:too_many_requests) |> json(%{error: "Rate limit exceeded. Max 10 analyses per hour."})

      {:error, %Ecto.Changeset{} = changeset} -> {:error, changeset}
    end
  end

  @doc "POST /api/v1/ai/analyze/document"
  def analyze_document(conn, %{"analysis" => %{"media_file_id" => media_file_id, "student_id" => student_id}}) do
    trainer_id = conn.assigns.current_user_id

    case AIAnalysis.request_document_analysis(media_file_id, student_id, trainer_id) do
      {:ok, record} ->
        Privacy.log_access(trainer_id, "ai_analyze", "ai_analysis", record.id, conn_info(conn))
        conn |> put_status(:created) |> json(%{data: analysis_json(record)})

      {:error, :rate_limited} ->
        conn |> put_status(:too_many_requests) |> json(%{error: "Rate limit exceeded. Max 10 analyses per hour."})

      {:error, %Ecto.Changeset{} = changeset} -> {:error, changeset}
    end
  end

  @doc "GET /api/v1/ai/analyses"
  def index(conn, params) do
    trainer_id = conn.assigns.current_user_id
    filters = Map.take(params, ["analysis_type", "status", "student_id"])
    analyses = AIAnalysis.list_analyses(trainer_id, filters)
    json(conn, %{data: Enum.map(analyses, &analysis_json/1)})
  end

  @doc "GET /api/v1/ai/analyses/:id"
  def show(conn, %{"id" => id}) do
    trainer_id = conn.assigns.current_user_id

    case AIAnalysis.get_analysis_for_trainer(id, trainer_id) do
      {:ok, record} -> json(conn, %{data: analysis_json(record)})
      {:error, :not_found} -> {:error, :not_found}
      {:error, :unauthorized} -> {:error, :forbidden}
    end
  end

  @doc "PUT /api/v1/ai/analyses/:id/review"
  def review(conn, %{"id" => id, "review" => %{"text" => review_text}}) do
    trainer_id = conn.assigns.current_user_id

    case AIAnalysis.review(id, trainer_id, review_text) do
      {:ok, record} -> json(conn, %{data: analysis_json(record)})
      {:error, :not_found} -> {:error, :not_found}
      {:error, :unauthorized} -> {:error, :forbidden}
      {:error, :bad_request, msg} -> {:error, :bad_request, msg}
    end
  end

  @doc "POST /api/v1/ai/analyses/:id/share"
  def share(conn, %{"id" => id}) do
    trainer_id = conn.assigns.current_user_id

    case AIAnalysis.share_with_student(id, trainer_id) do
      {:ok, record} -> json(conn, %{data: analysis_json(record), message: "Analysis shared with student"})
      {:error, :not_found} -> {:error, :not_found}
      {:error, :unauthorized} -> {:error, :forbidden}
      {:error, :bad_request, msg} -> {:error, :bad_request, msg}
    end
  end

  @doc "GET /api/v1/ai/usage"
  def usage(conn, _params) do
    trainer_id = conn.assigns.current_user_id
    stats = AIAnalysis.usage_stats(trainer_id)
    json(conn, %{data: stats})
  end

  @doc "GET /api/v1/student/ai/analyses (student-visible analyses)"
  def index_for_student(conn, params) do
    user = conn.assigns.current_user
    filters = Map.take(params, ["analysis_type"])
    analyses = AIAnalysis.list_analyses_for_student(user.id, filters)
    json(conn, %{data: Enum.map(analyses, &analysis_json/1)})
  end

  @doc "GET /api/v1/student/ai/analyses/:id"
  def show_for_student(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    case AIAnalysis.get_analysis_for_student(id, user.id) do
      {:ok, record} -> json(conn, %{data: analysis_json(record)})
      {:error, :not_found} -> {:error, :not_found}
      {:error, :unauthorized} -> {:error, :forbidden}
    end
  end

  defp analysis_json(record) do
    %{
      id: record.id,
      analysis_type: record.analysis_type,
      status: record.status,
      model_used: record.model_used,
      input_data: record.input_data,
      result: record.result,
      confidence_score: record.confidence_score,
      trainer_review: record.trainer_review,
      reviewed_at: record.reviewed_at,
      visible_to_student: record.visible_to_student,
      tokens_used: record.tokens_used,
      processing_time_ms: record.processing_time_ms,
      student_id: record.student_id,
      trainer_id: record.trainer_id,
      media_file_id: record.media_file_id,
      inserted_at: record.inserted_at,
      updated_at: record.updated_at
    }
  end

  defp conn_info(conn) do
    %{
      ip_address: conn.remote_ip |> :inet.ntoa() |> to_string(),
      user_agent: Plug.Conn.get_req_header(conn, "user-agent") |> List.first()
    }
  end
end
