defmodule GaPersonal.EvolutionTest do
  use GaPersonal.DataCase, async: true

  alias GaPersonal.Evolution
  alias GaPersonal.Evolution.{BodyAssessment, EvolutionPhoto, Goal}

  describe "body_assessments" do
    setup do
      trainer = insert(:trainer)
      student = insert(:student_user)
      %{trainer: trainer, student: student}
    end

    test "list_body_assessments/1 returns assessments for student", %{trainer: trainer, student: student} do
      assessment = insert(:body_assessment, student: student, trainer: trainer)
      assert [%BodyAssessment{id: id}] = Evolution.list_body_assessments(student.id)
      assert id == assessment.id
    end

    test "create_body_assessment/1 with valid data", %{trainer: trainer, student: student} do
      attrs = %{
        student_id: student.id,
        trainer_id: trainer.id,
        assessment_date: Date.utc_today(),
        weight_kg: Decimal.new("80.5"),
        height_cm: Decimal.new("178.0")
      }

      assert {:ok, %BodyAssessment{}} = Evolution.create_body_assessment(attrs)
    end

    test "create_body_assessment/1 without required fields returns error" do
      assert {:error, %Ecto.Changeset{}} = Evolution.create_body_assessment(%{})
    end

    test "get_body_assessment_for_trainer/2 returns owned assessment", %{trainer: trainer, student: student} do
      assessment = insert(:body_assessment, student: student, trainer: trainer)
      assert {:ok, %BodyAssessment{}} = Evolution.get_body_assessment_for_trainer(assessment.id, trainer.id)
    end

    test "get_body_assessment_for_trainer/2 returns unauthorized for other trainer", %{trainer: trainer, student: student} do
      assessment = insert(:body_assessment, student: student, trainer: trainer)
      other = insert(:trainer)
      assert {:error, :unauthorized} = Evolution.get_body_assessment_for_trainer(assessment.id, other.id)
    end

    test "get_body_assessment_for_student/2 returns assessment for student", %{trainer: trainer, student: student} do
      assessment = insert(:body_assessment, student: student, trainer: trainer)
      assert {:ok, %BodyAssessment{}} = Evolution.get_body_assessment_for_student(assessment.id, student.id)
    end

    test "update_body_assessment/2 updates the assessment", %{trainer: trainer, student: student} do
      assessment = insert(:body_assessment, student: student, trainer: trainer)
      assert {:ok, %BodyAssessment{}} = Evolution.update_body_assessment(assessment, %{weight_kg: Decimal.new("79.0")})
    end

    test "delete_body_assessment/1 deletes the assessment", %{trainer: trainer, student: student} do
      assessment = insert(:body_assessment, student: student, trainer: trainer)
      assert {:ok, %BodyAssessment{}} = Evolution.delete_body_assessment(assessment)
    end
  end

  describe "evolution_photos" do
    setup do
      trainer = insert(:trainer)
      student = insert(:student_user)
      %{trainer: trainer, student: student}
    end

    test "list_evolution_photos/1 returns photos for student", %{trainer: trainer, student: student} do
      assessment = insert(:body_assessment, student: student, trainer: trainer)
      insert(:evolution_photo, student: student, body_assessment: assessment)
      assert length(Evolution.list_evolution_photos(student.id)) == 1
    end

    test "create_evolution_photo/1 with valid data", %{student: student} do
      attrs = %{
        student_id: student.id,
        photo_url: "https://storage.example.com/photo.jpg",
        photo_type: "front",
        taken_at: Date.utc_today()
      }

      assert {:ok, %EvolutionPhoto{}} = Evolution.create_evolution_photo(attrs)
    end

    test "create_evolution_photo/1 with invalid photo_type returns error", %{student: student} do
      attrs = %{
        student_id: student.id,
        photo_url: "https://storage.example.com/photo.jpg",
        photo_type: "invalid",
        taken_at: Date.utc_today()
      }

      assert {:error, %Ecto.Changeset{}} = Evolution.create_evolution_photo(attrs)
    end
  end

  describe "goals" do
    setup do
      trainer = insert(:trainer)
      student = insert(:student_user)
      %{trainer: trainer, student: student}
    end

    test "list_goals/1 returns goals for student", %{trainer: trainer, student: student} do
      goal = insert(:goal, student: student, trainer: trainer)
      assert [%Goal{id: id}] = Evolution.list_goals(student.id)
      assert id == goal.id
    end

    test "create_goal/1 with valid data", %{trainer: trainer, student: student} do
      attrs = %{
        student_id: student.id,
        trainer_id: trainer.id,
        goal_type: "weight_loss",
        title: "Lose 5kg",
        start_date: Date.utc_today()
      }

      assert {:ok, %Goal{title: "Lose 5kg"}} = Evolution.create_goal(attrs)
    end

    test "create_goal/1 with invalid goal_type returns error", %{trainer: trainer, student: student} do
      attrs = %{
        student_id: student.id,
        trainer_id: trainer.id,
        goal_type: "invalid",
        title: "Test",
        start_date: Date.utc_today()
      }

      assert {:error, %Ecto.Changeset{}} = Evolution.create_goal(attrs)
    end

    test "get_goal_for_trainer/2 returns owned goal", %{trainer: trainer, student: student} do
      goal = insert(:goal, student: student, trainer: trainer)
      assert {:ok, %Goal{}} = Evolution.get_goal_for_trainer(goal.id, trainer.id)
    end

    test "get_goal_for_student/2 returns student's goal", %{trainer: trainer, student: student} do
      goal = insert(:goal, student: student, trainer: trainer)
      assert {:ok, %Goal{}} = Evolution.get_goal_for_student(goal.id, student.id)
    end

    test "achieve_goal/1 marks goal as achieved", %{trainer: trainer, student: student} do
      goal = insert(:goal, student: student, trainer: trainer)
      assert {:ok, %Goal{status: "achieved"} = achieved} = Evolution.achieve_goal(goal)
      assert achieved.achieved_at != nil
    end

    test "update_goal/2 updates the goal", %{trainer: trainer, student: student} do
      goal = insert(:goal, student: student, trainer: trainer)
      assert {:ok, %Goal{current_value: val}} = Evolution.update_goal(goal, %{current_value: Decimal.new("78.0")})
      assert Decimal.equal?(val, Decimal.new("78.0"))
    end

    test "delete_goal/1 deletes the goal", %{trainer: trainer, student: student} do
      goal = insert(:goal, student: student, trainer: trainer)
      assert {:ok, %Goal{}} = Evolution.delete_goal(goal)
    end
  end
end
