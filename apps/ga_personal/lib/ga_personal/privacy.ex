defmodule GaPersonal.Privacy do
  @moduledoc """
  The Privacy context - handles LGPD compliance, consent records, access logging,
  and user data export/deletion.
  """

  import Ecto.Query, warn: false
  alias GaPersonal.Repo
  alias GaPersonal.Privacy.{ConsentRecord, AccessLog}

  ## Consent functions

  def record_consent(user_id, consent_type, conn_info \\ %{}) do
    attrs = %{
      user_id: user_id,
      consent_type: consent_type,
      granted: true,
      granted_at: DateTime.utc_now() |> DateTime.truncate(:second),
      ip_address: Map.get(conn_info, :ip_address),
      user_agent: Map.get(conn_info, :user_agent)
    }

    # Revoke any existing consent of this type first
    revoke_existing_consent(user_id, consent_type)

    %ConsentRecord{}
    |> ConsentRecord.changeset(attrs)
    |> Repo.insert()
  end

  def revoke_consent(user_id, consent_type) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    from(c in ConsentRecord,
      where: c.user_id == ^user_id and c.consent_type == ^consent_type and c.granted == true and is_nil(c.revoked_at)
    )
    |> Repo.update_all(set: [granted: false, revoked_at: now, updated_at: now])

    {:ok, :revoked}
  end

  def has_consent?(user_id, consent_type) do
    from(c in ConsentRecord,
      where: c.user_id == ^user_id and c.consent_type == ^consent_type and c.granted == true and is_nil(c.revoked_at)
    )
    |> Repo.exists?()
  end

  def list_consents(user_id) do
    from(c in ConsentRecord,
      where: c.user_id == ^user_id,
      order_by: [desc: c.inserted_at]
    )
    |> Repo.all()
  end

  ## Access logging

  def log_access(user_id, action, resource_type, resource_id, conn_info \\ %{}) do
    attrs = %{
      user_id: user_id,
      action: action,
      resource_type: resource_type,
      resource_id: resource_id,
      ip_address: Map.get(conn_info, :ip_address),
      user_agent: Map.get(conn_info, :user_agent),
      metadata: Map.get(conn_info, :metadata, %{})
    }

    %AccessLog{}
    |> AccessLog.changeset(attrs)
    |> Repo.insert()
  end

  def get_audit_trail(user_id, filters \\ %{}) do
    query = from(a in AccessLog,
      where: a.user_id == ^user_id,
      order_by: [desc: a.inserted_at]
    )

    query
    |> apply_audit_filters(filters)
    |> Repo.all()
  end

  ## LGPD data export/deletion

  def export_user_data(user_id) do
    consents = list_consents(user_id)
    access_logs = get_audit_trail(user_id)

    media_files =
      from(m in GaPersonal.Media.MediaFile,
        where: m.student_id == ^user_id and is_nil(m.deleted_at)
      )
      |> Repo.all()

    {:ok, %{
      consents: Enum.map(consents, &consent_export/1),
      access_logs: Enum.map(access_logs, &access_log_export/1),
      media_files: Enum.map(media_files, &media_file_export/1)
    }}
  end

  def delete_user_data(user_id) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    # Soft-delete all media files
    from(m in GaPersonal.Media.MediaFile,
      where: m.student_id == ^user_id and is_nil(m.deleted_at)
    )
    |> Repo.update_all(set: [deleted_at: now, updated_at: now])

    # Revoke all consents
    from(c in ConsentRecord,
      where: c.user_id == ^user_id and c.granted == true and is_nil(c.revoked_at)
    )
    |> Repo.update_all(set: [granted: false, revoked_at: now, updated_at: now])

    {:ok, :deleted}
  end

  ## Private helpers

  defp revoke_existing_consent(user_id, consent_type) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    from(c in ConsentRecord,
      where: c.user_id == ^user_id and c.consent_type == ^consent_type and c.granted == true and is_nil(c.revoked_at)
    )
    |> Repo.update_all(set: [granted: false, revoked_at: now, updated_at: now])
  end

  defp apply_audit_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {"action", action}, query ->
        from a in query, where: a.action == ^action

      {"resource_type", resource_type}, query ->
        from a in query, where: a.resource_type == ^resource_type

      _, query ->
        query
    end)
  end

  defp consent_export(consent) do
    %{
      consent_type: consent.consent_type,
      granted: consent.granted,
      granted_at: consent.granted_at,
      revoked_at: consent.revoked_at,
      created_at: consent.inserted_at
    }
  end

  defp access_log_export(log) do
    %{
      action: log.action,
      resource_type: log.resource_type,
      resource_id: log.resource_id,
      created_at: log.inserted_at
    }
  end

  defp media_file_export(file) do
    %{
      id: file.id,
      file_type: file.file_type,
      original_filename: file.original_filename,
      content_type: file.content_type,
      file_size_bytes: file.file_size_bytes,
      created_at: file.inserted_at
    }
  end
end
