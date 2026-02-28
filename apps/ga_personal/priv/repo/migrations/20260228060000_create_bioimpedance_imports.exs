defmodule GaPersonal.Repo.Migrations.CreateBioimpedanceImports do
  use Ecto.Migration

  def change do
    create table(:bioimpedance_imports, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :device_type, :string, null: false
      add :status, :string, null: false, default: "pending_extraction"
      add :extracted_data, :map, default: %{}
      add :confidence_score, :float
      add :trainer_notes, :string
      add :applied_at, :utc_datetime

      add :media_file_id, references(:media_files, type: :binary_id, on_delete: :nothing), null: false
      add :student_id, references(:users, type: :binary_id, on_delete: :nothing), null: false
      add :trainer_id, references(:users, type: :binary_id, on_delete: :nothing), null: false
      add :body_assessment_id, references(:body_assessments, type: :binary_id, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:bioimpedance_imports, [:student_id])
    create index(:bioimpedance_imports, [:trainer_id])
    create index(:bioimpedance_imports, [:media_file_id])
    create index(:bioimpedance_imports, [:status])
  end
end
