defmodule GaPersonal.Workouts.WorkoutExercise do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "workout_exercises" do
    field :day_number, :integer
    field :order_in_workout, :integer
    field :sets, :integer
    field :reps, :string
    field :weight, :string
    field :duration_seconds, :integer
    field :rest_seconds, :integer
    field :notes, :string

    belongs_to :workout_plan, GaPersonal.Workouts.WorkoutPlan
    belongs_to :exercise, GaPersonal.Workouts.Exercise

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(workout_exercise, attrs) do
    workout_exercise
    |> cast(attrs, [
      :workout_plan_id,
      :exercise_id,
      :day_number,
      :order_in_workout,
      :sets,
      :reps,
      :weight,
      :duration_seconds,
      :rest_seconds,
      :notes
    ])
    |> validate_required([:workout_plan_id, :exercise_id])
    |> foreign_key_constraint(:workout_plan_id)
    |> foreign_key_constraint(:exercise_id)
  end
end
