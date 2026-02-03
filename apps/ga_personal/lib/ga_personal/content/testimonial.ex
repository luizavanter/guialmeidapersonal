defmodule GaPersonal.Content.Testimonial do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "testimonials" do
    field :author_name, :string
    field :author_photo_url, :string
    field :content, :string
    field :rating, :integer
    field :is_featured, :boolean, default: false
    field :is_approved, :boolean, default: false
    field :approved_at, :utc_datetime

    belongs_to :trainer, GaPersonal.Accounts.User
    belongs_to :student, GaPersonal.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(testimonial, attrs) do
    testimonial
    |> cast(attrs, [:trainer_id, :student_id, :author_name, :author_photo_url, :content, :rating, :is_featured, :is_approved])
    |> validate_required([:trainer_id, :author_name, :content])
    |> validate_inclusion(:rating, 1..5)
    |> foreign_key_constraint(:trainer_id)
    |> foreign_key_constraint(:student_id)
  end
end
