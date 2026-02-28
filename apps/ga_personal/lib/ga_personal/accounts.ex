defmodule GaPersonal.Accounts do
  @moduledoc """
  The Accounts context - handles users, authentication, and student profiles.
  """

  import Ecto.Query, warn: false
  alias GaPersonal.Repo
  alias GaPersonal.Accounts.{User, StudentProfile, RefreshToken}

  ## User functions

  @doc """
  Returns the list of users.
  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.
  """
  def get_user(id), do: Repo.get(User, id)

  @doc """
  Gets a single user, raises if not found.
  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Gets a user by email.
  """
  def get_user_by_email(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Creates a user.
  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.
  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user.
  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Authenticates a user by email and password.
  """
  def authenticate(email, password) do
    user = get_user_by_email(email)

    cond do
      user && User.verify_password(user, password) && user.active ->
        update_user(user, %{last_login_at: DateTime.utc_now()})
        {:ok, user}

      user && !user.active ->
        {:error, :inactive_user}

      true ->
        Bcrypt.no_user_verify()
        {:error, :invalid_credentials}
    end
  end

  ## Refresh Token functions

  @doc """
  Creates a new refresh token for a user.
  Returns {raw_token, refresh_token_record}.
  """
  def create_refresh_token(%User{id: user_id}) do
    raw_token = RefreshToken.generate_token()
    token_hash = RefreshToken.hash_token(raw_token)

    attrs = %{
      token_hash: token_hash,
      user_id: user_id,
      expires_at: RefreshToken.default_expiry()
    }

    case %RefreshToken{} |> RefreshToken.changeset(attrs) |> Repo.insert() do
      {:ok, record} -> {:ok, raw_token, record}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc """
  Verifies a raw refresh token. Returns the token record if valid.
  """
  def verify_refresh_token(raw_token) when is_binary(raw_token) do
    token_hash = RefreshToken.hash_token(raw_token)

    case Repo.get_by(RefreshToken, token_hash: token_hash) do
      nil ->
        {:error, :invalid_token}

      %RefreshToken{} = token ->
        cond do
          RefreshToken.revoked?(token) -> {:error, :token_revoked}
          RefreshToken.expired?(token) -> {:error, :token_expired}
          true -> {:ok, token}
        end
    end
  end

  def verify_refresh_token(_), do: {:error, :invalid_token}

  @doc """
  Revokes a refresh token.
  """
  def revoke_refresh_token(%RefreshToken{} = token) do
    token
    |> RefreshToken.changeset(%{revoked_at: DateTime.utc_now() |> DateTime.truncate(:second)})
    |> Repo.update()
  end

  @doc """
  Revokes all refresh tokens for a user.
  """
  def revoke_all_refresh_tokens(%User{id: user_id}) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    from(rt in RefreshToken,
      where: rt.user_id == ^user_id and is_nil(rt.revoked_at)
    )
    |> Repo.update_all(set: [revoked_at: now])
  end

  @doc """
  Rotates a refresh token: revokes the old one, creates a new one.
  Returns {new_raw_token, new_record, user}.
  """
  def rotate_refresh_token(raw_token) do
    with {:ok, old_token} <- verify_refresh_token(raw_token),
         user when not is_nil(user) <- get_user(old_token.user_id),
         {:ok, _revoked} <- revoke_refresh_token(old_token),
         {:ok, new_raw_token, new_record} <- create_refresh_token(user) do
      {:ok, new_raw_token, new_record, user}
    else
      nil -> {:error, :user_not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Deletes expired and revoked refresh tokens older than 7 days.
  """
  def cleanup_refresh_tokens do
    cutoff = DateTime.utc_now() |> DateTime.add(-7 * 24 * 60 * 60, :second)

    from(rt in RefreshToken,
      where: rt.expires_at < ^cutoff or (not is_nil(rt.revoked_at) and rt.revoked_at < ^cutoff)
    )
    |> Repo.delete_all()
  end

  ## Student Profile functions

  @doc """
  Returns the list of student profiles for a trainer.
  """
  def list_students(trainer_id, filters \\ %{}) do
    query = from sp in StudentProfile,
      where: sp.trainer_id == ^trainer_id,
      preload: [:user]

    query
    |> apply_student_filters(filters)
    |> Repo.all()
  end

  defp apply_student_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {:status, status}, query ->
        from sp in query, where: sp.status == ^status

      {:search, search_term}, query ->
        search_pattern = "%#{search_term}%"
        from sp in query,
          join: u in assoc(sp, :user),
          where: ilike(u.full_name, ^search_pattern) or ilike(u.email, ^search_pattern)

      _, query ->
        query
    end)
  end

  @doc """
  Gets a single student profile.
  """
  def get_student(id) do
    StudentProfile
    |> Repo.get(id)
    |> Repo.preload(:user)
  end

  @doc """
  Gets a single student profile, raises if not found.
  """
  def get_student!(id) do
    StudentProfile
    |> Repo.get!(id)
    |> Repo.preload(:user)
  end

  @doc """
  Gets a student profile with ownership verification.
  Returns {:ok, student} if the student belongs to the trainer,
  {:error, :not_found} if student doesn't exist,
  or {:error, :unauthorized} if student belongs to another trainer.
  """
  def get_student_for_trainer(id, trainer_id) do
    case get_student(id) do
      nil ->
        {:error, :not_found}

      %StudentProfile{trainer_id: ^trainer_id} = student ->
        {:ok, student}

      %StudentProfile{} ->
        {:error, :unauthorized}
    end
  end

  @doc """
  Gets a student profile with ownership verification, raises if not found or unauthorized.
  """
  def get_student_for_trainer!(id, trainer_id) do
    student = get_student!(id)

    if student.trainer_id == trainer_id do
      student
    else
      raise Ecto.NoResultsError, queryable: StudentProfile
    end
  end

  @doc """
  Gets a student profile by user_id.
  """
  def get_student_by_user_id(user_id) do
    StudentProfile
    |> Repo.get_by(user_id: user_id)
    |> Repo.preload(:user)
  end

  @doc """
  Creates a student (creates user and profile together).
  """
  def create_student(trainer_id, attrs \\ %{}) do
    result = Repo.transaction(fn ->
      user_attrs = Map.take(attrs, ["email", "password", "full_name", "phone"])
      |> Map.put("role", "student")

      with {:ok, user} <- create_user(user_attrs),
           profile_attrs = attrs
           |> Map.put("user_id", user.id)
           |> Map.put("trainer_id", trainer_id),
           {:ok, profile} <- create_student_profile(profile_attrs) do
        Repo.preload(profile, :user)
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)

    case result do
      {:ok, profile} ->
        GaPersonal.NotificationService.on_student_created(profile.user)
        {:ok, profile}

      error ->
        error
    end
  end

  @doc """
  Creates a student profile.
  """
  def create_student_profile(attrs \\ %{}) do
    %StudentProfile{}
    |> StudentProfile.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a student profile.
  """
  def update_student_profile(%StudentProfile{} = profile, attrs) do
    profile
    |> StudentProfile.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a student profile.
  """
  def delete_student_profile(%StudentProfile{} = profile) do
    Repo.delete(profile)
  end

  @doc """
  Deactivates a student (sets status to cancelled).
  """
  def deactivate_student(%StudentProfile{} = profile) do
    update_student_profile(profile, %{status: "cancelled"})
  end
end
