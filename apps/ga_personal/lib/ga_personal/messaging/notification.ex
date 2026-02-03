defmodule GaPersonal.Messaging.Notification do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "notifications" do
    field :type, :string
    field :title, :string
    field :body, :string
    field :action_url, :string
    field :is_read, :boolean, default: false
    field :read_at, :utc_datetime
    field :sent_at, :utc_datetime
    field :delivery_method, :string

    belongs_to :user, GaPersonal.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:user_id, :type, :title, :body, :action_url, :delivery_method, :is_read, :sent_at])
    |> validate_required([:user_id, :type, :title, :body])
    |> validate_inclusion(:delivery_method, ["in_app", "email", "sms", "push"])
    |> foreign_key_constraint(:user_id)
  end
end
