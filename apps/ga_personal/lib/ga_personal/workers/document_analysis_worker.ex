defmodule GaPersonal.Workers.DocumentAnalysisWorker do
  @moduledoc """
  Oban worker for medical document analysis using Claude.
  Step 1 (Haiku): Extract values. Step 2 (Sonnet): Fitness-relevant analysis.
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
    Logger.info("DocumentAnalysisWorker: Starting analysis #{analysis_id}")

    with {:ok, record} <- AIAnalysis.get_analysis(analysis_id),
         {:ok, _} <- AIAnalysis.mark_processing(analysis_id),
         {:ok, media_file} <- Media.get_file(record.media_file_id),
         {:ok, download_url} <- GCSClient.generate_signed_download_url(media_file.gcs_path),
         {:ok, extraction} <- step1_extract(download_url, media_file.content_type),
         {:ok, analysis} <- step2_analyze(extraction) do
      Privacy.log_access(
        record.trainer_id, "ai_analyze", "ai_analysis", analysis_id,
        %{metadata: %{tokens: extraction.tokens_used + analysis.tokens_used}}
      )

      total_tokens = extraction.tokens_used + analysis.tokens_used
      total_time = extraction.processing_time_ms + analysis.processing_time_ms

      case parse_result(analysis.text, extraction.text) do
        {:ok, combined} ->
          confidence = Map.get(combined, "confidence", 0.7)
          AIAnalysis.save_result(
            analysis_id, combined, confidence,
            "haiku+sonnet", total_tokens, total_time
          )
          :ok

        {:error, reason} ->
          Logger.error("DocumentAnalysisWorker: Parse failed for #{analysis_id}: #{inspect(reason)}")
          AIAnalysis.mark_failed(analysis_id, reason)
          {:error, reason}
      end
    else
      {:error, reason} ->
        Logger.error("DocumentAnalysisWorker: Failed for #{analysis_id}: #{inspect(reason)}")
        AIAnalysis.mark_failed(analysis_id, reason)
        {:error, reason}
    end
  end

  def enqueue(analysis_id) do
    %{analysis_id: analysis_id}
    |> new()
    |> Oban.insert()
  end

  defp step1_extract(download_url, content_type) do
    prompt = """
    Extraia TODOS os valores numéricos, nomes de exames e faixas de referência deste documento médico.
    IMPORTANTE: Responda em português brasileiro.
    Retorne como JSON:
    {
      "document_type": "blood_work|medical_clearance|bioimpedance|other",
      "date": "YYYY-MM-DD ou null",
      "values": [
        {"name": "...", "value": ..., "unit": "...", "reference_range": "...", "status": "normal|high|low|critical"}
      ],
      "notes": "..."
    }
    Retorne APENAS JSON válido, sem markdown.
    """

    AIClient.analyze_image_url(download_url, content_type, prompt, model: :haiku)
  end

  defp step2_analyze(extraction_result) do
    prompt = """
    Dados estes valores extraídos de um documento médico:
    #{extraction_result.text}

    IMPORTANTE: Responda em português brasileiro.
    Forneça análise relevante para fitness como JSON:
    {
      "abnormal_values": [{"name": "...", "concern": "...", "fitness_impact": "..."}],
      "nutritional_indicators": ["..."],
      "exercise_considerations": ["..."],
      "requires_medical_attention": ["..."],
      "fitness_relevant_observations": ["..."],
      "overall_fitness_clearance": "cleared|caution|needs_review",
      "confidence": 0.0-1.0
    }
    IMPORTANTE: Isto NÃO é aconselhamento médico. Sinalize qualquer coisa que requeira atenção médica.
    Retorne APENAS JSON válido, sem markdown.
    """

    system = "Você é um interpretador de dados de saúde orientado para fitness. Destaque valores relevantes para exercício e nutrição. Sempre recomende consulta médica para valores anormais. Nunca diagnostique. Responda sempre em português brasileiro."

    AIClient.chat(prompt, model: :sonnet, system: system)
  end

  defp parse_result(analysis_text, extraction_text) do
    clean = fn t -> t |> String.replace(~r/```json\s*/, "") |> String.replace(~r/```\s*/, "") |> String.trim() end

    with {:ok, analysis_data} <- Jason.decode(clean.(analysis_text)),
         {:ok, extraction_data} <- Jason.decode(clean.(extraction_text)) do
      combined = %{
        "extraction" => extraction_data,
        "analysis" => analysis_data,
        "confidence" => Map.get(analysis_data, "confidence", 0.7)
      }
      {:ok, combined}
    else
      _ -> {:error, :json_parse_failed}
    end
  end
end
