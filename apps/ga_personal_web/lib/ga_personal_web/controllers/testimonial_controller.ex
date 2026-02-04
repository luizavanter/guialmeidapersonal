defmodule GaPersonalWeb.TestimonialController do
  use GaPersonalWeb, :controller

  alias GaPersonal.Content

  action_fallback GaPersonalWeb.FallbackController

  def index(conn, params) do
    trainer_id = conn.assigns.current_user_id
    testimonials = Content.list_testimonials(trainer_id, params)
    json(conn, %{data: Enum.map(testimonials, &testimonial_json/1)})
  end

  def show(conn, %{"id" => id}) do
    trainer_id = conn.assigns.current_user_id

    case Content.get_testimonial_for_trainer(id, trainer_id) do
      {:ok, testimonial} ->
        json(conn, %{data: testimonial_json(testimonial)})

      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :unauthorized} ->
        {:error, :forbidden}
    end
  end

  def create(conn, %{"testimonial" => testimonial_params}) do
    trainer_id = conn.assigns.current_user_id
    params = Map.put(testimonial_params, "trainer_id", trainer_id)

    with {:ok, testimonial} <- Content.create_testimonial(params) do
      conn
      |> put_status(:created)
      |> json(%{data: testimonial_json(testimonial)})
    end
  end

  def update(conn, %{"id" => id, "testimonial" => testimonial_params}) do
    trainer_id = conn.assigns.current_user_id

    case Content.get_testimonial_for_trainer(id, trainer_id) do
      {:ok, testimonial} ->
        with {:ok, updated} <- Content.update_testimonial(testimonial, testimonial_params) do
          json(conn, %{data: testimonial_json(updated)})
        end

      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :unauthorized} ->
        {:error, :forbidden}
    end
  end

  def delete(conn, %{"id" => id}) do
    trainer_id = conn.assigns.current_user_id

    case Content.get_testimonial_for_trainer(id, trainer_id) do
      {:ok, testimonial} ->
        with {:ok, _} <- Content.delete_testimonial(testimonial) do
          send_resp(conn, :no_content, "")
        end

      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :unauthorized} ->
        {:error, :forbidden}
    end
  end

  defp testimonial_json(testimonial) do
    %{
      id: testimonial.id,
      trainer_id: testimonial.trainer_id,
      student_id: testimonial.student_id,
      author_name: testimonial.author_name,
      content: testimonial.content,
      rating: testimonial.rating,
      author_photo_url: testimonial.author_photo_url,
      is_approved: testimonial.is_approved,
      is_featured: testimonial.is_featured,
      approved_at: testimonial.approved_at,
      inserted_at: testimonial.inserted_at,
      updated_at: testimonial.updated_at
    }
  end
end
