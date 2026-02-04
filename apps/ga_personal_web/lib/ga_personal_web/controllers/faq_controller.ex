defmodule GaPersonalWeb.FAQController do
  use GaPersonalWeb, :controller

  alias GaPersonal.Content

  action_fallback GaPersonalWeb.FallbackController

  def index(conn, params) do
    trainer_id = conn.assigns.current_user_id
    faqs = Content.list_faqs(trainer_id, params)
    json(conn, %{data: Enum.map(faqs, &faq_json/1)})
  end

  def show(conn, %{"id" => id}) do
    trainer_id = conn.assigns.current_user_id

    case Content.get_faq_for_trainer(id, trainer_id) do
      {:ok, faq} ->
        json(conn, %{data: faq_json(faq)})

      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :unauthorized} ->
        {:error, :forbidden}
    end
  end

  def create(conn, %{"faq" => faq_params}) do
    trainer_id = conn.assigns.current_user_id
    params = Map.put(faq_params, "trainer_id", trainer_id)

    with {:ok, faq} <- Content.create_faq(params) do
      conn
      |> put_status(:created)
      |> json(%{data: faq_json(faq)})
    end
  end

  def update(conn, %{"id" => id, "faq" => faq_params}) do
    trainer_id = conn.assigns.current_user_id

    case Content.get_faq_for_trainer(id, trainer_id) do
      {:ok, faq} ->
        with {:ok, updated} <- Content.update_faq(faq, faq_params) do
          json(conn, %{data: faq_json(updated)})
        end

      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :unauthorized} ->
        {:error, :forbidden}
    end
  end

  def delete(conn, %{"id" => id}) do
    trainer_id = conn.assigns.current_user_id

    case Content.get_faq_for_trainer(id, trainer_id) do
      {:ok, faq} ->
        with {:ok, _} <- Content.delete_faq(faq) do
          send_resp(conn, :no_content, "")
        end

      {:error, :not_found} ->
        {:error, :not_found}

      {:error, :unauthorized} ->
        {:error, :forbidden}
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
