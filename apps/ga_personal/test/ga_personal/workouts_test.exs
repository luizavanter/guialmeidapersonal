defmodule GaPersonal.WorkoutsTest do
  use GaPersonal.DataCase, async: true

  alias GaPersonal.Workouts
  alias GaPersonal.Workouts.{Exercise, WorkoutPlan, WorkoutExercise, WorkoutLog}

  describe "exercises" do
    setup do
      trainer = insert(:trainer)
      %{trainer: trainer}
    end

    test "list_exercises/1 returns trainer's exercises", %{trainer: trainer} do
      exercise = insert(:exercise, trainer: trainer)
      exercises = Workouts.list_exercises(trainer.id)
      assert Enum.any?(exercises, &(&1.id == exercise.id))
    end

    test "list_exercises/1 includes public exercises from other trainers", %{trainer: trainer} do
      other_trainer = insert(:trainer)
      insert(:exercise, trainer: other_trainer, is_public: true)
      exercises = Workouts.list_exercises(trainer.id)
      assert length(exercises) >= 1
    end

    test "create_exercise/1 with valid data", %{trainer: trainer} do
      attrs = %{
        trainer_id: trainer.id,
        name: "Bench Press",
        category: "strength",
        difficulty_level: "intermediate",
        muscle_groups: ["chest", "triceps"]
      }

      assert {:ok, %Exercise{name: "Bench Press"}} = Workouts.create_exercise(attrs)
    end

    test "create_exercise/1 without name returns error" do
      assert {:error, %Ecto.Changeset{}} = Workouts.create_exercise(%{})
    end

    test "get_exercise_for_trainer/2 returns owned exercise", %{trainer: trainer} do
      exercise = insert(:exercise, trainer: trainer)
      assert {:ok, %Exercise{}} = Workouts.get_exercise_for_trainer(exercise.id, trainer.id)
    end

    test "get_exercise_for_trainer/2 returns public exercise from other trainer", %{trainer: trainer} do
      other_trainer = insert(:trainer)
      exercise = insert(:exercise, trainer: other_trainer, is_public: true)
      assert {:ok, %Exercise{}} = Workouts.get_exercise_for_trainer(exercise.id, trainer.id)
    end

    test "update_exercise/2 updates the exercise", %{trainer: trainer} do
      exercise = insert(:exercise, trainer: trainer)
      assert {:ok, %Exercise{name: "Updated"}} = Workouts.update_exercise(exercise, %{name: "Updated"})
    end

    test "delete_exercise/1 deletes the exercise", %{trainer: trainer} do
      exercise = insert(:exercise, trainer: trainer)
      assert {:ok, %Exercise{}} = Workouts.delete_exercise(exercise)
      assert_raise Ecto.NoResultsError, fn -> Workouts.get_exercise!(exercise.id) end
    end
  end

  describe "workout_plans" do
    setup do
      trainer = insert(:trainer)
      student = insert(:student_user)
      %{trainer: trainer, student: student}
    end

    test "list_workout_plans/1 returns plans for trainer", %{trainer: trainer, student: student} do
      plan = insert(:workout_plan, trainer: trainer, student: student)
      assert [%WorkoutPlan{id: id}] = Workouts.list_workout_plans(trainer.id)
      assert id == plan.id
    end

    test "create_workout_plan/1 with valid data", %{trainer: trainer, student: student} do
      attrs = %{
        trainer_id: trainer.id,
        student_id: student.id,
        name: "Strength Program",
        status: "draft"
      }

      assert {:ok, %WorkoutPlan{name: "Strength Program"}} = Workouts.create_workout_plan(attrs)
    end

    test "create_workout_plan/1 with invalid status returns error", %{trainer: trainer} do
      attrs = %{trainer_id: trainer.id, name: "Test", status: "invalid"}
      assert {:error, %Ecto.Changeset{}} = Workouts.create_workout_plan(attrs)
    end

    test "get_workout_plan_for_trainer/2 returns owned plan", %{trainer: trainer, student: student} do
      plan = insert(:workout_plan, trainer: trainer, student: student)
      assert {:ok, %WorkoutPlan{}} = Workouts.get_workout_plan_for_trainer(plan.id, trainer.id)
    end

    test "get_workout_plan_for_trainer/2 returns unauthorized for other trainer", %{trainer: trainer, student: student} do
      plan = insert(:workout_plan, trainer: trainer, student: student)
      other = insert(:trainer)
      assert {:error, :unauthorized} = Workouts.get_workout_plan_for_trainer(plan.id, other.id)
    end

    test "get_workout_plan_for_student/2 returns plan for student", %{trainer: trainer, student: student} do
      plan = insert(:workout_plan, trainer: trainer, student: student)
      assert {:ok, %WorkoutPlan{}} = Workouts.get_workout_plan_for_student(plan.id, student.id)
    end

    test "list_workout_plans_for_student/1 returns student's plans", %{trainer: trainer, student: student} do
      insert(:workout_plan, trainer: trainer, student: student)
      assert length(Workouts.list_workout_plans_for_student(student.id)) == 1
    end

    test "update_workout_plan/2 updates the plan", %{trainer: trainer, student: student} do
      plan = insert(:workout_plan, trainer: trainer, student: student)
      assert {:ok, %WorkoutPlan{status: "active"}} = Workouts.update_workout_plan(plan, %{status: "active"})
    end

    test "delete_workout_plan/1 deletes the plan", %{trainer: trainer, student: student} do
      plan = insert(:workout_plan, trainer: trainer, student: student)
      assert {:ok, %WorkoutPlan{}} = Workouts.delete_workout_plan(plan)
    end
  end

  describe "workout_exercises" do
    test "create_workout_exercise/1 with valid data" do
      trainer = insert(:trainer)
      student = insert(:student_user)
      plan = insert(:workout_plan, trainer: trainer, student: student)
      exercise = insert(:exercise, trainer: trainer)

      attrs = %{
        workout_plan_id: plan.id,
        exercise_id: exercise.id,
        day_number: 1,
        order_in_workout: 1,
        sets: 3,
        reps: "10"
      }

      assert {:ok, %WorkoutExercise{}} = Workouts.create_workout_exercise(attrs)
    end
  end

  describe "workout_logs" do
    setup do
      trainer = insert(:trainer)
      student = insert(:student_user)
      exercise = insert(:exercise, trainer: trainer)
      %{trainer: trainer, student: student, exercise: exercise}
    end

    test "create_workout_log/1 with valid data", %{student: student, exercise: exercise} do
      attrs = %{
        student_id: student.id,
        exercise_id: exercise.id,
        completed_at: DateTime.utc_now() |> DateTime.truncate(:second),
        sets_completed: 3,
        reps_completed: "10,10,8",
        weight_used: "60kg",
        difficulty_rating: 3
      }

      assert {:ok, %WorkoutLog{}} = Workouts.create_workout_log(attrs)
    end

    test "list_workout_logs/1 returns logs for student", %{trainer: trainer, student: student, exercise: exercise} do
      plan = insert(:workout_plan, trainer: trainer, student: student)
      insert(:workout_log, student: student, exercise: exercise, workout_plan: plan)
      assert length(Workouts.list_workout_logs(student.id)) == 1
    end

    test "get_workout_log_for_student/2 returns owned log", %{trainer: trainer, student: student, exercise: exercise} do
      plan = insert(:workout_plan, trainer: trainer, student: student)
      log = insert(:workout_log, student: student, exercise: exercise, workout_plan: plan)
      assert {:ok, %WorkoutLog{}} = Workouts.get_workout_log_for_student(log.id, student.id)
    end
  end
end
