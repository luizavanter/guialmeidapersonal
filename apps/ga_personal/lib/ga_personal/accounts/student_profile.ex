defmodule GaPersonal.Accounts.StudentProfile do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "student_profiles" do
    field :date_of_birth, :date
    field :gender, :string
    field :emergency_contact_name, :string
    field :emergency_contact_phone, :string
    field :medical_conditions, :string
    field :goals_description, :string
    field :notes, :string
    field :status, :string, default: "active"

    belongs_to :user, GaPersonal.Accounts.User
    belongs_to :trainer, GaPersonal.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(student_profile, attrs) do
    student_profile
    |> cast(attrs, [
      :user_id,
      :trainer_id,
      :date_of_birth,
      :gender,
      :emergency_contact_name,
      :emergency_contact_phone,
      :medical_conditions,
      :goals_description,
      :notes,
      :status
    ])
    |> validate_required([:user_id, :trainer_id])
    |> validate_inclusion(:status, ["active", "paused", "cancelled"])
    |> unique_constraint(:user_id)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:trainer_id)
  end
end
