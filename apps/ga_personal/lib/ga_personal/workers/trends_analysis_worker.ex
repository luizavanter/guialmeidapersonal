defmodule GaPersonal.Workers.TrendsAnalysisWorker do
  @moduledoc """
  Oban worker for numeric trends analysis using Claude Haiku.
  Analyzes body assessment history for trends, alerts, and recommendations.
  """
  use Oban.Worker, queue: :ai, max_attempts: 3

  require Logger

  alias GaPersonal.AIAnalysis
  alias GaPersonal.Evolution
  alias GaPersonal.AI.Client, as: AIClient
  alias GaPersonal.Privacy

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"analysis_id" => analysis_id}}) do
    Logger.info("TrendsAnalysisWorker: Starting analysis #{analysis_id}")

    with {:ok, record} <- AIAnalysis.get_analysis(analysis_id),
         {:ok, _} <- AIAnalysis.mark_processing(analysis_id),
         assessments <- Evolution.list_body_assessments(record.student_id),
         :ok <- validate_assessments(assessments),
         {:ok, ai_result} <- run_analysis(assessments) do
      Privacy.log_access(
        record.trainer_id, "ai_analyze", "ai_analysis", analysis_id,
        %{metadata: %{model: ai_result.model, tokens: ai_result.tokens_used}}
      )

      case parse_result(ai_result.text) do
        {:ok, parsed} ->
          confidence = Map.get(parsed, "confidence", 0.8)
          AIAnalysis.save_result(
            analysis_id, parsed, confidence,
            ai_result.model, ai_result.tokens_used, ai_result.processing_time_ms
          )
          :ok

        {:error, reason} ->
          Logger.error("TrendsAnalysisWorker: Parse failed for #{analysis_id}: #{inspect(reason)}")
          AIAnalysis.mark_failed(analysis_id)
          {:error, reason}
      end
    else
      {:error, reason} ->
        Logger.error("TrendsAnalysisWorker: Failed for #{analysis_id}: #{inspect(reason)}")
        AIAnalysis.mark_failed(analysis_id)
        {:error, reason}
    end
  end

  def enqueue(analysis_id) do
    %{analysis_id: analysis_id}
    |> new()
    |> Oban.insert()
  end

  defp validate_assessments(assessments) do
    if length(assessments) >= 2 do
      :ok
    else
      {:error, :insufficient_data}
    end
  end

  defp run_analysis(assessments) do
    assessment_data = Enum.map(assessments, fn a ->
      %{
        date: a.assessment_date,
        weight_kg: a.weight_kg,
        body_fat_percentage: a.body_fat_percentage,
        muscle_mass_kg: a.muscle_mass_kg,
        bmi: a.bmi,
        waist_cm: a.waist_cm,
        chest_cm: a.chest_cm
      }
    end)

    prompt = """
    Analyze this body composition data series for a fitness client:
    #{Jason.encode!(assessment_data)}

    Provide analysis as JSON:
    {
      "trends": {
        "weight": {"direction": "improving|stable|declining", "details": "..."},
        "body_fat": {"direction": "improving|stable|declining", "details": "..."},
        "muscle_mass": {"direction": "improving|stable|declining", "details": "..."}
      },
      "alerts": ["..."],
      "plateaus": ["..."],
      "recommendations": ["..."],
      "overall_assessment": "...",
      "confidence": 0.0-1.0
    }
    Return ONLY valid JSON, no markdown.
    """

    system = "You are a fitness data analyst. Analyze body composition trends objectively. Flag concerning patterns but do not provide medical advice."

    AIClient.chat(prompt, model: :haiku, system: system)
  end

  defp parse_result(text) do
    cleaned = text |> String.replace(~r/```json\s*/, "") |> String.replace(~r/```\s*/, "") |> String.trim()
    case Jason.decode(cleaned) do
      {:ok, data} when is_map(data) -> {:ok, data}
      _ -> {:error, :json_parse_failed}
    end
  end
end
