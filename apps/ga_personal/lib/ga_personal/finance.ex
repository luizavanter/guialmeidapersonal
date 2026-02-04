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

  @doc """
  Gets a plan with ownership verification.
  """
  def get_plan_for_trainer(id, trainer_id) do
    case Repo.get(Plan, id) do
      nil ->
        {:error, :not_found}

      %Plan{trainer_id: ^trainer_id} = plan ->
        {:ok, plan}

      %Plan{} ->
        {:error, :unauthorized}
    end
  end

  def get_plan_for_trainer!(id, trainer_id) do
    plan = get_plan!(id)
    if plan.trainer_id == trainer_id, do: plan, else: raise(Ecto.NoResultsError, queryable: Plan)
  end

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

  @doc """
  Gets a subscription with ownership verification.
  """
  def get_subscription_for_trainer(id, trainer_id) do
    case get_subscription!(id) do
      nil ->
        {:error, :not_found}

      %Subscription{trainer_id: ^trainer_id} = subscription ->
        {:ok, subscription}

      %Subscription{} ->
        {:error, :unauthorized}
    end
  rescue
    Ecto.NoResultsError -> {:error, :not_found}
  end

  def get_subscription_for_trainer!(id, trainer_id) do
    subscription = get_subscription!(id)
    if subscription.trainer_id == trainer_id, do: subscription, else: raise(Ecto.NoResultsError, queryable: Subscription)
  end

  @doc """
  Gets the current subscription for a student.
  """
  def get_subscription_for_student(student_id) do
    from(s in Subscription,
      where: s.student_id == ^student_id and s.status == "active",
      preload: [:plan],
      order_by: [desc: s.start_date],
      limit: 1
    )
    |> Repo.one()
  end

  @doc """
  Lists subscriptions for a specific student.
  """
  def list_subscriptions_for_student(student_id, filters \\ %{}) do
    query = from s in Subscription,
      where: s.student_id == ^student_id,
      preload: [:plan],
      order_by: [desc: s.start_date]

    query
    |> apply_subscription_filters(filters)
    |> Repo.all()
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

  def get_payment!(id) do
    Payment
    |> Repo.get!(id)
    |> Repo.preload([:student, :subscription])
  end

  @doc """
  Gets a payment with ownership verification.
  """
  def get_payment_for_trainer(id, trainer_id) do
    case get_payment!(id) do
      nil ->
        {:error, :not_found}

      %Payment{trainer_id: ^trainer_id} = payment ->
        {:ok, payment}

      %Payment{} ->
        {:error, :unauthorized}
    end
  rescue
    Ecto.NoResultsError -> {:error, :not_found}
  end

  def get_payment_for_trainer!(id, trainer_id) do
    payment = get_payment!(id)
    if payment.trainer_id == trainer_id, do: payment, else: raise(Ecto.NoResultsError, queryable: Payment)
  end

  @doc """
  Lists payments for a specific student.
  """
  def list_payments_for_student(student_id, filters \\ %{}) do
    query = from p in Payment,
      where: p.student_id == ^student_id,
      preload: [:subscription],
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
