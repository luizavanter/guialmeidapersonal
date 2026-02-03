defmodule GaPersonal.Finance.Subscription do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "subscriptions" do
    field :status, :string, default: "active"
    field :start_date, :date
    field :end_date, :date
    field :next_billing_date, :date
    field :sessions_remaining, :integer
    field :auto_renew, :boolean, default: true
    field :cancellation_reason, :string
    field :cancelled_at, :utc_datetime

    belongs_to :student, GaPersonal.Accounts.User
    belongs_to :plan, GaPersonal.Finance.Plan
    belongs_to :trainer, GaPersonal.Accounts.User
    has_many :payments, GaPersonal.Finance.Payment

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(subscription, attrs) do
    subscription
    |> cast(attrs, [
      :student_id,
      :plan_id,
      :trainer_id,
      :status,
      :start_date,
      :end_date,
      :next_billing_date,
      :sessions_remaining,
      :auto_renew,
      :cancellation_reason
    ])
    |> validate_required([:student_id, :plan_id, :trainer_id, :start_date])
    |> validate_inclusion(:status, ["active", "paused", "cancelled", "expired"])
    |> foreign_key_constraint(:student_id)
    |> foreign_key_constraint(:plan_id)
    |> foreign_key_constraint(:trainer_id)
  end
end
