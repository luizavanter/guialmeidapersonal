defmodule GaPersonal.Workouts do
  @moduledoc """
  The Workouts context - handles exercises, workout plans, and workout logs.
  """

  import Ecto.Query, warn: false
  alias GaPersonal.Repo
  alias GaPersonal.Workouts.{Exercise, WorkoutPlan, WorkoutExercise, WorkoutLog}

  ## Exercise functions

  def list_exercises(trainer_id) do
    from(e in Exercise,
      where: e.trainer_id == ^trainer_id or e.is_public == true,
      order_by: [e.name]
    )
    |> Repo.all()
  end

  def get_exercise!(id), do: Repo.get!(Exercise, id)

  def create_exercise(attrs \\ %{}) do
    %Exercise{}
    |> Exercise.changeset(attrs)
    |> Repo.insert()
  end

  def update_exercise(%Exercise{} = exercise, attrs) do
    exercise
    |> Exercise.changeset(attrs)
    |> Repo.update()
  end

  def delete_exercise(%Exercise{} = exercise) do
    Repo.delete(exercise)
  end

  ## WorkoutPlan functions

  def list_workout_plans(trainer_id, filters \\ %{}) do
    query = from wp in WorkoutPlan,
      where: wp.trainer_id == ^trainer_id,
      preload: [:student, workout_exercises: :exercise],
      order_by: [desc: wp.inserted_at]

    query
    |> apply_plan_filters(filters)
    |> Repo.all()
  end

  defp apply_plan_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {:student_id, student_id}, query ->
        from wp in query, where: wp.student_id == ^student_id

      {:status, status}, query ->
        from wp in query, where: wp.status == ^status

      {:is_template, is_template}, query ->
        from wp in query, where: wp.is_template == ^is_template

      _, query ->
        query
    end)
  end

  def get_workout_plan!(id) do
    WorkoutPlan
    |> Repo.get!(id)
    |> Repo.preload([:student, workout_exercises: :exercise])
  end

  def create_workout_plan(attrs \\ %{}) do
    %WorkoutPlan{}
    |> WorkoutPlan.changeset(attrs)
    |> Repo.insert()
  end

  def update_workout_plan(%WorkoutPlan{} = plan, attrs) do
    plan
    |> WorkoutPlan.changeset(attrs)
    |> Repo.update()
  end

  def delete_workout_plan(%WorkoutPlan{} = plan) do
    Repo.delete(plan)
  end

  ## WorkoutExercise functions

  def create_workout_exercise(attrs \\ %{}) do
    %WorkoutExercise{}
    |> WorkoutExercise.changeset(attrs)
    |> Repo.insert()
  end

  def update_workout_exercise(%WorkoutExercise{} = workout_exercise, attrs) do
    workout_exercise
    |> WorkoutExercise.changeset(attrs)
    |> Repo.update()
  end

  def delete_workout_exercise(%WorkoutExercise{} = workout_exercise) do
    Repo.delete(workout_exercise)
  end

  ## WorkoutLog functions

  def list_workout_logs(student_id, filters \\ %{}) do
    query = from wl in WorkoutLog,
      where: wl.student_id == ^student_id,
      preload: [:exercise, :workout_plan],
      order_by: [desc: wl.completed_at]

    query
    |> apply_log_filters(filters)
    |> Repo.all()
  end

  defp apply_log_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {:exercise_id, exercise_id}, query ->
        from wl in query, where: wl.exercise_id == ^exercise_id

      {:date_from, date_from}, query ->
        from wl in query, where: wl.completed_at >= ^date_from

      {:date_to, date_to}, query ->
        from wl in query, where: wl.completed_at <= ^date_to

      _, query ->
        query
    end)
  end

  def create_workout_log(attrs \\ %{}) do
    %WorkoutLog{}
    |> WorkoutLog.changeset(attrs)
    |> Repo.insert()
  end
end
