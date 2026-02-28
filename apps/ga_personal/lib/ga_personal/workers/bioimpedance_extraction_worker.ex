defmodule GaPersonal.Workers.BioimpedanceExtractionWorker do
  @moduledoc """
  Oban worker that extracts bioimpedance data from uploaded reports
  using Claude Haiku for OCR/extraction.
  """
  use Oban.Worker, queue: :ai, max_attempts: 3

  require Logger

  alias GaPersonal.Bioimpedance
  alias GaPersonal.Media
  alias GaPersonal.GCS.Client, as: GCSClient
  alias GaPersonal.AI.Client, as: AIClient
  alias GaPersonal.Privacy

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"import_id" => import_id}}) do
    Logger.info("BioimpedanceExtractionWorker: Starting extraction for import #{import_id}")

    with {:ok, import_record} <- Bioimpedance.get_import(import_id),
         {:ok, media_file} <- Media.get_file(import_record.media_file_id),
         {:ok, download_url} <- GCSClient.generate_signed_download_url(media_file.gcs_path),
         {:ok, ai_result} <- extract_data(download_url, media_file.content_type, import_record.device_type) do
      # Log AI access for LGPD compliance
      Privacy.log_access(
        import_record.trainer_id,
        "ai_analyze",
        "bioimpedance_import",
        import_id,
        %{metadata: %{model: ai_result.model, tokens: ai_result.tokens_used}}
      )

      # Parse the extracted data
      case parse_extraction_result(ai_result.text) do
        {:ok, extracted_data, confidence} ->
          Bioimpedance.save_extraction_result(import_id, extracted_data, confidence)
          Logger.info("BioimpedanceExtractionWorker: Extraction complete for #{import_id}, confidence: #{confidence}")
          :ok

        {:error, reason} ->
          Logger.error("BioimpedanceExtractionWorker: Failed to parse AI response for #{import_id}: #{inspect(reason)}")
          Bioimpedance.mark_extraction_failed(import_id)
          {:error, reason}
      end
    else
      {:error, reason} ->
        Logger.error("BioimpedanceExtractionWorker: Failed for #{import_id}: #{inspect(reason)}")
        Bioimpedance.mark_extraction_failed(import_id)
        {:error, reason}
    end
  end

  def enqueue(import_id) do
    %{import_id: import_id}
    |> new()
    |> Oban.insert()
  end

  defp extract_data(download_url, content_type, device_type) do
    prompt = extraction_prompt(device_type)

    if String.starts_with?(content_type, "image/") do
      AIClient.analyze_image_url(download_url, content_type, prompt, model: :haiku)
    else
      # For PDFs, we instruct Claude to process the document
      # Claude can handle PDF URLs directly via image analysis
      AIClient.analyze_image_url(download_url, "image/png", prompt, model: :haiku)
    end
  end

  defp extraction_prompt(device_type) do
    """
    Extract bioimpedance measurements from this #{device_type} report.
    Return ONLY valid JSON (no markdown, no code blocks) with this exact structure:
    {
      "weight_kg": <number or null>,
      "height_cm": <number or null>,
      "body_fat_percentage": <number or null>,
      "muscle_mass_kg": <number or null>,
      "visceral_fat_level": <number or null>,
      "basal_metabolic_rate": <number or null>,
      "body_water_percentage": <number or null>,
      "bone_mass_kg": <number or null>,
      "protein_percentage": <number or null>,
      "bmi": <number or null>,
      "segmental_analysis": <object or null>,
      "confidence": <number 0.0-1.0>,
      "field_confidences": {
        "weight_kg": <number 0.0-1.0>,
        "body_fat_percentage": <number 0.0-1.0>
      },
      "notes": "<any relevant observations about the report>"
    }

    Set values to null if not found in the report.
    The confidence score should reflect how clearly the values were readable.
    """
  end

  defp parse_extraction_result(text) do
    # Clean up potential markdown code blocks
    cleaned =
      text
      |> String.replace(~r/```json\s*/, "")
      |> String.replace(~r/```\s*/, "")
      |> String.trim()

    case Jason.decode(cleaned) do
      {:ok, data} when is_map(data) ->
        confidence = Map.get(data, "confidence", 0.5)
        extracted = Map.delete(data, "confidence")
        {:ok, extracted, confidence}

      {:ok, _} ->
        {:error, :invalid_json_structure}

      {:error, _} ->
        {:error, :json_parse_failed}
    end
  end
end
