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
