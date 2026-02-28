defmodule GaPersonal.FinanceTest do
  use GaPersonal.DataCase, async: true

  alias GaPersonal.Finance
  alias GaPersonal.Finance.{Plan, Subscription, Payment}

  describe "plans" do
    setup do
      trainer = insert(:trainer)
      %{trainer: trainer}
    end

    test "list_plans/1 returns plans for trainer", %{trainer: trainer} do
      plan = insert(:plan, trainer: trainer)
      assert [%Plan{id: id}] = Finance.list_plans(trainer.id)
      assert id == plan.id
    end

    test "create_plan/1 with valid data", %{trainer: trainer} do
      attrs = %{
        trainer_id: trainer.id,
        name: "Monthly Plan",
        price_cents: 15_000,
        billing_period: "monthly"
      }

      assert {:ok, %Plan{name: "Monthly Plan"}} = Finance.create_plan(attrs)
    end

    test "create_plan/1 with invalid billing_period returns error", %{trainer: trainer} do
      attrs = %{trainer_id: trainer.id, name: "Test", price_cents: 100, billing_period: "invalid"}
      assert {:error, %Ecto.Changeset{}} = Finance.create_plan(attrs)
    end

    test "create_plan/1 with zero price returns error", %{trainer: trainer} do
      attrs = %{trainer_id: trainer.id, name: "Free", price_cents: 0, billing_period: "monthly"}
      assert {:error, %Ecto.Changeset{}} = Finance.create_plan(attrs)
    end

    test "get_plan_for_trainer/2 returns owned plan", %{trainer: trainer} do
      plan = insert(:plan, trainer: trainer)
      assert {:ok, %Plan{}} = Finance.get_plan_for_trainer(plan.id, trainer.id)
    end

    test "get_plan_for_trainer/2 returns unauthorized for other trainer", %{trainer: trainer} do
      plan = insert(:plan, trainer: trainer)
      other = insert(:trainer)
      assert {:error, :unauthorized} = Finance.get_plan_for_trainer(plan.id, other.id)
    end

    test "update_plan/2 updates the plan", %{trainer: trainer} do
      plan = insert(:plan, trainer: trainer)
      assert {:ok, %Plan{price_cents: 20_000}} = Finance.update_plan(plan, %{price_cents: 20_000})
    end

    test "delete_plan/1 deletes the plan", %{trainer: trainer} do
      plan = insert(:plan, trainer: trainer)
      assert {:ok, %Plan{}} = Finance.delete_plan(plan)
    end
  end

  describe "subscriptions" do
    setup do
      trainer = insert(:trainer)
      student = insert(:student_user)
      plan = insert(:plan, trainer: trainer)
      %{trainer: trainer, student: student, plan: plan}
    end

    test "list_subscriptions/1 returns subscriptions for trainer", ctx do
      sub = insert(:subscription, trainer: ctx.trainer, student: ctx.student, plan: ctx.plan)
      assert [%Subscription{id: id}] = Finance.list_subscriptions(ctx.trainer.id)
      assert id == sub.id
    end

    test "create_subscription/1 with valid data", ctx do
      attrs = %{
        student_id: ctx.student.id,
        plan_id: ctx.plan.id,
        trainer_id: ctx.trainer.id,
        start_date: Date.utc_today()
      }

      assert {:ok, %Subscription{status: "active"}} = Finance.create_subscription(attrs)
    end

    test "get_subscription_for_trainer/2 returns owned subscription", ctx do
      sub = insert(:subscription, trainer: ctx.trainer, student: ctx.student, plan: ctx.plan)
      assert {:ok, %Subscription{}} = Finance.get_subscription_for_trainer(sub.id, ctx.trainer.id)
    end

    test "get_subscription_for_trainer/2 returns unauthorized for other trainer", ctx do
      sub = insert(:subscription, trainer: ctx.trainer, student: ctx.student, plan: ctx.plan)
      other = insert(:trainer)
      assert {:error, :unauthorized} = Finance.get_subscription_for_trainer(sub.id, other.id)
    end

    test "cancel_subscription/2 cancels with reason", ctx do
      sub = insert(:subscription, trainer: ctx.trainer, student: ctx.student, plan: ctx.plan)
      assert {:ok, %Subscription{status: "cancelled"}} = Finance.cancel_subscription(sub, "No longer needed")
    end

    test "list_subscriptions_for_student/1 returns student's subscriptions", ctx do
      insert(:subscription, trainer: ctx.trainer, student: ctx.student, plan: ctx.plan)
      assert length(Finance.list_subscriptions_for_student(ctx.student.id)) == 1
    end
  end

  describe "payments" do
    setup do
      trainer = insert(:trainer)
      student = insert(:student_user)
      %{trainer: trainer, student: student}
    end

    test "list_payments/1 returns payments for trainer", %{trainer: trainer, student: student} do
      payment = insert(:payment, trainer: trainer, student: student)
      assert [%Payment{id: id}] = Finance.list_payments(trainer.id)
      assert id == payment.id
    end

    test "create_payment/1 with valid data", %{trainer: trainer, student: student} do
      attrs = %{
        student_id: student.id,
        trainer_id: trainer.id,
        amount_cents: 15_000,
        payment_method: "pix",
        due_date: Date.utc_today() |> Date.add(5)
      }

      assert {:ok, %Payment{status: "pending"}} = Finance.create_payment(attrs)
    end

    test "create_payment/1 with invalid payment_method returns error", %{trainer: trainer, student: student} do
      attrs = %{student_id: student.id, trainer_id: trainer.id, amount_cents: 100, payment_method: "bitcoin"}
      assert {:error, %Ecto.Changeset{}} = Finance.create_payment(attrs)
    end

    test "get_payment_for_trainer/2 returns owned payment", %{trainer: trainer, student: student} do
      payment = insert(:payment, trainer: trainer, student: student)
      assert {:ok, %Payment{}} = Finance.get_payment_for_trainer(payment.id, trainer.id)
    end

    test "get_payment_for_trainer/2 returns unauthorized for other trainer", %{trainer: trainer, student: student} do
      payment = insert(:payment, trainer: trainer, student: student)
      other = insert(:trainer)
      assert {:error, :unauthorized} = Finance.get_payment_for_trainer(payment.id, other.id)
    end

    test "update_payment/2 updates the payment", %{trainer: trainer, student: student} do
      payment = insert(:payment, trainer: trainer, student: student)
      assert {:ok, %Payment{status: "completed"}} = Finance.update_payment(payment, %{status: "completed"})
    end

    test "list_payments_for_student/1 returns student's payments", %{trainer: trainer, student: student} do
      insert(:payment, trainer: trainer, student: student)
      assert length(Finance.list_payments_for_student(student.id)) == 1
    end
  end
end
