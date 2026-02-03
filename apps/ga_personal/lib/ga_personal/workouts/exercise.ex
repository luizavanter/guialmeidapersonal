defmodule GaPersonal.Workouts.Exercise do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "exercises" do
    field :name, :string
    field :description, :string
    field :category, :string
    field :muscle_groups, {:array, :string}, default: []
    field :equipment_needed, {:array, :string}, default: []
    field :difficulty_level, :string
    field :video_url, :string
    field :thumbnail_url, :string
    field :instructions, :string
    field :is_public, :boolean, default: false

    belongs_to :trainer, GaPersonal.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(exercise, attrs) do
    exercise
    |> cast(attrs, [
      :trainer_id,
      :name,
      :description,
      :category,
      :muscle_groups,
      :equipment_needed,
      :difficulty_level,
      :video_url,
      :thumbnail_url,
      :instructions,
      :is_public
    ])
    |> validate_required([:name])
    |> validate_inclusion(:category, ["strength", "cardio", "flexibility", "balance"])
    |> validate_inclusion(:difficulty_level, ["beginner", "intermediate", "advanced"])
  end
end
