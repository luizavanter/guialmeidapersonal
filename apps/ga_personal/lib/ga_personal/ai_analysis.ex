defmodule GaPersonal.AIAnalysis do
  @moduledoc """
  The AI Analysis context - handles AI-powered analysis of evolution photos,
  body composition trends, and medical documents using Claude API.
  """

  import Ecto.Query, warn: false
  alias GaPersonal.Repo
  alias GaPersonal.AIAnalysis.AIAnalysisRecord

  @rate_limit_per_hour 10

  ## Analysis requests

  def request_visual_analysis(media_file_id, student_id, trainer_id) do
    with :ok <- check_rate_limit(trainer_id) do
      create_and_enqueue("visual_body", %{
        student_id: student_id,
        trainer_id: trainer_id,
        media_file_id: media_file_id
      }, GaPersonal.Workers.VisualAnalysisWorker)
    end
  end

  def request_trends_analysis(student_id, trainer_id, opts \\ %{}) do
    with :ok <- check_rate_limit(trainer_id) do
      create_and_enqueue("numeric_trends", %{
        student_id: student_id,
        trainer_id: trainer_id,
        input_data: opts
      }, GaPersonal.Workers.TrendsAnalysisWorker)
    end
  end

  def request_document_analysis(media_file_id, student_id, trainer_id) do
    with :ok <- check_rate_limit(trainer_id) do
      create_and_enqueue("medical_document", %{
        student_id: student_id,
        trainer_id: trainer_id,
        media_file_id: media_file_id
      }, GaPersonal.Workers.DocumentAnalysisWorker)
    end
  end

  ## Result saving (called by workers)

  def save_result(analysis_id, result, confidence, model, tokens, time_ms) do
    case get_analysis(analysis_id) do
      {:ok, record} ->
        record
        |> AIAnalysisRecord.result_changeset(%{
          status: "completed",
          result: result,
          confidence_score: confidence,
          model_used: model,
          tokens_used: tokens,
          processing_time_ms: time_ms
        })
        |> Repo.update()

      error ->
        error
    end
  end

  def mark_failed(analysis_id) do
    case get_analysis(analysis_id) do
      {:ok, record} ->
        record
        |> Ecto.Changeset.change(%{status: "failed"})
        |> Repo.update()

      error ->
        error
    end
  end

  def mark_processing(analysis_id) do
    case get_analysis(analysis_id) do
      {:ok, record} ->
        record
        |> Ecto.Changeset.change(%{status: "processing"})
        |> Repo.update()

      error ->
        error
    end
  end

  ## Trainer actions

  def review(analysis_id, trainer_id, review_text) do
    with {:ok, record} <- get_analysis_for_trainer(analysis_id, trainer_id),
         :ok <- validate_completed(record) do
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      record
      |> AIAnalysisRecord.review_changeset(%{
        trainer_review: review_text,
        reviewed_at: now
      })
      |> Repo.update()
    end
  end

  def share_with_student(analysis_id, trainer_id) do
    with {:ok, record} <- get_analysis_for_trainer(analysis_id, trainer_id),
         :ok <- validate_reviewed_or_completed(record) do
      record
      |> Ecto.Changeset.change(%{visible_to_student: true})
      |> Repo.update()
    end
  end

  ## Queries

  def list_analyses(trainer_id, filters \\ %{}) do
    from(a in AIAnalysisRecord,
      where: a.trainer_id == ^trainer_id,
      order_by: [desc: a.inserted_at]
    )
    |> apply_filters(filters)
    |> Repo.all()
  end

  def list_analyses_for_student(student_id, filters \\ %{}) do
    from(a in AIAnalysisRecord,
      where: a.student_id == ^student_id and a.visible_to_student == true,
      order_by: [desc: a.inserted_at]
    )
    |> apply_filters(filters)
    |> Repo.all()
  end

  def get_analysis(id) do
    case Repo.get(AIAnalysisRecord, id) do
      nil -> {:error, :not_found}
      record -> {:ok, record}
    end
  end

  def get_analysis_for_trainer(id, trainer_id) do
    case Repo.get(AIAnalysisRecord, id) do
      nil -> {:error, :not_found}
      %AIAnalysisRecord{trainer_id: ^trainer_id} = record -> {:ok, record}
      %AIAnalysisRecord{} -> {:error, :unauthorized}
    end
  end

  def get_analysis_for_student(id, student_id) do
    case Repo.get(AIAnalysisRecord, id) do
      nil -> {:error, :not_found}
      %AIAnalysisRecord{student_id: ^student_id, visible_to_student: true} = record -> {:ok, record}
      %AIAnalysisRecord{} -> {:error, :unauthorized}
    end
  end

  def usage_stats(trainer_id) do
    now = DateTime.utc_now()
    one_hour_ago = DateTime.add(now, -3600, :second)
    thirty_days_ago = DateTime.add(now, -30, :day)

    analyses_this_hour =
      from(a in AIAnalysisRecord,
        where: a.trainer_id == ^trainer_id and a.inserted_at >= ^one_hour_ago,
        select: count(a.id)
      )
      |> Repo.one()

    monthly_stats =
      from(a in AIAnalysisRecord,
        where: a.trainer_id == ^trainer_id and a.inserted_at >= ^thirty_days_ago,
        select: %{
          total_analyses: count(a.id),
          total_tokens: sum(a.tokens_used),
          avg_processing_ms: avg(a.processing_time_ms)
        }
      )
      |> Repo.one()

    %{
      rate_limit: %{used: analyses_this_hour, limit: @rate_limit_per_hour},
      monthly: monthly_stats
    }
  end

  ## Private helpers

  defp create_and_enqueue(analysis_type, attrs, worker_module) do
    record_attrs = %{
      analysis_type: analysis_type,
      status: "queued",
      student_id: attrs.student_id,
      trainer_id: attrs.trainer_id,
      media_file_id: Map.get(attrs, :media_file_id),
      input_data: Map.get(attrs, :input_data, %{})
    }

    case create_analysis(record_attrs) do
      {:ok, record} ->
        worker_module.enqueue(record.id)
        {:ok, record}

      error ->
        error
    end
  end

  defp create_analysis(attrs) do
    %AIAnalysisRecord{}
    |> AIAnalysisRecord.changeset(attrs)
    |> Repo.insert()
  end

  defp check_rate_limit(trainer_id) do
    one_hour_ago =
      DateTime.utc_now()
      |> DateTime.add(-3600, :second)

    count =
      from(a in AIAnalysisRecord,
        where: a.trainer_id == ^trainer_id and a.inserted_at >= ^one_hour_ago,
        select: count(a.id)
      )
      |> Repo.one()

    if count < @rate_limit_per_hour do
      :ok
    else
      {:error, :rate_limited}
    end
  end

  defp validate_completed(record) do
    if record.status in ["completed", "reviewed"] do
      :ok
    else
      {:error, :bad_request, "Analysis must be completed before review"}
    end
  end

  defp validate_reviewed_or_completed(record) do
    if record.status in ["completed", "reviewed"] do
      :ok
    else
      {:error, :bad_request, "Analysis must be completed or reviewed before sharing"}
    end
  end

  defp apply_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {"analysis_type", type}, query ->
        from a in query, where: a.analysis_type == ^type

      {"status", status}, query ->
        from a in query, where: a.status == ^status

      {"student_id", student_id}, query ->
        from a in query, where: a.student_id == ^student_id

      _, query ->
        query
    end)
  end
end
