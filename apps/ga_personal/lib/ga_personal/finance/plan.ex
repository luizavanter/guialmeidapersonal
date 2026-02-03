defmodule GaPersonal.Finance.Plan do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "plans" do
    field :name, :string
    field :description, :string
    field :price_cents, :integer
    field :currency, :string, default: "BRL"
    field :billing_period, :string
    field :sessions_included, :integer
    field :features, {:array, :string}, default: []
    field :is_active, :boolean, default: true
    field :is_public, :boolean, default: true

    belongs_to :trainer, GaPersonal.Accounts.User
    has_many :subscriptions, GaPersonal.Finance.Subscription

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(plan, attrs) do
    plan
    |> cast(attrs, [
      :trainer_id,
      :name,
      :description,
      :price_cents,
      :currency,
      :billing_period,
      :sessions_included,
      :features,
      :is_active,
      :is_public
    ])
    |> validate_required([:trainer_id, :name, :price_cents, :billing_period])
    |> validate_inclusion(:billing_period, ["weekly", "monthly", "quarterly", "yearly", "one_time"])
    |> validate_number(:price_cents, greater_than: 0)
    |> foreign_key_constraint(:trainer_id)
  end
end
