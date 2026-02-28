defmodule GaPersonalWeb.EvolutionPhotoController do
  use GaPersonalWeb, :controller

  alias GaPersonal.{Accounts, Evolution}

  action_fallback GaPersonalWeb.FallbackController

  def index_for_student(conn, _params) do
    user = conn.assigns.current_user

    photos = Evolution.list_evolution_photos(user.id)
    json(conn, %{data: Enum.map(photos, &photo_json/1)})
  end

  defp photo_json(photo) do
    %{
      id: photo.id,
      student_id: photo.student_id,
      photo_url: photo.photo_url,
      photo_type: photo.photo_type,
      taken_at: photo.taken_at,
      notes: photo.notes,
      inserted_at: photo.inserted_at,
      updated_at: photo.updated_at
    }
  end
end
