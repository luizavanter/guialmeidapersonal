defmodule GaPersonal.Pose do
  @moduledoc """
  The Pose context - stores results from client-side pose detection
  using TensorFlow.js MoveNet. All detection happens in the browser;
  this context only persists the results.
  """

  import Ecto.Query, warn: false
  alias GaPersonal.Repo
  alias GaPersonal.Pose.PoseAnalysis

  def create_result(attrs) do
    %PoseAnalysis{}
    |> PoseAnalysis.changeset(attrs)
    |> Repo.insert()
  end

  def list_results(student_id, filters \\ %{}) do
    from(p in PoseAnalysis,
      where: p.student_id == ^student_id,
      order_by: [desc: p.inserted_at]
    )
    |> apply_filters(filters)
    |> Repo.all()
  end

  def list_results_for_trainer(trainer_id, filters \\ %{}) do
    from(p in PoseAnalysis,
      where: p.trainer_id == ^trainer_id,
      order_by: [desc: p.inserted_at]
    )
    |> apply_filters(filters)
    |> Repo.all()
  end

  def get_result(id) do
    case Repo.get(PoseAnalysis, id) do
      nil -> {:error, :not_found}
      result -> {:ok, result}
    end
  end

  def get_result_for_trainer(id, trainer_id) do
    case Repo.get(PoseAnalysis, id) do
      nil -> {:error, :not_found}
      %PoseAnalysis{trainer_id: ^trainer_id} = result -> {:ok, result}
      %PoseAnalysis{} -> {:error, :unauthorized}
    end
  end

  def get_result_for_student(id, student_id) do
    case Repo.get(PoseAnalysis, id) do
      nil -> {:error, :not_found}
      %PoseAnalysis{student_id: ^student_id} = result -> {:ok, result}
      %PoseAnalysis{} -> {:error, :unauthorized}
    end
  end

  defp apply_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {"analysis_type", type}, query ->
        from p in query, where: p.analysis_type == ^type

      {"exercise_name", name}, query ->
        from p in query, where: p.exercise_name == ^name

      {"student_id", student_id}, query ->
        from p in query, where: p.student_id == ^student_id

      _, query ->
        query
    end)
  end
end
