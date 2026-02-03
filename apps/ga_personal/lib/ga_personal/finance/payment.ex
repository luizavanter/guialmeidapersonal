defmodule GaPersonal.Finance.Payment do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "payments" do
    field :amount_cents, :integer
    field :currency, :string, default: "BRL"
    field :status, :string, default: "pending"
    field :payment_method, :string
    field :payment_date, :date
    field :due_date, :date
    field :reference_number, :string
    field :notes, :string

    belongs_to :student, GaPersonal.Accounts.User
    belongs_to :trainer, GaPersonal.Accounts.User
    belongs_to :subscription, GaPersonal.Finance.Subscription

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(payment, attrs) do
    payment
    |> cast(attrs, [
      :student_id,
      :trainer_id,
      :subscription_id,
      :amount_cents,
      :currency,
      :status,
      :payment_method,
      :payment_date,
      :due_date,
      :reference_number,
      :notes
    ])
    |> validate_required([:student_id, :trainer_id, :amount_cents])
    |> validate_inclusion(:status, ["pending", "completed", "failed", "refunded"])
    |> validate_inclusion(:payment_method, ["cash", "pix", "credit_card", "debit_card", "bank_transfer"])
    |> validate_number(:amount_cents, greater_than: 0)
    |> foreign_key_constraint(:student_id)
    |> foreign_key_constraint(:trainer_id)
    |> foreign_key_constraint(:subscription_id)
  end
end
