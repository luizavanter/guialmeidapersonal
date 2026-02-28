defmodule GaPersonal.Workouts.WorkoutPlan do
  use Ecto.Schema
  import Ecto.Changeset
  alias GaPersonal.Sanitizer

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "workout_plans" do
    field :name, :string
    field :description, :string
    field :duration_weeks, :integer
    field :sessions_per_week, :integer
    field :difficulty_level, :string
    field :goals, {:array, :string}, default: []
    field :status, :string, default: "draft"
    field :started_at, :date
    field :completed_at, :date
    field :is_template, :boolean, default: false

    belongs_to :trainer, GaPersonal.Accounts.User
    belongs_to :student, GaPersonal.Accounts.User
    has_many :workout_exercises, GaPersonal.Workouts.WorkoutExercise

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(workout_plan, attrs) do
    workout_plan
    |> cast(attrs, [
      :trainer_id,
      :student_id,
      :name,
      :description,
      :duration_weeks,
      :sessions_per_week,
      :difficulty_level,
      :goals,
      :status,
      :started_at,
      :completed_at,
      :is_template
    ])
    |> Sanitizer.sanitize_changeset([:name, :description, :goals])
    |> validate_required([:trainer_id, :name])
    |> validate_length(:name, max: 255)
    |> validate_length(:description, max: 5000)
    |> validate_inclusion(:status, ["draft", "active", "completed", "archived"])
    |> foreign_key_constraint(:trainer_id)
    |> foreign_key_constraint(:student_id)
  end
end
