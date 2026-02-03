defmodule GaPersonal.Evolution.BodyAssessment do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "body_assessments" do
    field :assessment_date, :date
    field :weight_kg, :decimal
    field :height_cm, :decimal
    field :body_fat_percentage, :decimal
    field :muscle_mass_kg, :decimal
    field :bmi, :decimal
    field :neck_cm, :decimal
    field :chest_cm, :decimal
    field :waist_cm, :decimal
    field :hips_cm, :decimal
    field :right_arm_cm, :decimal
    field :left_arm_cm, :decimal
    field :right_thigh_cm, :decimal
    field :left_thigh_cm, :decimal
    field :right_calf_cm, :decimal
    field :left_calf_cm, :decimal
    field :resting_heart_rate, :integer
    field :blood_pressure_systolic, :integer
    field :blood_pressure_diastolic, :integer
    field :notes, :string

    belongs_to :student, GaPersonal.Accounts.User
    belongs_to :trainer, GaPersonal.Accounts.User
    has_many :evolution_photos, GaPersonal.Evolution.EvolutionPhoto

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(body_assessment, attrs) do
    body_assessment
    |> cast(attrs, [
      :student_id,
      :trainer_id,
      :assessment_date,
      :weight_kg,
      :height_cm,
      :body_fat_percentage,
      :muscle_mass_kg,
      :bmi,
      :neck_cm,
      :chest_cm,
      :waist_cm,
      :hips_cm,
      :right_arm_cm,
      :left_arm_cm,
      :right_thigh_cm,
      :left_thigh_cm,
      :right_calf_cm,
      :left_calf_cm,
      :resting_heart_rate,
      :blood_pressure_systolic,
      :blood_pressure_diastolic,
      :notes
    ])
    |> validate_required([:student_id, :trainer_id, :assessment_date])
    |> foreign_key_constraint(:student_id)
    |> foreign_key_constraint(:trainer_id)
  end
end
