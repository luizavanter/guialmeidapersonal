defmodule GaPersonal.Schedule.TimeSlot do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "time_slots" do
    field :day_of_week, :integer
    field :start_time, :time
    field :end_time, :time
    field :slot_duration_minutes, :integer, default: 60
    field :is_available, :boolean, default: true

    belongs_to :trainer, GaPersonal.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(time_slot, attrs) do
    time_slot
    |> cast(attrs, [:trainer_id, :day_of_week, :start_time, :end_time, :slot_duration_minutes, :is_available])
    |> validate_required([:trainer_id, :day_of_week, :start_time, :end_time])
    |> validate_inclusion(:day_of_week, 0..6)
    |> validate_number(:slot_duration_minutes, greater_than: 0)
    |> foreign_key_constraint(:trainer_id)
  end
end
