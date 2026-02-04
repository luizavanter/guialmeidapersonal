defmodule GaPersonalWeb.Plugs.Authorize do
  @moduledoc """
  Authorization plugs for role-based access control.

  ## Usage

  In your router:

      pipeline :trainer_only do
        plug GaPersonalWeb.Plugs.Authorize, roles: ["trainer", "admin"]
      end

      pipeline :student_only do
        plug GaPersonalWeb.Plugs.Authorize, roles: ["student"]
      end

  Or in a controller:

      plug GaPersonalWeb.Plugs.Authorize, [roles: ["trainer", "admin"]] when action in [:create, :update]
  """

  import Plug.Conn
  import Phoenix.Controller

  alias GaPersonal.Guardian

  @behaviour Plug

  @doc """
  Initialize the plug with allowed roles.

  ## Options

    * `:roles` - List of role strings that are allowed. Required.

  ## Examples

      plug GaPersonalWeb.Plugs.Authorize, roles: ["trainer", "admin"]
      plug GaPersonalWeb.Plugs.Authorize, roles: ["student"]
  """
  @impl Plug
  def init(opts) do
    roles = Keyword.get(opts, :roles, [])

    if roles == [] do
      raise ArgumentError, "GaPersonalWeb.Plugs.Authorize requires :roles option"
    end

    %{roles: roles}
  end

  @doc """
  Checks if the current user has one of the allowed roles.
  Returns 403 Forbidden if the user does not have an allowed role.
  """
  @impl Plug
  def call(conn, %{roles: allowed_roles}) do
    user = Guardian.Plug.current_resource(conn)

    cond do
      is_nil(user) ->
        # No user loaded - should be caught by authentication first
        conn
        |> put_status(:unauthorized)
        |> json(%{errors: %{message: "Not authenticated"}})
        |> halt()

      user.role in allowed_roles ->
        # User has an allowed role - proceed
        conn

      true ->
        # User does not have an allowed role
        conn
        |> put_status(:forbidden)
        |> json(%{errors: %{message: "Forbidden - insufficient permissions"}})
        |> halt()
    end
  end
end

defmodule GaPersonalWeb.Plugs.RequireRole do
  @moduledoc """
  Convenience plug for requiring specific roles.

  ## Usage

      # Allow trainers and admins
      plug GaPersonalWeb.Plugs.RequireRole, [:trainer, :admin]

      # Allow only students
      plug GaPersonalWeb.Plugs.RequireRole, [:student]
  """

  import Plug.Conn
  import Phoenix.Controller

  alias GaPersonal.Guardian

  @behaviour Plug

  @impl Plug
  def init(roles) when is_list(roles) do
    # Convert atoms to strings for comparison
    Enum.map(roles, &to_string/1)
  end

  def init(role) when is_atom(role) or is_binary(role) do
    [to_string(role)]
  end

  @impl Plug
  def call(conn, allowed_roles) do
    user = Guardian.Plug.current_resource(conn)

    cond do
      is_nil(user) ->
        conn
        |> put_status(:unauthorized)
        |> json(%{errors: %{message: "Not authenticated"}})
        |> halt()

      user.role in allowed_roles ->
        conn

      true ->
        conn
        |> put_status(:forbidden)
        |> json(%{errors: %{
          message: "Forbidden",
          detail: "This action requires one of the following roles: #{Enum.join(allowed_roles, ", ")}"
        }})
        |> halt()
    end
  end
end

defmodule GaPersonalWeb.Plugs.LoadCurrentUser do
  @moduledoc """
  Plug to ensure current user is loaded and assign useful user data to conn.

  This plug:
  - Loads the current user from Guardian
  - Assigns the user to conn.assigns.current_user
  - Assigns the user's role to conn.assigns.current_role
  - Assigns the user's id to conn.assigns.current_user_id
  """

  import Plug.Conn

  alias GaPersonal.Guardian

  @behaviour Plug

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    user = Guardian.Plug.current_resource(conn)

    if user do
      conn
      |> assign(:current_user, user)
      |> assign(:current_user_id, user.id)
      |> assign(:current_role, user.role)
    else
      conn
    end
  end
end
