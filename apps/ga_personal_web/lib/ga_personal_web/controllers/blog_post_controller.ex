defmodule GaPersonalWeb.BlogPostController do
  use GaPersonalWeb, :controller

  alias GaPersonal.Content
  alias GaPersonal.Guardian

  action_fallback GaPersonalWeb.FallbackController

  def index(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    blog_posts = Content.list_blog_posts(user.id, params)
    json(conn, %{data: Enum.map(blog_posts, &blog_post_json/1)})
  end

  def show(conn, %{"id" => id}) do
    blog_post = Content.get_blog_post!(id)
    json(conn, %{data: blog_post_json(blog_post)})
  end

  def create(conn, %{"blog_post" => blog_post_params}) do
    user = Guardian.Plug.current_resource(conn)
    params = Map.put(blog_post_params, "trainer_id", user.id)

    with {:ok, blog_post} <- Content.create_blog_post(params) do
      conn
      |> put_status(:created)
      |> json(%{data: blog_post_json(blog_post)})
    end
  end

  def update(conn, %{"id" => id, "blog_post" => blog_post_params}) do
    blog_post = Content.get_blog_post!(id)

    with {:ok, updated} <- Content.update_blog_post(blog_post, blog_post_params) do
      json(conn, %{data: blog_post_json(updated)})
    end
  end

  def delete(conn, %{"id" => id}) do
    blog_post = Content.get_blog_post!(id)

    with {:ok, _} <- Content.delete_blog_post(blog_post) do
      send_resp(conn, :no_content, "")
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
