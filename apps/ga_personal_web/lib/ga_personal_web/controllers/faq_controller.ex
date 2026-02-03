defmodule GaPersonalWeb.FAQController do
  use GaPersonalWeb, :controller

  alias GaPersonal.Content
  alias GaPersonal.Content.FAQ
  alias GaPersonal.Repo
  alias GaPersonal.Guardian

  action_fallback GaPersonalWeb.FallbackController

  def index(conn, params) do
    user = Guardian.Plug.current_resource(conn)
    faqs = Content.list_faqs(user.id, params)
    json(conn, %{data: Enum.map(faqs, &faq_json/1)})
  end

  def show(conn, %{"id" => id}) do
    faq = Repo.get!(FAQ, id)
    json(conn, %{data: faq_json(faq)})
  end

  def create(conn, %{"faq" => faq_params}) do
    user = Guardian.Plug.current_resource(conn)
    params = Map.put(faq_params, "trainer_id", user.id)

    with {:ok, faq} <- Content.create_faq(params) do
      conn
      |> put_status(:created)
      |> json(%{data: faq_json(faq)})
    end
  end

  def update(conn, %{"id" => id, "faq" => faq_params}) do
    faq = Repo.get!(FAQ, id)

    with {:ok, updated} <- Content.update_faq(faq, faq_params) do
      json(conn, %{data: faq_json(updated)})
    end
  end

  def delete(conn, %{"id" => id}) do
    faq = Repo.get!(FAQ, id)

    with {:ok, _} <- Content.delete_faq(faq) do
      send_resp(conn, :no_content, "")
    end
  end

  defp faq_json(faq) do
    %{
      id: faq.id,
      trainer_id: faq.trainer_id,
      question: faq.question,
      answer: faq.answer,
      category: faq.category,
      display_order: faq.display_order,
      is_published: faq.is_published,
      inserted_at: faq.inserted_at,
      updated_at: faq.updated_at
    }
  end
end
