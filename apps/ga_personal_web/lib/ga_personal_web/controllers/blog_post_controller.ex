defmodule GaPersonalWeb.BlogPostController do
  use GaPersonalWeb, :controller

  alias GaPersonal.Content

  action_fallback GaPersonalWeb.FallbackController

  def index(conn, params) do
    trainer_id = conn.assigns.current_user_id
    blog_posts = Content.list_blog_posts(trainer_id, params)
    json(conn, %{data: Enum.map(blog_posts, &blog_post_json/1)})
  end

  def show(conn, %{"id" => id}) do
    trainer_id = conn.assigns.current_user_id

    case Content.get_blog_post_for_trainer(id, trainer_id) do
      {:ok, blog_post} ->
        json(conn, %{data: blog_post_json(blog_post)})

      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :unauthorized} ->
        {:error, :forbidden}
    end
  end

  def create(conn, %{"blog_post" => blog_post_params}) do
    trainer_id = conn.assigns.current_user_id
    params = Map.put(blog_post_params, "trainer_id", trainer_id)

    with {:ok, blog_post} <- Content.create_blog_post(params) do
      conn
      |> put_status(:created)
      |> json(%{data: blog_post_json(blog_post)})
    end
  end

  def update(conn, %{"id" => id, "blog_post" => blog_post_params}) do
    trainer_id = conn.assigns.current_user_id

    case Content.get_blog_post_for_trainer(id, trainer_id) do
      {:ok, blog_post} ->
        with {:ok, updated} <- Content.update_blog_post(blog_post, blog_post_params) do
          json(conn, %{data: blog_post_json(updated)})
        end

      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :unauthorized} ->
        {:error, :forbidden}
    end
  end

  def delete(conn, %{"id" => id}) do
    trainer_id = conn.assigns.current_user_id

    case Content.get_blog_post_for_trainer(id, trainer_id) do
      {:ok, blog_post} ->
        with {:ok, _} <- Content.delete_blog_post(blog_post) do
          send_resp(conn, :no_content, "")
        end

      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :unauthorized} ->
        {:error, :forbidden}
    end
  end

  defp blog_post_json(blog_post) do
    %{
      id: blog_post.id,
      trainer_id: blog_post.trainer_id,
      title: blog_post.title,
      slug: blog_post.slug,
      excerpt: blog_post.excerpt,
      content: blog_post.content,
      featured_image_url: blog_post.featured_image_url,
      status: blog_post.status,
      tags: blog_post.tags,
      published_at: blog_post.published_at,
      inserted_at: blog_post.inserted_at,
      updated_at: blog_post.updated_at
    }
  end
end
