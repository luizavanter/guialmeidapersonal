defmodule GaPersonal.Repo.Migrations.CreateAiAnalyses do
  use Ecto.Migration

  def change do
    create table(:ai_analyses, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :analysis_type, :string, null: false
      add :status, :string, null: false, default: "queued"
      add :model_used, :string
      add :input_data, :map, default: %{}
      add :result, :map, default: %{}
      add :confidence_score, :float
      add :trainer_review, :string
      add :reviewed_at, :utc_datetime
      add :visible_to_student, :boolean, default: false
      add :tokens_used, :integer
      add :processing_time_ms, :integer

      add :student_id, references(:users, type: :binary_id, on_delete: :nothing), null: false
      add :trainer_id, references(:users, type: :binary_id, on_delete: :nothing), null: false
      add :media_file_id, references(:media_files, type: :binary_id, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:ai_analyses, [:student_id])
    create index(:ai_analyses, [:trainer_id])
    create index(:ai_analyses, [:analysis_type])
    create index(:ai_analyses, [:status])
    create index(:ai_analyses, [:media_file_id])
  end
end
