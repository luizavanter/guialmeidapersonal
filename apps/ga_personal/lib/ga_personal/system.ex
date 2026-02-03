defmodule GaPersonal.System do
  @moduledoc """
  The System context - handles system settings and audit logs.
  """

  import Ecto.Query, warn: false
  alias GaPersonal.Repo
  alias GaPersonal.System.{SystemSetting, AuditLog}

  ## SystemSetting functions

  def list_settings(trainer_id, category \\ nil) do
    query = from s in SystemSetting,
      where: s.trainer_id == ^trainer_id

    query =
      if category do
        from s in query, where: s.category == ^category
      else
        query
      end

    query
    |> order_by([s], s.key)
    |> Repo.all()
  end

  def get_setting(trainer_id, key) do
    Repo.get_by(SystemSetting, trainer_id: trainer_id, key: key)
  end

  def get_setting_value(trainer_id, key, default \\ nil) do
    case get_setting(trainer_id, key) do
      nil -> default
      setting -> parse_setting_value(setting)
    end
  end

  defp parse_setting_value(%{value: value, value_type: "integer"}), do: String.to_integer(value)
  defp parse_setting_value(%{value: "true", value_type: "boolean"}), do: true
  defp parse_setting_value(%{value: "false", value_type: "boolean"}), do: false
  defp parse_setting_value(%{value: value, value_type: "json"}), do: Jason.decode!(value)
  defp parse_setting_value(%{value: value}), do: value

  def create_setting(attrs \\ %{}) do
    %SystemSetting{}
    |> SystemSetting.changeset(attrs)
    |> Repo.insert()
  end

  def update_setting(%SystemSetting{} = setting, attrs) do
    setting
    |> SystemSetting.changeset(attrs)
    |> Repo.update()
  end

  def upsert_setting(trainer_id, key, value, opts \\ []) do
    value_type = Keyword.get(opts, :value_type, "string")
    category = Keyword.get(opts, :category)
    description = Keyword.get(opts, :description)

    case get_setting(trainer_id, key) do
      nil ->
        create_setting(%{
          trainer_id: trainer_id,
          key: key,
          value: to_string(value),
          value_type: value_type,
          category: category,
          description: description
        })

      setting ->
        update_setting(setting, %{value: to_string(value)})
    end
  end

  ## AuditLog functions

  def list_audit_logs(filters \\ %{}) do
    query = from al in AuditLog,
      order_by: [desc: al.inserted_at],
      limit: 1000

    query
    |> apply_audit_filters(filters)
    |> Repo.all()
  end

  defp apply_audit_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {:user_id, user_id}, query ->
        from al in query, where: al.user_id == ^user_id

      {:resource_type, resource_type}, query ->
        from al in query, where: al.resource_type == ^resource_type

      {:resource_id, resource_id}, query ->
        from al in query, where: al.resource_id == ^resource_id

      {:date_from, date_from}, query ->
        from al in query, where: al.inserted_at >= ^date_from

      _, query ->
        query
    end)
  end

  def create_audit_log(attrs \\ %{}) do
    %AuditLog{}
    |> AuditLog.changeset(attrs)
    |> Repo.insert()
  end

  def log_action(user_id, action, resource_type, resource_id, changes \\ %{}, metadata \\ %{}) do
    create_audit_log(%{
      user_id: user_id,
      action: action,
      resource_type: resource_type,
      resource_id: resource_id,
      changes: changes,
      ip_address: metadata[:ip_address],
      user_agent: metadata[:user_agent]
    })
  end
end
