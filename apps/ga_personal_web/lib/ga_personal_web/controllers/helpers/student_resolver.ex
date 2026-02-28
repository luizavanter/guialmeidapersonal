defmodule GaPersonalWeb.Helpers.StudentResolver do
  @moduledoc """
  Resolves a student_id (which could be a profile ID or user ID) to a verified user_id.
  All schemas store student_id as a reference to the users table, but the frontend
  typically sends the student profile ID. This helper handles both cases.
  """

  alias GaPersonal.Accounts

  @doc """
  Resolves a student_id to a verified user_id, confirming trainer ownership.

  Returns:
    - {:ok, user_id} if the student belongs to the trainer
    - {:error, :not_found} if no student found
    - {:error, :forbidden} if the student belongs to another trainer
  """
  def resolve_and_verify_student(student_id, trainer_id) do
    # First try as profile ID (get_student_for_trainer expects profile ID)
    case Accounts.get_student_for_trainer(student_id, trainer_id) do
      {:ok, student} ->
        {:ok, student.user_id}

      {:error, :not_found} ->
        # Maybe it's a user_id - try to find the profile by user_id
        case Accounts.get_student_by_user_id(student_id) do
          nil ->
            {:error, :not_found}

          profile ->
            if profile.trainer_id == trainer_id do
              {:ok, student_id}
            else
              {:error, :forbidden}
            end
        end

      {:error, :unauthorized} ->
        {:error, :forbidden}
    end
  end
end
