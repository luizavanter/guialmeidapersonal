defmodule GaPersonal.Bioimpedance.BioimpedanceImport do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @device_types ~w(anovator relaxmedic inbody tanita omron other)
  @statuses ~w(pending_extraction extracting extracted reviewed applied rejected failed)

  schema "bioimpedance_imports" do
    field :device_type, :string
    field :status, :string, default: "pending_extraction"
    field :extracted_data, :map, default: %{}
    field :confidence_score, :float
    field :trainer_notes, :string
    field :applied_at, :utc_datetime

    belongs_to :media_file, GaPersonal.Media.MediaFile
    belongs_to :student, GaPersonal.Accounts.User
    belongs_to :trainer, GaPersonal.Accounts.User
    belongs_to :body_assessment, GaPersonal.Evolution.BodyAssessment

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(import_record, attrs) do
    import_record
    |> cast(attrs, [
      :device_type,
      :status,
      :extracted_data,
      :confidence_score,
      :trainer_notes,
      :applied_at,
      :media_file_id,
      :student_id,
      :trainer_id,
      :body_assessment_id
    ])
    |> validate_required([:device_type, :media_file_id, :student_id, :trainer_id])
    |> validate_inclusion(:device_type, @device_types)
    |> validate_inclusion(:status, @statuses)
    |> validate_number(:confidence_score, greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0)
    |> foreign_key_constraint(:media_file_id)
    |> foreign_key_constraint(:student_id)
    |> foreign_key_constraint(:trainer_id)
    |> foreign_key_constraint(:body_assessment_id)
  end

  def extraction_changeset(import_record, attrs) do
    import_record
    |> cast(attrs, [:status, :extracted_data, :confidence_score])
    |> validate_required([:status, :extracted_data])
  end

  def review_changeset(import_record, attrs) do
    import_record
    |> cast(attrs, [:status, :extracted_data, :trainer_notes])
    |> validate_required([:status])
  end

  def apply_changeset(import_record, attrs) do
    import_record
    |> cast(attrs, [:status, :applied_at, :body_assessment_id])
    |> validate_required([:status, :applied_at, :body_assessment_id])
  end

  def device_types, do: @device_types
end
