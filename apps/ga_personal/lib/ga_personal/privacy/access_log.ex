defmodule GaPersonal.Privacy.AccessLog do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @actions ~w(view download delete ai_analyze upload)

  schema "access_logs" do
    field :action, :string
    field :resource_type, :string
    field :resource_id, :binary_id
    field :ip_address, :string
    field :user_agent, :string
    field :metadata, :map, default: %{}

    belongs_to :user, GaPersonal.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(access_log, attrs) do
    access_log
    |> cast(attrs, [:action, :resource_type, :resource_id, :ip_address, :user_agent, :metadata, :user_id])
    |> validate_required([:action, :resource_type, :user_id])
    |> validate_inclusion(:action, @actions)
    |> foreign_key_constraint(:user_id)
  end
end
