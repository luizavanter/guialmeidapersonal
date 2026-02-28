defmodule GaPersonal.Media.MediaFile do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @file_types ~w(evolution_photo medical_document bioimpedance_report)
  @upload_statuses ~w(pending confirmed failed)

  schema "media_files" do
    field :file_type, :string
    field :gcs_path, :string
    field :original_filename, :string
    field :content_type, :string
    field :file_size_bytes, :integer
    field :metadata, :map, default: %{}
    field :encrypted, :boolean, default: true
    field :upload_status, :string, default: "pending"
    field :deleted_at, :utc_datetime

    belongs_to :student, GaPersonal.Accounts.User
    belongs_to :uploaded_by, GaPersonal.Accounts.User
    belongs_to :trainer, GaPersonal.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(media_file, attrs) do
    media_file
    |> cast(attrs, [
      :file_type,
      :gcs_path,
      :original_filename,
      :content_type,
      :file_size_bytes,
      :metadata,
      :encrypted,
      :upload_status,
      :deleted_at,
      :student_id,
      :uploaded_by_id,
      :trainer_id
    ])
    |> validate_required([:file_type, :gcs_path, :original_filename, :content_type, :student_id, :uploaded_by_id, :trainer_id])
    |> validate_inclusion(:file_type, @file_types)
    |> validate_inclusion(:upload_status, @upload_statuses)
    |> validate_format(:content_type, ~r/^(image|application)\/.+$/)
    |> validate_number(:file_size_bytes, greater_than: 0)
    |> foreign_key_constraint(:student_id)
    |> foreign_key_constraint(:uploaded_by_id)
    |> foreign_key_constraint(:trainer_id)
  end

  def confirm_changeset(media_file, attrs) do
    media_file
    |> cast(attrs, [:upload_status, :file_size_bytes, :metadata])
    |> put_change(:upload_status, "confirmed")
  end

  def not_deleted(query \\ __MODULE__) do
    from m in query, where: is_nil(m.deleted_at)
  end

  def file_types, do: @file_types
end
