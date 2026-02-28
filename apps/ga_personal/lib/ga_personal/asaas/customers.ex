defmodule GaPersonal.Asaas.Customers do
  @moduledoc """
  Asaas Customer API.
  Manages customer records in Asaas for payment processing.
  """

  alias GaPersonal.Asaas.Client

  @doc """
  Creates a customer in Asaas.

  Required fields:
    - name: Customer full name
    - cpfCnpj: CPF or CNPJ (Brazilian tax ID)

  Optional fields:
    - email, phone, mobilePhone, postalCode, address, etc.
  """
  def create(attrs) when is_map(attrs) do
    Client.post("/customers", attrs)
  end

  @doc """
  Updates an existing customer in Asaas.
  """
  def update(customer_id, attrs) when is_binary(customer_id) and is_map(attrs) do
    Client.put("/customers/#{customer_id}", attrs)
  end

  @doc """
  Gets a customer by Asaas ID.
  """
  def get(customer_id) when is_binary(customer_id) do
    Client.get("/customers/#{customer_id}")
  end

  @doc """
  Finds a customer by CPF/CNPJ.
  """
  def find_by_cpf(cpf) when is_binary(cpf) do
    case Client.get("/customers", query: [cpfCnpj: cpf]) do
      {:ok, %{"data" => [customer | _]}} -> {:ok, customer}
      {:ok, %{"data" => []}} -> {:error, :not_found}
      error -> error
    end
  end

  @doc """
  Finds a customer by email.
  """
  def find_by_email(email) when is_binary(email) do
    case Client.get("/customers", query: [email: email]) do
      {:ok, %{"data" => [customer | _]}} -> {:ok, customer}
      {:ok, %{"data" => []}} -> {:error, :not_found}
      error -> error
    end
  end

  @doc """
  Builds Asaas customer params from a user and student profile.
  """
  def build_customer_params(user, student_profile \\ nil) do
    params = %{
      "name" => user.full_name,
      "email" => user.email
    }

    params =
      if user.phone && user.phone != "" do
        Map.put(params, "mobilePhone", user.phone)
      else
        params
      end

    params =
      if student_profile && student_profile.cpf && student_profile.cpf != "" do
        Map.put(params, "cpfCnpj", student_profile.cpf)
      else
        params
      end

    params
  end
end
