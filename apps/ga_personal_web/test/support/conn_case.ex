defmodule GaPersonalWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use GaPersonalWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint GaPersonalWeb.Endpoint

      use GaPersonalWeb, :verified_routes

      import Plug.Conn
      import Phoenix.ConnTest
      import GaPersonalWeb.ConnCase
      import GaPersonal.Factory
    end
  end

  setup tags do
    GaPersonal.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Creates a trainer user and returns an authenticated connection.
  """
  def setup_trainer_conn(%{conn: conn}) do
    trainer = GaPersonal.Factory.insert(:trainer)
    conn = authenticate_conn(conn, trainer)
    %{conn: conn, trainer: trainer}
  end

  @doc """
  Creates a student user and returns an authenticated connection.
  """
  def setup_student_conn(%{conn: conn}) do
    student = GaPersonal.Factory.insert(:student_user)
    conn = authenticate_conn(conn, student)
    %{conn: conn, student: student}
  end

  @doc """
  Creates an admin user and returns an authenticated connection.
  """
  def setup_admin_conn(%{conn: conn}) do
    admin = GaPersonal.Factory.insert(:admin)
    conn = authenticate_conn(conn, admin)
    %{conn: conn, admin: admin}
  end

  @doc """
  Authenticates a connection with a given user by generating a JWT token.
  """
  def authenticate_conn(conn, user) do
    {:ok, token, _claims} = GaPersonal.Guardian.encode_and_sign(user)

    conn
    |> Plug.Conn.put_req_header("authorization", "Bearer #{token}")
    |> Plug.Conn.put_req_header("content-type", "application/json")
  end
end
