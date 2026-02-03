defmodule GaPersonal.Content.BlogPost do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "blog_posts" do
    field :title, :string
    field :slug, :string
    field :content, :string
    field :excerpt, :string
    field :featured_image_url, :string
    field :status, :string, default: "draft"
    field :published_at, :utc_datetime
    field :tags, {:array, :string}, default: []
    field :view_count, :integer, default: 0

    belongs_to :trainer, GaPersonal.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(blog_post, attrs) do
    blog_post
    |> cast(attrs, [:trainer_id, :title, :slug, :content, :excerpt, :featured_image_url, :status, :published_at, :tags])
    |> validate_required([:trainer_id, :title, :slug, :content])
    |> validate_inclusion(:status, ["draft", "published", "archived"])
    |> unique_constraint(:slug)
    |> foreign_key_constraint(:trainer_id)
  end
end
