defmodule GaPersonal.Messaging.Message do
  use Ecto.Schema
  import Ecto.Changeset
  alias GaPersonal.Sanitizer

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "messages" do
    field :subject, :string
    field :body, :string
    field :is_read, :boolean, default: false
    field :read_at, :utc_datetime

    belongs_to :sender, GaPersonal.Accounts.User
    belongs_to :recipient, GaPersonal.Accounts.User
    belongs_to :parent_message, GaPersonal.Messaging.Message

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:sender_id, :recipient_id, :subject, :body, :parent_message_id, :is_read])
    |> Sanitizer.sanitize_changeset([:subject, :body])
    |> validate_required([:sender_id, :recipient_id, :body])
    |> validate_length(:subject, max: 255)
    |> validate_length(:body, max: 10_000)
    |> foreign_key_constraint(:sender_id)
    |> foreign_key_constraint(:recipient_id)
  end
end
