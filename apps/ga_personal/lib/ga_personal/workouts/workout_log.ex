defmodule GaPersonal.Workouts.WorkoutLog do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "workout_logs" do
    field :completed_at, :utc_datetime
    field :sets_completed, :integer
    field :reps_completed, :string
    field :weight_used, :string
    field :duration_seconds, :integer
    field :difficulty_rating, :integer
    field :notes, :string

    belongs_to :student, GaPersonal.Accounts.User
    belongs_to :workout_plan, GaPersonal.Workouts.WorkoutPlan
    belongs_to :exercise, GaPersonal.Workouts.Exercise

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(workout_log, attrs) do
    workout_log
    |> cast(attrs, [
      :student_id,
      :workout_plan_id,
      :exercise_id,
      :completed_at,
      :sets_completed,
      :reps_completed,
      :weight_used,
      :duration_seconds,
      :difficulty_rating,
      :notes
    ])
    |> validate_required([:student_id, :exercise_id, :completed_at])
    |> validate_inclusion(:difficulty_rating, 1..5)
    |> foreign_key_constraint(:student_id)
    |> foreign_key_constraint(:exercise_id)
  end
end
