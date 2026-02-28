defmodule GaPersonalWeb.AuthControllerTest do
  use GaPersonalWeb.ConnCase, async: true

  describe "POST /api/v1/auth/login" do
    test "returns tokens with valid credentials", %{conn: conn} do
      insert(:user, email: "test@example.com", password: "Password123!")

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/api/v1/auth/login", %{email: "test@example.com", password: "Password123!"})

      assert %{"data" => %{"user" => user, "tokens" => tokens}} = json_response(conn, 200)
      assert user["email"] == "test@example.com"
      assert tokens["accessToken"] != nil
      assert tokens["refreshToken"] != nil
      assert tokens["expiresIn"] == 900
    end

    test "returns 401 with invalid credentials", %{conn: conn} do
      insert(:user, email: "test@example.com", password: "Password123!")

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/api/v1/auth/login", %{email: "test@example.com", password: "wrongpassword"})

      assert %{"errors" => %{"message" => "Invalid email or password"}} = json_response(conn, 401)
    end

    test "returns 401 for non-existent user", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/api/v1/auth/login", %{email: "nobody@example.com", password: "anypassword"})

      assert json_response(conn, 401)
    end

    test "returns 403 for inactive user", %{conn: conn} do
      insert(:user, email: "inactive@example.com", password: "Password123!", active: false)

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/api/v1/auth/login", %{email: "inactive@example.com", password: "Password123!"})

      assert %{"errors" => %{"message" => "Account is inactive"}} = json_response(conn, 403)
    end
  end

  describe "POST /api/v1/auth/register" do
    test "creates user and returns tokens", %{conn: conn} do
      params = %{
        user: %{
          email: "new@example.com",
          password: "Password123!",
          full_name: "New User",
          role: "trainer"
        }
      }

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/api/v1/auth/register", params)

      assert %{"data" => %{"user" => user, "tokens" => tokens}} = json_response(conn, 201)
      assert user["email"] == "new@example.com"
      assert tokens["accessToken"] != nil
    end

    test "returns error with invalid data", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/api/v1/auth/register", %{user: %{}})

      assert json_response(conn, 422)
    end
  end

  describe "POST /api/v1/auth/refresh" do
    test "rotates tokens with valid refresh token", %{conn: conn} do
      user = insert(:user)
      {:ok, raw_token, _record} = GaPersonal.Accounts.create_refresh_token(user)

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/api/v1/auth/refresh", %{refreshToken: raw_token})

      assert %{"data" => %{"tokens" => tokens}} = json_response(conn, 200)
      assert tokens["accessToken"] != nil
      assert tokens["refreshToken"] != nil
      assert tokens["refreshToken"] != raw_token
    end

    test "returns 401 with invalid refresh token", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/api/v1/auth/refresh", %{refreshToken: "invalid-token"})

      assert json_response(conn, 401)
    end
  end

  describe "POST /api/v1/auth/logout" do
    test "revokes refresh token", %{conn: conn} do
      user = insert(:user)
      {:ok, raw_token, _record} = GaPersonal.Accounts.create_refresh_token(user)

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/api/v1/auth/logout", %{refreshToken: raw_token})

      assert %{"data" => %{"message" => "Logged out successfully"}} = json_response(conn, 200)

      # Verify token is revoked
      assert {:error, :token_revoked} = GaPersonal.Accounts.verify_refresh_token(raw_token)
    end

    test "returns success even with invalid token", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post("/api/v1/auth/logout", %{refreshToken: "invalid"})

      assert %{"data" => %{"message" => "Logged out successfully"}} = json_response(conn, 200)
    end
  end

  describe "GET /api/v1/auth/me" do
    test "returns current user when authenticated", %{conn: conn} do
      %{conn: conn, trainer: trainer} = setup_trainer_conn(%{conn: conn})

      conn = get(conn, "/api/v1/auth/me")

      assert %{"data" => user} = json_response(conn, 200)
      assert user["id"] == trainer.id
      assert user["email"] == trainer.email
    end

    test "returns 401 when not authenticated", %{conn: conn} do
      conn = get(conn, "/api/v1/auth/me")
      assert json_response(conn, 401)
    end
  end
end
