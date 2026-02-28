defmodule GaPersonalWeb.MediaController do
  use GaPersonalWeb, :controller

  alias GaPersonal.Media
  alias GaPersonal.Accounts
  alias GaPersonal.Privacy

  action_fallback GaPersonalWeb.FallbackController

  def create_upload_url(conn, %{"media" => params}) do
    user = conn.assigns.current_user
    trainer_id = resolve_trainer_id(user)
    student_id = params["student_id"] || user.id

    with :ok <- validate_required(params, ~w(file_type content_type original_filename)),
         {:ok, result} <- Media.generate_upload_url(
           student_id,
           params["file_type"],
           params["content_type"],
           params["original_filename"],
           user.id,
           trainer_id
         ) do
      Privacy.log_access(user.id, "upload", "media_file", result.file_id, conn_info(conn))

      conn
      |> put_status(:created)
      |> json(%{data: %{
        upload_url: result.upload_url,
        file_id: result.file_id,
        gcs_path: result.gcs_path
      }})
    else
      {:error, :invalid_content_type} ->
        {:error, :bad_request, "Invalid content type"}

      error ->
        error
    end
  end

  def confirm_upload(conn, %{"media" => %{"file_id" => file_id} = params}) do
    user = conn.assigns.current_user
    metadata = Map.get(params, "metadata", %{})
    file_size = Map.get(params, "file_size_bytes")

    confirm_attrs = %{}
    confirm_attrs = if file_size, do: Map.put(confirm_attrs, :file_size_bytes, file_size), else: confirm_attrs
    confirm_attrs = if metadata != %{}, do: Map.put(confirm_attrs, :metadata, metadata), else: confirm_attrs

    with {:ok, media_file} <- Media.get_file(file_id),
         :ok <- verify_upload_ownership(media_file, user),
         {:ok, confirmed} <- Media.confirm_upload(file_id, confirm_attrs) do
      json(conn, %{data: media_file_json(confirmed)})
    else
      {:error, :already_confirmed} ->
        {:error, :bad_request, "File already confirmed"}

      error ->
        error
    end
  end

  def download(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    with {:ok, media_file} <- Media.get_file(id),
         :ok <- verify_access(media_file, user),
         {:ok, download_url} <- Media.generate_download_url(id, user.id, conn_info(conn)) do
      json(conn, %{data: %{download_url: download_url, file: media_file_json(media_file)}})
    end
  end

  def index(conn, %{"student_id" => student_id} = params) do
    trainer_id = conn.assigns.current_user_id
    filters = Map.take(params, ["file_type"]) |> Map.put("student_id", student_id)
    files = Media.list_files_for_trainer(trainer_id, filters)
    json(conn, %{data: Enum.map(files, &media_file_json/1)})
  end

  def my_files(conn, params) do
    user = conn.assigns.current_user
    filters = Map.take(params, ["file_type"])
    files = Media.list_files(user.id, filters)
    json(conn, %{data: Enum.map(files, &media_file_json/1)})
  end

  def delete(conn, %{"id" => id}) do
    trainer_id = conn.assigns.current_user_id

    case Media.soft_delete(id, trainer_id) do
      {:ok, _} ->
        Privacy.log_access(trainer_id, "delete", "media_file", id, conn_info(conn))
        json(conn, %{message: "File deleted"})

      {:error, :not_found} -> {:error, :not_found}
      {:error, :unauthorized} -> {:error, :forbidden}
    end
  end

  defp media_file_json(file) do
    %{
      id: file.id,
      file_type: file.file_type,
      original_filename: file.original_filename,
      content_type: file.content_type,
      file_size_bytes: file.file_size_bytes,
      upload_status: file.upload_status,
      metadata: file.metadata,
      student_id: file.student_id,
      uploaded_by_id: file.uploaded_by_id,
      trainer_id: file.trainer_id,
      inserted_at: file.inserted_at,
      updated_at: file.updated_at
    }
  end

  defp resolve_trainer_id(%{role: role} = user) when role in [:trainer, :admin, "trainer", "admin"], do: user.id
  defp resolve_trainer_id(user) do
    case Accounts.get_student_by_user_id(user.id) do
      nil -> user.id
      student -> student.trainer_id
    end
  end

  defp verify_upload_ownership(media_file, user) do
    if media_file.uploaded_by_id == user.id or media_file.trainer_id == user.id do
      :ok
    else
      {:error, :forbidden}
    end
  end

  defp verify_access(media_file, user) do
    if media_file.student_id == user.id or media_file.trainer_id == user.id or media_file.uploaded_by_id == user.id do
      :ok
    else
      {:error, :forbidden}
    end
  end

  defp validate_required(params, fields) do
    missing = Enum.filter(fields, fn f -> is_nil(params[f]) or params[f] == "" end)

    if missing == [] do
      :ok
    else
      {:error, :bad_request, "Missing required fields: #{Enum.join(missing, ", ")}"}
    end
  end

  defp conn_info(conn) do
    %{
      ip_address: conn.remote_ip |> :inet.ntoa() |> to_string(),
      user_agent: Plug.Conn.get_req_header(conn, "user-agent") |> List.first()
    }
  end
end
