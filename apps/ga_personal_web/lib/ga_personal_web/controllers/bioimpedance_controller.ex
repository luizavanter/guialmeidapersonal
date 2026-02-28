defmodule GaPersonalWeb.BioimpedanceController do
  use GaPersonalWeb, :controller

  alias GaPersonal.Bioimpedance
  alias GaPersonal.Privacy

  action_fallback GaPersonalWeb.FallbackController

  @doc """
  POST /api/v1/bioimpedance/extract
  Start extraction from an uploaded bioimpedance report.
  """
  def extract(conn, %{"bioimpedance" => params}) do
    trainer_id = conn.assigns.current_user_id

    with :ok <- validate_required(params, ~w(media_file_id device_type student_id)),
         {:ok, import_record} <- Bioimpedance.start_extraction(
           params["media_file_id"],
           params["device_type"],
           params["student_id"],
           trainer_id
         ) do
      Privacy.log_access(trainer_id, "ai_analyze", "bioimpedance_import", import_record.id, conn_info(conn))

      conn
      |> put_status(:created)
      |> json(%{data: import_json(import_record)})
    else
      {:error, :not_found} -> {:error, :not_found}
      {:error, :unauthorized} -> {:error, :forbidden}
      {:error, %Ecto.Changeset{} = changeset} -> {:error, changeset}
      {:error, :bad_request, msg} -> {:error, :bad_request, msg}
      error -> error
    end
  end

  @doc """
  GET /api/v1/bioimpedance/imports
  List imports for the trainer with optional filters.
  """
  def index(conn, params) do
    trainer_id = conn.assigns.current_user_id
    filters = Map.take(params, ["status", "student_id", "device_type"])
    imports = Bioimpedance.list_imports(trainer_id, filters)
    json(conn, %{data: Enum.map(imports, &import_json/1)})
  end

  @doc """
  GET /api/v1/bioimpedance/imports/:id
  Show import detail with extracted data.
  """
  def show(conn, %{"id" => id}) do
    trainer_id = conn.assigns.current_user_id

    case Bioimpedance.get_import_for_trainer(id, trainer_id) do
      {:ok, import_record} -> json(conn, %{data: import_json(import_record)})
      {:error, :not_found} -> {:error, :not_found}
      {:error, :unauthorized} -> {:error, :forbidden}
    end
  end

  @doc """
  PUT /api/v1/bioimpedance/imports/:id
  Trainer edits extracted data before applying.
  """
  def update(conn, %{"id" => id, "bioimpedance" => params}) do
    trainer_id = conn.assigns.current_user_id

    case Bioimpedance.review(id, trainer_id, params) do
      {:ok, import_record} -> json(conn, %{data: import_json(import_record)})
      {:error, :not_found} -> {:error, :not_found}
      {:error, :unauthorized} -> {:error, :forbidden}
      {:error, :bad_request, msg} -> {:error, :bad_request, msg}
      {:error, %Ecto.Changeset{} = changeset} -> {:error, changeset}
    end
  end

  @doc """
  POST /api/v1/bioimpedance/imports/:id/apply
  Apply extracted data to create a BodyAssessment.
  """
  def apply_import(conn, %{"id" => id}) do
    trainer_id = conn.assigns.current_user_id

    case Bioimpedance.apply_to_assessment(id, trainer_id) do
      {:ok, result} ->
        json(conn, %{
          data: import_json(result),
          message: "Bioimpedance data applied to body assessment"
        })

      {:error, :not_found} -> {:error, :not_found}
      {:error, :unauthorized} -> {:error, :forbidden}
      {:error, :bad_request, msg} -> {:error, :bad_request, msg}
      {:error, %Ecto.Changeset{} = changeset} -> {:error, changeset}
    end
  end

  @doc """
  POST /api/v1/bioimpedance/imports/:id/reject
  Reject an extraction.
  """
  def reject(conn, %{"id" => id} = params) do
    trainer_id = conn.assigns.current_user_id
    notes = params["notes"]

    case Bioimpedance.reject(id, trainer_id, notes) do
      {:ok, import_record} -> json(conn, %{data: import_json(import_record)})
      {:error, :not_found} -> {:error, :not_found}
      {:error, :unauthorized} -> {:error, :forbidden}
      {:error, :bad_request, msg} -> {:error, :bad_request, msg}
    end
  end

  defp import_json(import_record) do
    %{
      id: import_record.id,
      device_type: import_record.device_type,
      status: import_record.status,
      extracted_data: import_record.extracted_data,
      confidence_score: import_record.confidence_score,
      trainer_notes: import_record.trainer_notes,
      applied_at: import_record.applied_at,
      media_file_id: import_record.media_file_id,
      student_id: import_record.student_id,
      trainer_id: import_record.trainer_id,
      body_assessment_id: import_record.body_assessment_id,
      inserted_at: import_record.inserted_at,
      updated_at: import_record.updated_at
    }
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
