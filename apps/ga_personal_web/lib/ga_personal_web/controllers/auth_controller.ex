defmodule GaPersonalWeb.AuthController do
  use GaPersonalWeb, :controller

  alias GaPersonal.Accounts
  alias GaPersonal.Guardian

  action_fallback GaPersonalWeb.FallbackController

  # Token expiration in seconds (28 days)
  @token_expires_in 28 * 24 * 60 * 60

  def register(conn, %{"user" => user_params}) do
    with {:ok, user} <- Accounts.create_user(user_params),
         {:ok, token, _claims} <- Guardian.encode_and_sign(user) do
      conn
      |> put_status(:created)
      |> json(%{
        data: %{
          user: user_json(user),
          tokens: tokens_json(token)
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
          tokens: tokens_json(token)
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
    {first_name, last_name} = split_name(user.full_name)

    %{
      id: user.id,
      email: user.email,
      role: user.role,
      firstName: first_name,
      lastName: last_name,
      phone: user.phone,
      avatarUrl: nil,
      locale: format_locale(user.locale),
      createdAt: format_datetime(user.inserted_at),
      updatedAt: format_datetime(user.updated_at)
    }
  end

  defp tokens_json(access_token) do
    %{
      accessToken: access_token,
      refreshToken: access_token,
      expiresIn: @token_expires_in
    }
  end

  defp split_name(nil), do: {"", ""}
  defp split_name(full_name) do
    parts = String.split(full_name, " ", parts: 2)
    case parts do
      [first] -> {first, ""}
      [first, last] -> {first, last}
      _ -> {full_name, ""}
    end
  end

  defp format_locale(nil), do: "pt-BR"
  defp format_locale("pt_BR"), do: "pt-BR"
  defp format_locale("en_US"), do: "en-US"
  defp format_locale(locale), do: locale

  defp format_datetime(nil), do: nil
  defp format_datetime(datetime), do: DateTime.to_iso8601(datetime)
end
