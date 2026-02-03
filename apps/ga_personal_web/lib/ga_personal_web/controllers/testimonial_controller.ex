defmodule GaPersonalWeb.TestimonialController do
  use GaPersonalWeb, :controller

  alias GaPersonal.Content
  alias GaPersonal.Content.Testimonial
  alias GaPersonal.Repo
  alias GaPersonal.Guardian

  action_fallback GaPersonalWeb.FallbackController

  def index(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    testimonials = Content.list_testimonials(user.id, params)
    json(conn, %{data: Enum.map(testimonials, &testimonial_json/1)})
  end

  def show(conn, %{"id" => id}) do
    testimonial = Repo.get!(Testimonial, id)
    json(conn, %{data: testimonial_json(testimonial)})
  end

  def create(conn, %{"testimonial" => testimonial_params}) do
    user = Guardian.Plug.current_resource(conn)
    params = Map.put(testimonial_params, "trainer_id", user.id)

    with {:ok, testimonial} <- Content.create_testimonial(params) do
      conn
      |> put_status(:created)
      |> json(%{data: testimonial_json(testimonial)})
    end
  end

  def update(conn, %{"id" => id, "testimonial" => testimonial_params}) do
    testimonial = Repo.get!(Testimonial, id)

    with {:ok, updated} <- Content.update_testimonial(testimonial, testimonial_params) do
      json(conn, %{data: testimonial_json(updated)})
    end
  end

  def delete(conn, %{"id" => id}) do
    testimonial = Repo.get!(Testimonial, id)

    with {:ok, _} <- Repo.delete(testimonial) do
      send_resp(conn, :no_content, "")
    end
  end

  defp testimonial_json(testimonial) do
    %{
      id: testimonial.id,
      trainer_id: testimonial.trainer_id,
      student_id: testimonial.student_id,
      student_name: testimonial.student_name,
      content: testimonial.content,
      rating: testimonial.rating,
      photo_url: testimonial.photo_url,
      is_approved: testimonial.is_approved,
      is_featured: testimonial.is_featured,
      approved_at: testimonial.approved_at,
      inserted_at: testimonial.inserted_at,
      updated_at: testimonial.updated_at
    }
  end
end
