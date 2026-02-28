defmodule GaPersonal.Workers.AsaasCustomerSync do
  @moduledoc """
  Oban worker that syncs a student to Asaas as a customer.
  Triggered when a new student is created.
  """
  use Oban.Worker, queue: :default, max_attempts: 3

  require Logger

  alias GaPersonal.Accounts
  alias GaPersonal.Asaas.Customers

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"student_profile_id" => profile_id}}) do
    profile = Accounts.get_student(profile_id)

    cond do
      is_nil(profile) ->
        Logger.warning("AsaasCustomerSync: Student profile #{profile_id} not found")
        :ok

      profile.asaas_customer_id != nil ->
        Logger.info("AsaasCustomerSync: Student #{profile_id} already has Asaas customer")
        :ok

      !asaas_configured?() ->
        Logger.info("AsaasCustomerSync: Asaas not configured, skipping sync")
        :ok

      true ->
        sync_customer(profile)
    end
  end

  defp sync_customer(profile) do
    user = profile.user
    params = Customers.build_customer_params(user, profile)

    case Customers.create(params) do
      {:ok, %{"id" => asaas_id}} ->
        Accounts.update_student_profile(profile, %{asaas_customer_id: asaas_id})
        Logger.info("AsaasCustomerSync: Created Asaas customer #{asaas_id} for student #{profile.id}")
        :ok

      {:error, %{status: 409}} ->
        # Customer already exists, try to find by email
        case Customers.find_by_email(user.email) do
          {:ok, %{"id" => asaas_id}} ->
            Accounts.update_student_profile(profile, %{asaas_customer_id: asaas_id})
            Logger.info("AsaasCustomerSync: Linked existing Asaas customer #{asaas_id} for student #{profile.id}")
            :ok

          _ ->
            Logger.warning("AsaasCustomerSync: Customer conflict but could not find by email")
            :ok
        end

      {:error, :api_key_not_configured} ->
        Logger.info("AsaasCustomerSync: API key not configured, skipping")
        :ok

      {:error, reason} ->
        Logger.error("AsaasCustomerSync: Failed to create customer: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp asaas_configured? do
    Application.get_env(:ga_personal, :asaas)[:api_key] != nil
  end

  @doc """
  Enqueues a customer sync job for a student profile.
  """
  def enqueue(student_profile_id) do
    %{student_profile_id: student_profile_id}
    |> __MODULE__.new()
    |> Oban.insert()
  end
end
