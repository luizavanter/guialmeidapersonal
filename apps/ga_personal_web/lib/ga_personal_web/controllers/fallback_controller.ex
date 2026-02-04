defmodule GaPersonalWeb.FallbackController do
  @moduledoc """
  Translates controller action results into JSON responses.
  """
  use GaPersonalWeb, :controller

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{errors: translate_errors(changeset)})
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> json(%{errors: %{message: "Resource not found"}})
  end

  # 401 - Authentication failed
  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(:unauthorized)
    |> json(%{errors: %{message: "Unauthorized - authentication required"}})
  end

  # 401 - Invalid credentials
  def call(conn, {:error, :invalid_credentials}) do
    conn
    |> put_status(:unauthorized)
    |> json(%{errors: %{message: "Invalid email or password"}})
  end

  # 401 - Inactive user
  def call(conn, {:error, :inactive_user}) do
    conn
    |> put_status(:unauthorized)
    |> json(%{errors: %{message: "Account is inactive"}})
  end

  # 403 - Forbidden (ownership verification failed)
  def call(conn, {:error, :forbidden}) do
    conn
    |> put_status(:forbidden)
    |> json(%{errors: %{message: "Forbidden - you don't have permission to access this resource"}})
  end

  # Generic bad request
  def call(conn, {:error, :bad_request}) do
    conn
    |> put_status(:bad_request)
    |> json(%{errors: %{message: "Bad request"}})
  end

  # Generic bad request with message
  def call(conn, {:error, :bad_request, message}) when is_binary(message) do
    conn
    |> put_status(:bad_request)
    |> json(%{errors: %{message: message}})
  end

  defp translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
