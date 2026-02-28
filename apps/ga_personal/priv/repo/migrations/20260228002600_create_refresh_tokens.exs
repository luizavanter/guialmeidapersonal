defmodule GaPersonal.Repo.Migrations.CreateRefreshTokens do
  use Ecto.Migration

  def change do
    create table(:refresh_tokens, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :token_hash, :string, null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :expires_at, :utc_datetime, null: false
      add :revoked_at, :utc_datetime

      timestamps()
    end

    create index(:refresh_tokens, [:token_hash], unique: true)
    create index(:refresh_tokens, [:user_id])
    create index(:refresh_tokens, [:expires_at])
  end
end
