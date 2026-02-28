defmodule GaPersonalWeb.HealthControllerTest do
  use GaPersonalWeb.ConnCase, async: true

  describe "GET /api/v1/health" do
    test "returns healthy status", %{conn: conn} do
      conn = get(conn, "/api/v1/health")

      assert %{
               "status" => "healthy",
               "checks" => %{"database" => "ok"},
               "timestamp" => _,
               "version" => _
             } = json_response(conn, 200)
    end

    test "does not require authentication", %{conn: conn} do
      conn = get(conn, "/api/v1/health")
      assert conn.status == 200
    end
  end
end
