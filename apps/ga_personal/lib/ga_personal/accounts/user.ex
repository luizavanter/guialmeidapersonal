defmodule GaPersonal.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias GaPersonal.Sanitizer

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    field :role, :string
    field :full_name, :string
    field :phone, :string
    field :locale, :string, default: "pt_BR"
    field :active, :boolean, default: true
    field :last_login_at, :utc_datetime

    has_one :student_profile, GaPersonal.Accounts.StudentProfile
    has_many :trained_students, GaPersonal.Accounts.StudentProfile, foreign_key: :trainer_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password, :role, :full_name, :phone, :locale, :active])
    |> validate_required([:email, :role, :full_name])
    |> Sanitizer.sanitize_changeset([:full_name, :phone])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email")
    |> validate_length(:full_name, max: 255)
    |> validate_length(:email, max: 255)
    |> validate_length(:phone, max: 30)
    |> validate_inclusion(:role, ["trainer", "student", "admin"])
    |> validate_inclusion(:locale, ["pt_BR", "en_US"])
    |> unique_constraint(:email)
    |> put_password_hash()
  end

  defp put_password_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    change(changeset, password_hash: Bcrypt.hash_pwd_salt(password))
  end

  defp put_password_hash(changeset), do: changeset

  def verify_password(user, password) do
    Bcrypt.verify_pass(password, user.password_hash)
  end
end
