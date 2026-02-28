defmodule GaPersonal.Workers.VisualAnalysisWorker do
  @moduledoc """
  Oban worker for visual body analysis using Claude Sonnet.
  Analyzes evolution photos for posture, muscle development, and body composition.
  """
  use Oban.Worker, queue: :ai, max_attempts: 3

  require Logger

  alias GaPersonal.AIAnalysis
  alias GaPersonal.Media
  alias GaPersonal.GCS.Client, as: GCSClient
  alias GaPersonal.AI.Client, as: AIClient
  alias GaPersonal.Privacy

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"analysis_id" => analysis_id}}) do
    Logger.info("VisualAnalysisWorker: Starting analysis #{analysis_id}")

    with {:ok, record} <- AIAnalysis.get_analysis(analysis_id),
         {:ok, _} <- AIAnalysis.mark_processing(analysis_id),
         {:ok, media_file} <- Media.get_file(record.media_file_id),
         {:ok, download_url} <- GCSClient.generate_signed_download_url(media_file.gcs_path),
         {:ok, ai_result} <- run_analysis(download_url, media_file.content_type) do
      Privacy.log_access(
        record.trainer_id, "ai_analyze", "ai_analysis", analysis_id,
        %{metadata: %{model: ai_result.model, tokens: ai_result.tokens_used}}
      )

      case parse_result(ai_result.text) do
        {:ok, parsed} ->
          confidence = Map.get(parsed, "confidence", 0.7)
          AIAnalysis.save_result(
            analysis_id, parsed, confidence,
            ai_result.model, ai_result.tokens_used, ai_result.processing_time_ms
          )
          :ok

        {:error, reason} ->
          Logger.error("VisualAnalysisWorker: Parse failed for #{analysis_id}: #{inspect(reason)}")
          AIAnalysis.mark_failed(analysis_id)
          {:error, reason}
      end
    else
      {:error, reason} ->
        Logger.error("VisualAnalysisWorker: Failed for #{analysis_id}: #{inspect(reason)}")
        AIAnalysis.mark_failed(analysis_id)
        {:error, reason}
    end
  end

  def enqueue(analysis_id) do
    %{analysis_id: analysis_id}
    |> new()
    |> Oban.insert()
  end

  defp run_analysis(image_url, content_type) do
    prompt = """
    Analyze these fitness progress photos. Provide a professional assessment as JSON:
    {
      "muscle_development": {"observations": ["..."], "areas_of_progress": ["..."]},
      "posture_alignment": {"observations": ["..."], "concerns": ["..."]},
      "body_composition": {"visual_assessment": "...", "estimated_changes": "..."},
      "focus_areas": ["..."],
      "overall_notes": "...",
      "confidence": 0.0-1.0
    }
    Do NOT provide medical diagnoses. This is for a personal trainer's reference only.
    Return ONLY valid JSON, no markdown.
    """

    system = "You are a fitness assessment AI assistant helping a personal trainer. Provide objective, professional observations about visible physical characteristics. Never diagnose medical conditions."

    AIClient.analyze_image_url(image_url, content_type, prompt, model: :sonnet, system: system)
  end

  defp parse_result(text) do
    cleaned = text |> String.replace(~r/```json\s*/, "") |> String.replace(~r/```\s*/, "") |> String.trim()
    case Jason.decode(cleaned) do
      {:ok, data} when is_map(data) -> {:ok, data}
      _ -> {:error, :json_parse_failed}
    end
  end
end
