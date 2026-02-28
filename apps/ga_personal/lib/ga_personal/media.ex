defmodule GaPersonal.Media do
  @moduledoc """
  The Media context - handles file uploads, downloads, and media management.
  Uses GCS signed URLs for direct browser-to-cloud upload.
  """

  import Ecto.Query, warn: false
  alias GaPersonal.Repo
  alias GaPersonal.Media.MediaFile
  alias GaPersonal.GCS.Client, as: GCSClient
  alias GaPersonal.Privacy

  @allowed_content_types ~w(
    image/jpeg image/png image/webp
    application/pdf
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
    application/vnd.ms-excel
    text/csv
  )

  def generate_upload_url(student_id, file_type, content_type, original_filename, uploaded_by_id, trainer_id) do
    unless content_type in @allowed_content_types do
      {:error, :invalid_content_type}
    else
      file_id = Ecto.UUID.generate()
      ext = extension_from_content_type(content_type)
      gcs_path = "media/#{trainer_id}/#{student_id}/#{file_type}/#{file_id}#{ext}"

      attrs = %{
        id: file_id,
        file_type: file_type,
        gcs_path: gcs_path,
        original_filename: original_filename,
        content_type: content_type,
        upload_status: "pending",
        student_id: student_id,
        uploaded_by_id: uploaded_by_id,
        trainer_id: trainer_id
      }

      with {:ok, media_file} <- create_media_file(attrs),
           {:ok, upload_url} <- GCSClient.generate_signed_upload_url(gcs_path, content_type) do
        {:ok, %{upload_url: upload_url, file_id: media_file.id, gcs_path: gcs_path}}
      end
    end
  end

  def confirm_upload(file_id, metadata \\ %{}) do
    case get_file(file_id) do
      {:ok, media_file} ->
        if media_file.upload_status == "pending" do
          media_file
          |> MediaFile.confirm_changeset(metadata)
          |> Repo.update()
        else
          {:error, :already_confirmed}
        end

      error ->
        error
    end
  end

  def generate_download_url(file_id, user_id, conn_info \\ %{}) do
    case get_file(file_id) do
      {:ok, media_file} ->
        Privacy.log_access(user_id, "download", "media_file", file_id, conn_info)

        GCSClient.generate_signed_download_url(media_file.gcs_path)

      error ->
        error
    end
  end

  def list_files(student_id, filters \\ %{}) do
    MediaFile.not_deleted()
    |> where([m], m.student_id == ^student_id)
    |> where([m], m.upload_status == "confirmed")
    |> apply_filters(filters)
    |> order_by([m], desc: m.inserted_at)
    |> Repo.all()
  end

  def list_files_for_trainer(trainer_id, filters \\ %{}) do
    MediaFile.not_deleted()
    |> where([m], m.trainer_id == ^trainer_id)
    |> where([m], m.upload_status == "confirmed")
    |> apply_filters(filters)
    |> order_by([m], desc: m.inserted_at)
    |> Repo.all()
  end

  def get_file(id) do
    case Repo.get(MediaFile, id) do
      nil -> {:error, :not_found}
      %MediaFile{deleted_at: deleted_at} = _file when not is_nil(deleted_at) -> {:error, :not_found}
      media_file -> {:ok, media_file}
    end
  end

  def get_file_for_trainer(id, trainer_id) do
    case get_file(id) do
      {:ok, %MediaFile{trainer_id: ^trainer_id} = file} -> {:ok, file}
      {:ok, %MediaFile{}} -> {:error, :unauthorized}
      error -> error
    end
  end

  def get_file_for_student(id, student_id) do
    case get_file(id) do
      {:ok, %MediaFile{student_id: ^student_id} = file} -> {:ok, file}
      {:ok, %MediaFile{}} -> {:error, :unauthorized}
      error -> error
    end
  end

  def soft_delete(id, trainer_id) do
    case get_file_for_trainer(id, trainer_id) do
      {:ok, media_file} ->
        media_file
        |> Ecto.Changeset.change(%{deleted_at: DateTime.utc_now() |> DateTime.truncate(:second)})
        |> Repo.update()

      error ->
        error
    end
  end

  def hard_delete_expired do
    thirty_days_ago =
      DateTime.utc_now()
      |> DateTime.add(-30, :day)
      |> DateTime.truncate(:second)

    expired_files =
      from(m in MediaFile,
        where: not is_nil(m.deleted_at) and m.deleted_at < ^thirty_days_ago
      )
      |> Repo.all()

    results =
      Enum.map(expired_files, fn file ->
        GCSClient.delete_object(file.gcs_path)
        Repo.delete(file)
      end)

    {:ok, length(results)}
  end

  defp create_media_file(attrs) do
    %MediaFile{id: attrs.id}
    |> MediaFile.changeset(Map.delete(attrs, :id))
    |> Repo.insert()
  end

  defp apply_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {"file_type", file_type}, query ->
        from m in query, where: m.file_type == ^file_type

      {"student_id", student_id}, query ->
        from m in query, where: m.student_id == ^student_id

      _, query ->
        query
    end)
  end

  defp extension_from_content_type("image/jpeg"), do: ".jpg"
  defp extension_from_content_type("image/png"), do: ".png"
  defp extension_from_content_type("image/webp"), do: ".webp"
  defp extension_from_content_type("application/pdf"), do: ".pdf"
  defp extension_from_content_type("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"), do: ".xlsx"
  defp extension_from_content_type("application/vnd.ms-excel"), do: ".xls"
  defp extension_from_content_type("text/csv"), do: ".csv"
  defp extension_from_content_type(_), do: ""
end
