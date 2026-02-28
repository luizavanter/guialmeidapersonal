defmodule GaPersonal.Bioimpedance do
  @moduledoc """
  The Bioimpedance context - handles bioimpedance report import, AI extraction,
  trainer review, and application to BodyAssessment records.
  """

  import Ecto.Query, warn: false
  alias GaPersonal.Repo
  alias GaPersonal.Bioimpedance.BioimpedanceImport
  alias GaPersonal.Evolution
  alias GaPersonal.Media

  @doc """
  Starts extraction for an uploaded bioimpedance report.
  Creates a BioimpedanceImport record and enqueues the extraction worker.
  """
  def start_extraction(media_file_id, device_type, student_id, trainer_id) do
    attrs = %{
      media_file_id: media_file_id,
      device_type: device_type,
      student_id: student_id,
      trainer_id: trainer_id,
      status: "pending_extraction"
    }

    with {:ok, media_file} <- Media.get_file(media_file_id),
         :ok <- verify_file_ownership(media_file, trainer_id),
         {:ok, import_record} <- create_import(attrs) do
      # Enqueue extraction worker
      GaPersonal.Workers.BioimpedanceExtractionWorker.enqueue(import_record.id)
      {:ok, import_record}
    end
  end

  @doc """
  Updates the import with extracted data from the AI worker.
  """
  def save_extraction_result(import_id, extracted_data, confidence_score) do
    case get_import(import_id) do
      {:ok, import_record} ->
        import_record
        |> BioimpedanceImport.extraction_changeset(%{
          status: "extracted",
          extracted_data: extracted_data,
          confidence_score: confidence_score
        })
        |> Repo.update()

      error ->
        error
    end
  end

  @doc """
  Marks extraction as failed.
  """
  def mark_extraction_failed(import_id) do
    case get_import(import_id) do
      {:ok, import_record} ->
        import_record
        |> Ecto.Changeset.change(%{status: "failed"})
        |> Repo.update()

      error ->
        error
    end
  end

  @doc """
  Trainer reviews and optionally edits extracted data.
  """
  def review(import_id, trainer_id, attrs) do
    with {:ok, import_record} <- get_import_for_trainer(import_id, trainer_id),
         :ok <- validate_status(import_record, ["extracted", "reviewed"]) do
      import_record
      |> BioimpedanceImport.review_changeset(Map.merge(attrs, %{"status" => "reviewed"}))
      |> Repo.update()
    end
  end

  @doc """
  Applies extracted data to create a BodyAssessment record.
  """
  def apply_to_assessment(import_id, trainer_id) do
    with {:ok, import_record} <- get_import_for_trainer(import_id, trainer_id),
         :ok <- validate_status(import_record, ["extracted", "reviewed"]) do
      assessment_attrs = build_assessment_attrs(import_record)

      case Evolution.create_body_assessment(assessment_attrs) do
        {:ok, assessment} ->
          now = DateTime.utc_now() |> DateTime.truncate(:second)

          import_record
          |> BioimpedanceImport.apply_changeset(%{
            status: "applied",
            applied_at: now,
            body_assessment_id: assessment.id
          })
          |> Repo.update()

          {:ok, import_record |> Map.put(:body_assessment, assessment)}

        {:error, changeset} ->
          {:error, changeset}
      end
    end
  end

  @doc """
  Rejects an extraction.
  """
  def reject(import_id, trainer_id, notes \\ nil) do
    with {:ok, import_record} <- get_import_for_trainer(import_id, trainer_id),
         :ok <- validate_status(import_record, ["extracted", "reviewed"]) do
      attrs = %{status: "rejected"}
      attrs = if notes, do: Map.put(attrs, :trainer_notes, notes), else: attrs

      import_record
      |> BioimpedanceImport.review_changeset(attrs)
      |> Repo.update()
    end
  end

  ## Query functions

  def list_imports(trainer_id, filters \\ %{}) do
    from(i in BioimpedanceImport,
      where: i.trainer_id == ^trainer_id,
      order_by: [desc: i.inserted_at],
      preload: [:media_file, :body_assessment]
    )
    |> apply_filters(filters)
    |> Repo.all()
  end

  def get_import(id) do
    case Repo.get(BioimpedanceImport, id) do
      nil -> {:error, :not_found}
      import_record -> {:ok, import_record}
    end
  end

  def get_import_for_trainer(id, trainer_id) do
    case Repo.get(BioimpedanceImport, id) do
      nil -> {:error, :not_found}
      %BioimpedanceImport{trainer_id: ^trainer_id} = import_record -> {:ok, import_record}
      %BioimpedanceImport{} -> {:error, :unauthorized}
    end
  end

  ## Private helpers

  defp create_import(attrs) do
    %BioimpedanceImport{}
    |> BioimpedanceImport.changeset(attrs)
    |> Repo.insert()
  end

  defp verify_file_ownership(media_file, trainer_id) do
    if media_file.trainer_id == trainer_id do
      :ok
    else
      {:error, :unauthorized}
    end
  end

  defp validate_status(import_record, allowed_statuses) do
    if import_record.status in allowed_statuses do
      :ok
    else
      {:error, :bad_request, "Import is in '#{import_record.status}' status, expected one of: #{Enum.join(allowed_statuses, ", ")}"}
    end
  end

  defp build_assessment_attrs(import_record) do
    data = import_record.extracted_data

    %{
      "student_id" => import_record.student_id,
      "trainer_id" => import_record.trainer_id,
      "assessment_date" => Date.utc_today(),
      "weight_kg" => data["weight_kg"],
      "height_cm" => data["height_cm"],
      "body_fat_percentage" => data["body_fat_percentage"],
      "muscle_mass_kg" => data["muscle_mass_kg"],
      "notes" => "Imported from #{import_record.device_type} bioimpedance report"
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end

  defp apply_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {"status", status}, query ->
        from i in query, where: i.status == ^status

      {"student_id", student_id}, query ->
        from i in query, where: i.student_id == ^student_id

      {"device_type", device_type}, query ->
        from i in query, where: i.device_type == ^device_type

      _, query ->
        query
    end)
  end
end
