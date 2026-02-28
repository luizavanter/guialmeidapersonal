defmodule GaPersonal.Privacy.ConsentRecord do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @consent_types ~w(media_upload ai_analysis data_retention)

  schema "consent_records" do
    field :consent_type, :string
    field :granted, :boolean
    field :granted_at, :utc_datetime
    field :revoked_at, :utc_datetime
    field :ip_address, :string
    field :user_agent, :string

    belongs_to :user, GaPersonal.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(consent_record, attrs) do
    consent_record
    |> cast(attrs, [:consent_type, :granted, :granted_at, :revoked_at, :ip_address, :user_agent, :user_id])
    |> validate_required([:consent_type, :granted, :user_id])
    |> validate_inclusion(:consent_type, @consent_types)
    |> foreign_key_constraint(:user_id)
  end

  def consent_types, do: @consent_types
end
