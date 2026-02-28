defmodule GaPersonal.AIAnalysis.AIAnalysisRecord do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @analysis_types ~w(visual_body numeric_trends medical_document)
  @statuses ~w(queued processing completed failed reviewed)

  schema "ai_analyses" do
    field :analysis_type, :string
    field :status, :string, default: "queued"
    field :model_used, :string
    field :input_data, :map, default: %{}
    field :result, :map, default: %{}
    field :confidence_score, :float
    field :trainer_review, :string
    field :reviewed_at, :utc_datetime
    field :visible_to_student, :boolean, default: false
    field :tokens_used, :integer
    field :processing_time_ms, :integer

    belongs_to :student, GaPersonal.Accounts.User
    belongs_to :trainer, GaPersonal.Accounts.User
    belongs_to :media_file, GaPersonal.Media.MediaFile

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(record, attrs) do
    record
    |> cast(attrs, [
      :analysis_type, :status, :model_used, :input_data, :result,
      :confidence_score, :trainer_review, :reviewed_at, :visible_to_student,
      :tokens_used, :processing_time_ms,
      :student_id, :trainer_id, :media_file_id
    ])
    |> validate_required([:analysis_type, :student_id, :trainer_id])
    |> validate_inclusion(:analysis_type, @analysis_types)
    |> validate_inclusion(:status, @statuses)
    |> validate_number(:confidence_score, greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0)
    |> foreign_key_constraint(:student_id)
    |> foreign_key_constraint(:trainer_id)
    |> foreign_key_constraint(:media_file_id)
  end

  def result_changeset(record, attrs) do
    record
    |> cast(attrs, [:status, :result, :confidence_score, :model_used, :tokens_used, :processing_time_ms])
    |> validate_required([:status, :result])
  end

  def review_changeset(record, attrs) do
    record
    |> cast(attrs, [:trainer_review, :reviewed_at, :status])
    |> put_change(:status, "reviewed")
    |> validate_required([:reviewed_at])
  end

  def analysis_types, do: @analysis_types
end
