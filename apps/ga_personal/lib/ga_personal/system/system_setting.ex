defmodule GaPersonal.System.SystemSetting do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "system_settings" do
    field :key, :string
    field :value, :string
    field :value_type, :string
    field :category, :string
    field :description, :string

    belongs_to :trainer, GaPersonal.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(system_setting, attrs) do
    system_setting
    |> cast(attrs, [:trainer_id, :key, :value, :value_type, :category, :description])
    |> validate_required([:trainer_id, :key])
    |> validate_inclusion(:value_type, ["string", "integer", "boolean", "json"])
    |> unique_constraint([:trainer_id, :key])
    |> foreign_key_constraint(:trainer_id)
  end
end
