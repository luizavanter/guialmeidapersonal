defmodule GaPersonal.ScheduleTest do
  use GaPersonal.DataCase, async: true

  alias GaPersonal.Schedule
  alias GaPersonal.Schedule.{TimeSlot, Appointment}

  describe "time_slots" do
    setup do
      trainer = insert(:trainer)
      %{trainer: trainer}
    end

    test "list_time_slots/1 returns slots for trainer", %{trainer: trainer} do
      slot = insert(:time_slot, trainer: trainer)
      assert [%TimeSlot{id: id}] = Schedule.list_time_slots(trainer.id)
      assert id == slot.id
    end

    test "list_time_slots/1 does not return other trainer's slots", %{trainer: _trainer} do
      other_trainer = insert(:trainer)
      insert(:time_slot, trainer: other_trainer)
      assert Schedule.list_time_slots(insert(:trainer).id) == []
    end

    test "create_time_slot/1 with valid data", %{trainer: trainer} do
      attrs = %{
        trainer_id: trainer.id,
        day_of_week: 1,
        start_time: ~T[09:00:00],
        end_time: ~T[10:00:00],
        slot_duration_minutes: 60
      }

      assert {:ok, %TimeSlot{}} = Schedule.create_time_slot(attrs)
    end

    test "create_time_slot/1 with invalid day_of_week", %{trainer: trainer} do
      attrs = %{trainer_id: trainer.id, day_of_week: 7, start_time: ~T[09:00:00], end_time: ~T[10:00:00]}
      assert {:error, %Ecto.Changeset{}} = Schedule.create_time_slot(attrs)
    end

    test "get_time_slot_for_trainer/2 returns slot when owned", %{trainer: trainer} do
      slot = insert(:time_slot, trainer: trainer)
      assert {:ok, %TimeSlot{}} = Schedule.get_time_slot_for_trainer(slot.id, trainer.id)
    end

    test "get_time_slot_for_trainer/2 returns unauthorized for other trainer", %{trainer: _trainer} do
      other_trainer = insert(:trainer)
      slot = insert(:time_slot, trainer: other_trainer)
      assert {:error, :unauthorized} = Schedule.get_time_slot_for_trainer(slot.id, insert(:trainer).id)
    end

    test "update_time_slot/2 updates the slot", %{trainer: trainer} do
      slot = insert(:time_slot, trainer: trainer)
      assert {:ok, %TimeSlot{is_available: false}} = Schedule.update_time_slot(slot, %{is_available: false})
    end

    test "delete_time_slot/1 deletes the slot", %{trainer: trainer} do
      slot = insert(:time_slot, trainer: trainer)
      assert {:ok, %TimeSlot{}} = Schedule.delete_time_slot(slot)
      assert_raise Ecto.NoResultsError, fn -> Schedule.get_time_slot!(slot.id) end
    end
  end

  describe "appointments" do
    setup do
      trainer = insert(:trainer)
      student = insert(:student_user)
      %{trainer: trainer, student: student}
    end

    test "list_appointments/1 returns appointments for trainer", %{trainer: trainer, student: student} do
      appt = insert(:appointment, trainer: trainer, student: student)
      assert [%Appointment{id: id}] = Schedule.list_appointments(trainer.id)
      assert id == appt.id
    end

    test "create_appointment/1 with valid data", %{trainer: trainer, student: student} do
      attrs = %{
        trainer_id: trainer.id,
        student_id: student.id,
        scheduled_at: DateTime.utc_now() |> DateTime.add(1, :day) |> DateTime.truncate(:second),
        duration_minutes: 60,
        status: "scheduled"
      }

      assert {:ok, %Appointment{}} = Schedule.create_appointment(attrs)
    end

    test "create_appointment/1 without required fields returns error" do
      assert {:error, %Ecto.Changeset{}} = Schedule.create_appointment(%{})
    end

    test "get_appointment_for_trainer/2 returns appointment when owned", %{trainer: trainer, student: student} do
      appt = insert(:appointment, trainer: trainer, student: student)
      assert {:ok, %Appointment{}} = Schedule.get_appointment_for_trainer(appt.id, trainer.id)
    end

    test "get_appointment_for_trainer/2 returns unauthorized for other trainer", %{trainer: trainer, student: student} do
      appt = insert(:appointment, trainer: trainer, student: student)
      other_trainer = insert(:trainer)
      assert {:error, :unauthorized} = Schedule.get_appointment_for_trainer(appt.id, other_trainer.id)
    end

    test "get_appointment_for_student/2 returns appointment for participant", %{trainer: trainer, student: student} do
      appt = insert(:appointment, trainer: trainer, student: student)
      assert {:ok, %Appointment{}} = Schedule.get_appointment_for_student(appt.id, student.id)
    end

    test "cancel_appointment/2 cancels with reason", %{trainer: trainer, student: student} do
      appt = insert(:appointment, trainer: trainer, student: student)
      assert {:ok, %Appointment{status: "cancelled"}} = Schedule.cancel_appointment(appt, "Schedule conflict")
    end

    test "list_appointments_for_student/1 returns student's appointments", %{trainer: trainer, student: student} do
      insert(:appointment, trainer: trainer, student: student)
      other_student = insert(:student_user)
      insert(:appointment, trainer: trainer, student: other_student)

      assert length(Schedule.list_appointments_for_student(student.id)) == 1
    end
  end
end
