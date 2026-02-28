defmodule GaPersonal.Evolution do
  @moduledoc """
  The Evolution context - handles body assessments, photos, and goals.
  """

  import Ecto.Query, warn: false
  alias GaPersonal.Repo
  alias GaPersonal.Evolution.{BodyAssessment, EvolutionPhoto, Goal}

  ## BodyAssessment functions

  def list_body_assessments(student_id) do
    from(ba in BodyAssessment,
      where: ba.student_id == ^student_id,
      order_by: [desc: ba.assessment_date],
      preload: :evolution_photos
    )
    |> Repo.all()
  end

  def get_body_assessment!(id) do
    BodyAssessment
    |> Repo.get!(id)
    |> Repo.preload(:evolution_photos)
  end

  @doc """
  Gets a body assessment with trainer ownership verification.
  Verifies that the student belongs to the trainer.
  """
  def get_body_assessment_for_trainer(id, trainer_id) do
    case get_body_assessment!(id) do
      nil ->
        {:error, :not_found}

      assessment ->
        # student_id references users table, so look up profile by user_id
        case GaPersonal.Accounts.get_student_by_user_id(assessment.student_id) do
          nil ->
            {:error, :not_found}

          %{trainer_id: ^trainer_id} ->
            {:ok, assessment}

          _ ->
            {:error, :unauthorized}
        end
    end
  rescue
    Ecto.NoResultsError -> {:error, :not_found}
  end

  @doc """
  Gets a body assessment for a student (read-only access).
  """
  def get_body_assessment_for_student(id, student_id) do
    case get_body_assessment!(id) do
      nil ->
        {:error, :not_found}

      %BodyAssessment{student_id: ^student_id} = assessment ->
        {:ok, assessment}

      %BodyAssessment{} ->
        {:error, :unauthorized}
    end
  rescue
    Ecto.NoResultsError -> {:error, :not_found}
  end

  def create_body_assessment(attrs \\ %{}) do
    %BodyAssessment{}
    |> BodyAssessment.changeset(attrs)
    |> Repo.insert()
  end

  def update_body_assessment(%BodyAssessment{} = assessment, attrs) do
    assessment
    |> BodyAssessment.changeset(attrs)
    |> Repo.update()
  end

  def delete_body_assessment(%BodyAssessment{} = assessment) do
    Repo.delete(assessment)
  end

  ## EvolutionPhoto functions

  def list_evolution_photos(student_id) do
    from(ep in EvolutionPhoto,
      where: ep.student_id == ^student_id,
      order_by: [desc: ep.taken_at]
    )
    |> Repo.all()
  end

  def create_evolution_photo(attrs \\ %{}) do
    %EvolutionPhoto{}
    |> EvolutionPhoto.changeset(attrs)
    |> Repo.insert()
  end

  def delete_evolution_photo(%EvolutionPhoto{} = photo) do
    Repo.delete(photo)
  end

  ## Goal functions

  def list_goals(student_id, filters \\ %{}) do
    query = from g in Goal,
      where: g.student_id == ^student_id,
      order_by: [desc: g.inserted_at]

    query
    |> apply_goal_filters(filters)
    |> Repo.all()
  end

  defp apply_goal_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {:status, status}, query ->
        from g in query, where: g.status == ^status

      {:goal_type, goal_type}, query ->
        from g in query, where: g.goal_type == ^goal_type

      _, query ->
        query
    end)
  end

  def get_goal!(id), do: Repo.get!(Goal, id)

  @doc """
  Gets a goal with trainer ownership verification.
  Verifies that the student belongs to the trainer.
  """
  def get_goal_for_trainer(id, trainer_id) do
    case Repo.get(Goal, id) do
      nil ->
        {:error, :not_found}

      goal ->
        # student_id references users table, so look up profile by user_id
        case GaPersonal.Accounts.get_student_by_user_id(goal.student_id) do
          nil ->
            {:error, :not_found}

          %{trainer_id: ^trainer_id} ->
            {:ok, goal}

          _ ->
            {:error, :unauthorized}
        end
    end
  end

  @doc """
  Gets a goal for a student (read-only access).
  """
  def get_goal_for_student(id, student_id) do
    case Repo.get(Goal, id) do
      nil ->
        {:error, :not_found}

      %Goal{student_id: ^student_id} = goal ->
        {:ok, goal}

      %Goal{} ->
        {:error, :unauthorized}
    end
  end

  def create_goal(attrs \\ %{}) do
    %Goal{}
    |> Goal.changeset(attrs)
    |> Repo.insert()
  end

  def update_goal(%Goal{} = goal, attrs) do
    goal
    |> Goal.changeset(attrs)
    |> Repo.update()
  end

  def delete_goal(%Goal{} = goal) do
    Repo.delete(goal)
  end

  def achieve_goal(%Goal{} = goal) do
    update_goal(goal, %{
      status: "achieved",
      achieved_at: Date.utc_today()
    })
  end
end
