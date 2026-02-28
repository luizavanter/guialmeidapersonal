defmodule GaPersonal.Content.FAQ do
  use Ecto.Schema
  import Ecto.Changeset
  alias GaPersonal.Sanitizer

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "faqs" do
    field :question, :string
    field :answer, :string
    field :category, :string
    field :display_order, :integer, default: 0
    field :is_published, :boolean, default: true

    belongs_to :trainer, GaPersonal.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(faq, attrs) do
    faq
    |> cast(attrs, [:trainer_id, :question, :answer, :category, :display_order, :is_published])
    |> Sanitizer.sanitize_changeset([:question, :answer, :category])
    |> validate_required([:trainer_id, :question, :answer])
    |> validate_length(:question, max: 500)
    |> validate_length(:answer, max: 5000)
    |> validate_length(:category, max: 100)
    |> foreign_key_constraint(:trainer_id)
  end
end
