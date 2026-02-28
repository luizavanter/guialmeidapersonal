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

  @doc """
  Gets an exercise with ownership verification.
  Public exercises are accessible to all trainers.
  Private exercises are only accessible to their owner.
  """
  def get_exercise_for_trainer(id, trainer_id) do
    case Repo.get(Exercise, id) do
      nil ->
        {:error, :not_found}

      %Exercise{is_public: true} = exercise ->
        {:ok, exercise}

      %Exercise{trainer_id: ^trainer_id} = exercise ->
        {:ok, exercise}

      %Exercise{} ->
        {:error, :unauthorized}
    end
  end

  def get_exercise_for_trainer!(id, trainer_id) do
    exercise = get_exercise!(id)
    if exercise.is_public or exercise.trainer_id == trainer_id do
      exercise
    else
      raise Ecto.NoResultsError, queryable: Exercise
    end
  end

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

  @doc """
  Gets a workout plan with ownership verification.
  """
  def get_workout_plan_for_trainer(id, trainer_id) do
    case get_workout_plan!(id) do
      nil ->
        {:error, :not_found}

      %WorkoutPlan{trainer_id: ^trainer_id} = plan ->
        {:ok, plan}

      %WorkoutPlan{} ->
        {:error, :unauthorized}
    end
  rescue
    Ecto.NoResultsError -> {:error, :not_found}
  end

  def get_workout_plan_for_trainer!(id, trainer_id) do
    plan = get_workout_plan!(id)
    if plan.trainer_id == trainer_id, do: plan, else: raise(Ecto.NoResultsError, queryable: WorkoutPlan)
  end

  @doc """
  Gets a workout plan for a student (read-only access).
  """
  def get_workout_plan_for_student(id, student_id) do
    case get_workout_plan!(id) do
      nil ->
        {:error, :not_found}

      %WorkoutPlan{student_id: ^student_id} = plan ->
        {:ok, plan}

      %WorkoutPlan{} ->
        {:error, :unauthorized}
    end
  rescue
    Ecto.NoResultsError -> {:error, :not_found}
  end

  @doc """
  Lists workout plans for a specific student.
  """
  def list_workout_plans_for_student(student_id, filters \\ %{}) do
    query = from wp in WorkoutPlan,
      where: wp.student_id == ^student_id,
      preload: [workout_exercises: :exercise],
      order_by: [desc: wp.inserted_at]

    query
    |> apply_plan_filters(filters)
    |> Repo.all()
  end

  @doc """
  Gets a workout log with student ownership verification.
  """
  def get_workout_log!(id) do
    WorkoutLog
    |> Repo.get!(id)
    |> Repo.preload([:exercise, :workout_plan])
  end

  def get_workout_log_for_student(id, student_id) do
    case get_workout_log!(id) do
      nil ->
        {:error, :not_found}

      %WorkoutLog{student_id: ^student_id} = log ->
        {:ok, log}

      %WorkoutLog{} ->
        {:error, :unauthorized}
    end
  rescue
    Ecto.NoResultsError -> {:error, :not_found}
  end

  def create_workout_plan(attrs \\ %{}) do
    %WorkoutPlan{}
    |> WorkoutPlan.changeset(attrs)
    |> Repo.insert()
  end

  def update_workout_plan(%WorkoutPlan{} = plan, attrs) do
    old_status = plan.status

    result =
      plan
      |> WorkoutPlan.changeset(attrs)
      |> Repo.update()

    case result do
      {:ok, updated} ->
        if old_status != "active" and updated.status == "active" and updated.student_id do
          GaPersonal.NotificationService.on_workout_plan_assigned(updated, updated.student_id)
        end
        {:ok, updated}

      error ->
        error
    end
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
