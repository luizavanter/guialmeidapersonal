defmodule GaPersonal.Evolution.EvolutionPhoto do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "evolution_photos" do
    field :photo_url, :string
    field :photo_type, :string
    field :taken_at, :date
    field :notes, :string

    belongs_to :student, GaPersonal.Accounts.User
    belongs_to :body_assessment, GaPersonal.Evolution.BodyAssessment

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(evolution_photo, attrs) do
    evolution_photo
    |> cast(attrs, [:student_id, :body_assessment_id, :photo_url, :photo_type, :taken_at, :notes])
    |> validate_required([:student_id, :photo_url, :photo_type, :taken_at])
    |> validate_inclusion(:photo_type, ["front", "back", "side", "other"])
    |> foreign_key_constraint(:student_id)
    |> foreign_key_constraint(:body_assessment_id)
  end
end
