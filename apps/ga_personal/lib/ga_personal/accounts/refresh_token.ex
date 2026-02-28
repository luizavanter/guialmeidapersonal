defmodule GaPersonal.Accounts.RefreshToken do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @token_bytes 64
  @token_ttl_days 30

  schema "refresh_tokens" do
    field :token_hash, :string
    field :expires_at, :utc_datetime
    field :revoked_at, :utc_datetime

    belongs_to :user, GaPersonal.Accounts.User

    timestamps()
  end

  def changeset(refresh_token, attrs) do
    refresh_token
    |> cast(attrs, [:token_hash, :user_id, :expires_at, :revoked_at])
    |> validate_required([:token_hash, :user_id, :expires_at])
    |> unique_constraint(:token_hash)
    |> foreign_key_constraint(:user_id)
  end

  def generate_token do
    :crypto.strong_rand_bytes(@token_bytes) |> Base.url_encode64(padding: false)
  end

  def hash_token(token) do
    :crypto.hash(:sha256, token) |> Base.encode16(case: :lower)
  end

  def default_expiry do
    DateTime.utc_now()
    |> DateTime.add(@token_ttl_days * 24 * 60 * 60, :second)
    |> DateTime.truncate(:second)
  end

  def expired?(%__MODULE__{expires_at: expires_at}) do
    DateTime.compare(DateTime.utc_now(), expires_at) == :gt
  end

  def revoked?(%__MODULE__{revoked_at: nil}), do: false
  def revoked?(%__MODULE__{}), do: true
end
