defmodule GaPersonal.Schedule.Appointment do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "appointments" do
    field :scheduled_at, :utc_datetime
    field :duration_minutes, :integer, default: 60
    field :status, :string, default: "scheduled"
    field :appointment_type, :string
    field :location, :string
    field :notes, :string
    field :cancellation_reason, :string
    field :cancelled_at, :utc_datetime

    belongs_to :trainer, GaPersonal.Accounts.User
    belongs_to :student, GaPersonal.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(appointment, attrs) do
    appointment
    |> cast(attrs, [
      :trainer_id,
      :student_id,
      :scheduled_at,
      :duration_minutes,
      :status,
      :appointment_type,
      :location,
      :notes,
      :cancellation_reason
    ])
    |> validate_required([:trainer_id, :student_id, :scheduled_at])
    |> validate_inclusion(:status, ["scheduled", "completed", "cancelled", "no_show"])
    |> foreign_key_constraint(:trainer_id)
    |> foreign_key_constraint(:student_id)
  end
end
