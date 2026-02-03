defmodule GaPersonal.Finance do
  @moduledoc """
  The Finance context - handles plans, subscriptions, and payments.
  """

  import Ecto.Query, warn: false
  alias GaPersonal.Repo
  alias GaPersonal.Finance.{Plan, Subscription, Payment}

  ## Plan functions

  def list_plans(trainer_id) do
    from(p in Plan,
      where: p.trainer_id == ^trainer_id,
      order_by: [p.price_cents]
    )
    |> Repo.all()
  end

  def get_plan!(id), do: Repo.get!(Plan, id)

  def create_plan(attrs \\ %{}) do
    %Plan{}
    |> Plan.changeset(attrs)
    |> Repo.insert()
  end

  def update_plan(%Plan{} = plan, attrs) do
    plan
    |> Plan.changeset(attrs)
    |> Repo.update()
  end

  def delete_plan(%Plan{} = plan) do
    Repo.delete(plan)
  end

  ## Subscription functions

  def list_subscriptions(trainer_id, filters \\ %{}) do
    query = from s in Subscription,
      where: s.trainer_id == ^trainer_id,
      preload: [:student, :plan],
      order_by: [desc: s.start_date]

    query
    |> apply_subscription_filters(filters)
    |> Repo.all()
  end

  defp apply_subscription_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {:status, status}, query ->
        from s in query, where: s.status == ^status

      {:student_id, student_id}, query ->
        from s in query, where: s.student_id == ^student_id

      _, query ->
        query
    end)
  end

  def get_subscription!(id) do
    Subscription
    |> Repo.get!(id)
    |> Repo.preload([:student, :plan, :payments])
  end

  def create_subscription(attrs \\ %{}) do
    %Subscription{}
    |> Subscription.changeset(attrs)
    |> Repo.insert()
  end

  def update_subscription(%Subscription{} = subscription, attrs) do
    subscription
    |> Subscription.changeset(attrs)
    |> Repo.update()
  end

  def cancel_subscription(%Subscription{} = subscription, reason) do
    update_subscription(subscription, %{
      status: "cancelled",
      cancellation_reason: reason,
      cancelled_at: DateTime.utc_now()
    })
  end

  ## Payment functions

  def list_payments(trainer_id, filters \\ %{}) do
    query = from p in Payment,
      where: p.trainer_id == ^trainer_id,
      preload: [:student, :subscription],
      order_by: [desc: p.payment_date]

    query
    |> apply_payment_filters(filters)
    |> Repo.all()
  end

  defp apply_payment_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {:status, status}, query ->
        from p in query, where: p.status == ^status

      {:student_id, student_id}, query ->
        from p in query, where: p.student_id == ^student_id

      {:date_from, date_from}, query ->
        from p in query, where: p.payment_date >= ^date_from

      {:date_to, date_to}, query ->
        from p in query, where: p.payment_date <= ^date_to

      _, query ->
        query
    end)
  end

  def create_payment(attrs \\ %{}) do
    %Payment{}
    |> Payment.changeset(attrs)
    |> Repo.insert()
  end

  def update_payment(%Payment{} = payment, attrs) do
    payment
    |> Payment.changeset(attrs)
    |> Repo.update()
  end
end
