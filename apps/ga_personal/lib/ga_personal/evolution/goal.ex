defmodule GaPersonal.Evolution.Goal do
  use Ecto.Schema
  import Ecto.Changeset
  alias GaPersonal.Sanitizer

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "goals" do
    field :goal_type, :string
    field :title, :string
    field :description, :string
    field :target_value, :decimal
    field :current_value, :decimal
    field :unit, :string
    field :start_date, :date
    field :target_date, :date
    field :status, :string, default: "active"
    field :achieved_at, :date

    belongs_to :student, GaPersonal.Accounts.User
    belongs_to :trainer, GaPersonal.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(goal, attrs) do
    goal
    |> cast(attrs, [
      :student_id,
      :trainer_id,
      :goal_type,
      :title,
      :description,
      :target_value,
      :current_value,
      :unit,
      :start_date,
      :target_date,
      :status,
      :achieved_at
    ])
    |> Sanitizer.sanitize_changeset([:title, :description, :unit])
    |> validate_required([:student_id, :trainer_id, :goal_type, :title, :start_date])
    |> validate_length(:title, max: 255)
    |> validate_length(:description, max: 2000)
    |> validate_length(:unit, max: 20)
    |> validate_inclusion(:goal_type, ["weight_loss", "muscle_gain", "strength", "endurance", "flexibility", "custom"])
    |> validate_inclusion(:status, ["active", "achieved", "abandoned"])
    |> foreign_key_constraint(:student_id)
    |> foreign_key_constraint(:trainer_id)
  end
end
