defmodule GaPersonal.Content do
  @moduledoc """
  The Content context - handles blog posts, testimonials, and FAQs.
  """

  import Ecto.Query, warn: false
  alias GaPersonal.Repo
  alias GaPersonal.Content.{BlogPost, Testimonial, FAQ}

  ## BlogPost functions

  def list_blog_posts(trainer_id, filters \\ %{}) do
    query = from bp in BlogPost,
      where: bp.trainer_id == ^trainer_id,
      order_by: [desc: bp.published_at]

    query
    |> apply_blog_filters(filters)
    |> Repo.all()
  end

  defp apply_blog_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {:status, status}, query ->
        from bp in query, where: bp.status == ^status

      {:tag, tag}, query ->
        from bp in query, where: ^tag in bp.tags

      _, query ->
        query
    end)
  end

  def get_blog_post!(id), do: Repo.get!(BlogPost, id)

  def get_blog_post_by_slug!(slug), do: Repo.get_by!(BlogPost, slug: slug)

  def create_blog_post(attrs \\ %{}) do
    %BlogPost{}
    |> BlogPost.changeset(attrs)
    |> Repo.insert()
  end

  def update_blog_post(%BlogPost{} = blog_post, attrs) do
    blog_post
    |> BlogPost.changeset(attrs)
    |> Repo.update()
  end

  def delete_blog_post(%BlogPost{} = blog_post) do
    Repo.delete(blog_post)
  end

  ## Testimonial functions

  def list_testimonials(trainer_id, filters \\ %{}) do
    query = from t in Testimonial,
      where: t.trainer_id == ^trainer_id,
      order_by: [desc: t.inserted_at]

    query
    |> apply_testimonial_filters(filters)
    |> Repo.all()
  end

  defp apply_testimonial_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {:is_approved, is_approved}, query ->
        from t in query, where: t.is_approved == ^is_approved

      {:is_featured, is_featured}, query ->
        from t in query, where: t.is_featured == ^is_featured

      _, query ->
        query
    end)
  end

  def create_testimonial(attrs \\ %{}) do
    %Testimonial{}
    |> Testimonial.changeset(attrs)
    |> Repo.insert()
  end

  def update_testimonial(%Testimonial{} = testimonial, attrs) do
    testimonial
    |> Testimonial.changeset(attrs)
    |> Repo.update()
  end

  def approve_testimonial(%Testimonial{} = testimonial) do
    update_testimonial(testimonial, %{is_approved: true, approved_at: DateTime.utc_now()})
  end

  ## FAQ functions

  def list_faqs(trainer_id, filters \\ %{}) do
    query = from f in FAQ,
      where: f.trainer_id == ^trainer_id,
      order_by: [f.display_order, f.inserted_at]

    query
    |> apply_faq_filters(filters)
    |> Repo.all()
  end

  defp apply_faq_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {:category, category}, query ->
        from f in query, where: f.category == ^category

      {:is_published, is_published}, query ->
        from f in query, where: f.is_published == ^is_published

      _, query ->
        query
    end)
  end

  def create_faq(attrs \\ %{}) do
    %FAQ{}
    |> FAQ.changeset(attrs)
    |> Repo.insert()
  end

  def update_faq(%FAQ{} = faq, attrs) do
    faq
    |> FAQ.changeset(attrs)
    |> Repo.update()
  end

  def delete_faq(%FAQ{} = faq) do
    Repo.delete(faq)
  end
end
