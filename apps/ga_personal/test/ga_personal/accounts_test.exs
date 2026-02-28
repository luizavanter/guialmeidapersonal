defmodule GaPersonal.AccountsTest do
  use GaPersonal.DataCase, async: true

  alias GaPersonal.Accounts
  alias GaPersonal.Accounts.{User, StudentProfile, RefreshToken}

  describe "users" do
    test "list_users/0 returns all users" do
      user = insert(:user)
      assert [%User{id: id}] = Accounts.list_users()
      assert id == user.id
    end

    test "get_user/1 returns the user with given id" do
      user = insert(:user)
      assert %User{id: id} = Accounts.get_user(user.id)
      assert id == user.id
    end

    test "get_user/1 returns nil for non-existent id" do
      assert Accounts.get_user(Ecto.UUID.generate()) == nil
    end

    test "get_user!/1 raises for non-existent id" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_user!(Ecto.UUID.generate())
      end
    end

    test "get_user_by_email/1 returns user with given email" do
      user = insert(:user, email: "test@example.com")
      assert %User{id: id} = Accounts.get_user_by_email("test@example.com")
      assert id == user.id
    end

    test "get_user_by_email/1 returns nil for non-existent email" do
      assert Accounts.get_user_by_email("nonexistent@example.com") == nil
    end

    test "create_user/1 with valid data creates a user" do
      attrs = %{
        email: "new@example.com",
        password: "Password123!",
        role: "trainer",
        full_name: "New User"
      }

      assert {:ok, %User{} = user} = Accounts.create_user(attrs)
      assert user.email == "new@example.com"
      assert user.role == "trainer"
      assert user.full_name == "New User"
      assert user.password_hash != nil
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(%{})
    end

    test "create_user/1 with duplicate email returns error" do
      insert(:user, email: "taken@example.com")
      attrs = %{email: "taken@example.com", password: "Pass123!", role: "trainer", full_name: "Dup"}

      assert {:error, %Ecto.Changeset{} = changeset} = Accounts.create_user(attrs)
      assert "has already been taken" in errors_on(changeset).email
    end

    test "create_user/1 with invalid role returns error" do
      attrs = %{email: "test@example.com", password: "Pass123!", role: "invalid", full_name: "Test"}
      assert {:error, %Ecto.Changeset{} = changeset} = Accounts.create_user(attrs)
      assert errors_on(changeset).role != nil
    end

    test "update_user/2 with valid data updates the user" do
      user = insert(:user)
      assert {:ok, %User{} = updated} = Accounts.update_user(user, %{full_name: "Updated Name"})
      assert updated.full_name == "Updated Name"
    end

    test "delete_user/1 deletes the user" do
      user = insert(:user)
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert Accounts.get_user(user.id) == nil
    end
  end

  describe "authenticate/2" do
    test "returns user with valid credentials" do
      insert(:user, email: "auth@test.com", password: "Password123!")
      assert {:ok, %User{email: "auth@test.com"}} = Accounts.authenticate("auth@test.com", "Password123!")
    end

    test "returns error with wrong password" do
      insert(:user, email: "auth@test.com", password: "Password123!")
      assert {:error, :invalid_credentials} = Accounts.authenticate("auth@test.com", "wrongpassword")
    end

    test "returns error for non-existent email" do
      assert {:error, :invalid_credentials} = Accounts.authenticate("nobody@test.com", "anypassword")
    end

    test "returns error for inactive user" do
      insert(:user, email: "inactive@test.com", password: "Password123!", active: false)
      assert {:error, :inactive_user} = Accounts.authenticate("inactive@test.com", "Password123!")
    end
  end

  describe "refresh tokens" do
    test "create_refresh_token/1 creates a valid token" do
      user = insert(:user)
      assert {:ok, raw_token, %RefreshToken{} = record} = Accounts.create_refresh_token(user)
      assert is_binary(raw_token)
      assert record.user_id == user.id
      assert record.revoked_at == nil
    end

    test "verify_refresh_token/1 verifies a valid token" do
      user = insert(:user)
      {:ok, raw_token, _record} = Accounts.create_refresh_token(user)
      assert {:ok, %RefreshToken{}} = Accounts.verify_refresh_token(raw_token)
    end

    test "verify_refresh_token/1 rejects invalid token" do
      assert {:error, :invalid_token} = Accounts.verify_refresh_token("invalid-token")
    end

    test "verify_refresh_token/1 rejects revoked token" do
      user = insert(:user)
      {:ok, raw_token, record} = Accounts.create_refresh_token(user)
      Accounts.revoke_refresh_token(record)
      assert {:error, :token_revoked} = Accounts.verify_refresh_token(raw_token)
    end

    test "verify_refresh_token/1 rejects expired token" do
      user = insert(:user)
      {:ok, raw_token, record} = Accounts.create_refresh_token(user)

      # Manually expire the token
      record
      |> Ecto.Changeset.change(%{expires_at: DateTime.utc_now() |> DateTime.add(-1, :day) |> DateTime.truncate(:second)})
      |> Repo.update!()

      assert {:error, :token_expired} = Accounts.verify_refresh_token(raw_token)
    end

    test "rotate_refresh_token/1 revokes old and creates new" do
      user = insert(:user)
      {:ok, raw_token, old_record} = Accounts.create_refresh_token(user)

      assert {:ok, new_raw_token, _new_record, returned_user} = Accounts.rotate_refresh_token(raw_token)
      assert new_raw_token != raw_token
      assert returned_user.id == user.id

      # Old token should be revoked
      assert {:error, :token_revoked} = Accounts.verify_refresh_token(raw_token)

      # New token should be valid
      assert {:ok, %RefreshToken{}} = Accounts.verify_refresh_token(new_raw_token)
    end

    test "revoke_all_refresh_tokens/1 revokes all tokens for user" do
      user = insert(:user)
      {:ok, token1, _} = Accounts.create_refresh_token(user)
      {:ok, token2, _} = Accounts.create_refresh_token(user)

      {count, _} = Accounts.revoke_all_refresh_tokens(user)
      assert count == 2

      assert {:error, :token_revoked} = Accounts.verify_refresh_token(token1)
      assert {:error, :token_revoked} = Accounts.verify_refresh_token(token2)
    end
  end

  describe "student profiles" do
    setup do
      trainer = insert(:trainer)
      student_user = insert(:student_user)
      profile = insert(:student_profile, user: student_user, trainer: trainer)
      %{trainer: trainer, student_user: student_user, profile: profile}
    end

    test "list_students/1 returns students for trainer", %{trainer: trainer, profile: profile} do
      students = Accounts.list_students(trainer.id)
      assert length(students) == 1
      assert hd(students).id == profile.id
    end

    test "list_students/1 does not return other trainer's students", %{profile: _profile} do
      other_trainer = insert(:trainer)
      assert Accounts.list_students(other_trainer.id) == []
    end

    test "list_students/2 filters by status", %{trainer: trainer, profile: _profile} do
      other_student = insert(:student_user)
      insert(:student_profile, user: other_student, trainer: trainer, status: "cancelled")

      assert length(Accounts.list_students(trainer.id, %{status: "active"})) == 1
      assert length(Accounts.list_students(trainer.id, %{status: "cancelled"})) == 1
    end

    test "get_student/1 returns profile with user preloaded", %{profile: profile} do
      found = Accounts.get_student(profile.id)
      assert found.id == profile.id
      assert found.user != nil
    end

    test "get_student_for_trainer/2 returns profile when owned", %{trainer: trainer, profile: profile} do
      assert {:ok, %StudentProfile{}} = Accounts.get_student_for_trainer(profile.id, trainer.id)
    end

    test "get_student_for_trainer/2 returns unauthorized for other trainer", %{profile: profile} do
      other_trainer = insert(:trainer)
      assert {:error, :unauthorized} = Accounts.get_student_for_trainer(profile.id, other_trainer.id)
    end

    test "get_student_for_trainer/2 returns not_found for missing id", %{trainer: trainer} do
      assert {:error, :not_found} = Accounts.get_student_for_trainer(Ecto.UUID.generate(), trainer.id)
    end

    test "deactivate_student/1 sets status to cancelled", %{profile: profile} do
      assert {:ok, %StudentProfile{status: "cancelled"}} = Accounts.deactivate_student(profile)
    end
  end
end
