defmodule GaPersonal.Repo.Migrations.CreatePoseAnalyses do
  use Ecto.Migration

  def change do
    create table(:pose_analyses, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :analysis_type, :string, null: false
      add :exercise_name, :string
      add :keypoints_data, :map, default: %{}
      add :scores, :map, default: %{}
      add :feedback, {:array, :string}, default: []
      add :overall_score, :float

      add :student_id, references(:users, type: :binary_id, on_delete: :nothing), null: false
      add :trainer_id, references(:users, type: :binary_id, on_delete: :nothing), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:pose_analyses, [:student_id])
    create index(:pose_analyses, [:trainer_id])
    create index(:pose_analyses, [:analysis_type])
  end
end
