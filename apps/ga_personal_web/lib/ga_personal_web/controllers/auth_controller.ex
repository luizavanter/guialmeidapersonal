defmodule GaPersonalWeb.AuthController do
  use GaPersonalWeb, :controller

  alias GaPersonal.Accounts
  alias GaPersonal.Guardian

  action_fallback GaPersonalWeb.FallbackController

  def register(conn, %{"user" => user_params}) do
    with {:ok, user} <- Accounts.create_user(user_params),
         {:ok, token, _claims} <- Guardian.encode_and_sign(user) do
      conn
      |> put_status(:created)
      |> json(%{
        data: %{
          user: user_json(user),
          token: token
        }
      })
    end
  end

  def login(conn, %{"email" => email, "password" => password}) do
    with {:ok, user} <- Accounts.authenticate(email, password),
         {:ok, token, _claims} <- Guardian.encode_and_sign(user) do
      json(conn, %{
        data: %{
          user: user_json(user),
          token: token
        }
      })
    else
      {:error, :invalid_credentials} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{errors: %{message: "Invalid email or password"}})

      {:error, :inactive_user} ->
        conn
        |> put_status(:forbidden)
        |> json(%{errors: %{message: "Account is inactive"}})
    end
  end

  def me(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    json(conn, %{data: user_json(user)})
  end

  defp user_json(user) do
    %{
      id: user.id,
      email: user.email,
      full_name: user.full_name,
      role: user.role,
      phone: user.phone,
      locale: user.locale,
      active: user.active
    }
  end
end
