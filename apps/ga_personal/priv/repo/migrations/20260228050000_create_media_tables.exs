defmodule GaPersonal.Repo.Migrations.CreateMediaTables do
  use Ecto.Migration

  def change do
    create table(:media_files, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :file_type, :string, null: false
      add :gcs_path, :string, null: false
      add :original_filename, :string, null: false
      add :content_type, :string, null: false
      add :file_size_bytes, :integer
      add :metadata, :map, default: %{}
      add :encrypted, :boolean, default: true
      add :upload_status, :string, default: "pending", null: false
      add :deleted_at, :utc_datetime

      add :student_id, references(:users, type: :binary_id, on_delete: :nothing), null: false
      add :uploaded_by_id, references(:users, type: :binary_id, on_delete: :nothing), null: false
      add :trainer_id, references(:users, type: :binary_id, on_delete: :nothing), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:media_files, [:student_id])
    create index(:media_files, [:trainer_id])
    create index(:media_files, [:file_type])
    create index(:media_files, [:deleted_at])

    create table(:consent_records, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :consent_type, :string, null: false
      add :granted, :boolean, null: false
      add :granted_at, :utc_datetime
      add :revoked_at, :utc_datetime
      add :ip_address, :string
      add :user_agent, :string

      add :user_id, references(:users, type: :binary_id, on_delete: :nothing), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:consent_records, [:user_id])
    create index(:consent_records, [:user_id, :consent_type])

    create table(:access_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :action, :string, null: false
      add :resource_type, :string, null: false
      add :resource_id, :binary_id
      add :ip_address, :string
      add :user_agent, :string
      add :metadata, :map, default: %{}

      add :user_id, references(:users, type: :binary_id, on_delete: :nothing), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:access_logs, [:user_id])
    create index(:access_logs, [:resource_type, :resource_id])
  end
end
