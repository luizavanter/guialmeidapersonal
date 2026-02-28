defmodule GaPersonal.Pose.PoseAnalysis do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @analysis_types ~w(posture exercise)
  @exercises ~w(squat deadlift shoulder_press plank lunge)

  schema "pose_analyses" do
    field :analysis_type, :string
    field :exercise_name, :string
    field :keypoints_data, :map, default: %{}
    field :scores, :map, default: %{}
    field :feedback, {:array, :string}, default: []
    field :overall_score, :float

    belongs_to :student, GaPersonal.Accounts.User
    belongs_to :trainer, GaPersonal.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(pose_analysis, attrs) do
    pose_analysis
    |> cast(attrs, [:analysis_type, :exercise_name, :keypoints_data, :scores, :feedback, :overall_score, :student_id, :trainer_id])
    |> validate_required([:analysis_type, :keypoints_data, :student_id, :trainer_id])
    |> validate_inclusion(:analysis_type, @analysis_types)
    |> validate_exercise_name()
    |> validate_number(:overall_score, greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0)
    |> foreign_key_constraint(:student_id)
    |> foreign_key_constraint(:trainer_id)
  end

  defp validate_exercise_name(changeset) do
    case get_field(changeset, :analysis_type) do
      "exercise" ->
        changeset
        |> validate_required([:exercise_name])
        |> validate_inclusion(:exercise_name, @exercises)

      _ ->
        changeset
    end
  end

  def analysis_types, do: @analysis_types
  def exercises, do: @exercises
end
