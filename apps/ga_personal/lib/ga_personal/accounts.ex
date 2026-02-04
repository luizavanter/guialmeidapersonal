defmodule GaPersonal.Accounts do
  @moduledoc """
  The Accounts context - handles users, authentication, and student profiles.
  """

  import Ecto.Query, warn: false
  alias GaPersonal.Repo
  alias GaPersonal.Accounts.{User, StudentProfile}

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
    Repo.transaction(fn ->
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
