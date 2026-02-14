defmodule KeenAuthPermissions.PermissionHelpersTest do
  @moduledoc """
  Tests for KeenAuthPermissions.PermissionHelpers module.
  """

  use ExUnit.Case

  alias KeenAuthPermissions.PermissionHelpers
  alias KeenAuthPermissions.User
  alias KeenAuthPermissions.RequestContext
  alias KeenAuthPermissions.Error.ErrorStruct

  # Test fixtures
  defp user_with_permissions(permissions, groups \\ []) do
    %User{
      user_id: 1,
      code: "test",
      uuid: "test-uuid",
      username: "test_user",
      email: "test@example.com",
      display_name: "Test User",
      groups: groups,
      permissions: permissions
    }
  end

  defp context_with_permissions(permissions, groups \\ []) do
    user = user_with_permissions(permissions, groups)
    RequestContext.new(user)
  end

  # ============================================================================
  # Boolean Checks
  # ============================================================================

  describe "has_any?/2" do
    test "returns true when user has one of the required permissions" do
      user = user_with_permissions(["admin.read", "users.list"])
      assert PermissionHelpers.has_any?(user, ["admin.read", "admin.write"])
    end

    test "returns true when user has all of the required permissions" do
      user = user_with_permissions(["admin.read", "admin.write"])
      assert PermissionHelpers.has_any?(user, ["admin.read", "admin.write"])
    end

    test "returns false when user has none of the required permissions" do
      user = user_with_permissions(["users.read"])
      refute PermissionHelpers.has_any?(user, ["admin.read", "admin.write"])
    end

    test "works with single permission string" do
      user = user_with_permissions(["admin.read"])
      assert PermissionHelpers.has_any?(user, "admin.read")
      refute PermissionHelpers.has_any?(user, "admin.write")
    end

    test "works with RequestContext" do
      ctx = context_with_permissions(["admin.read"])
      assert PermissionHelpers.has_any?(ctx, ["admin.read"])
      refute PermissionHelpers.has_any?(ctx, ["admin.write"])
    end

    test "returns false for empty permission list" do
      user = user_with_permissions(["admin.read"])
      refute PermissionHelpers.has_any?(user, [])
    end
  end

  describe "has_all?/2" do
    test "returns true when user has all required permissions" do
      user = user_with_permissions(["admin.read", "admin.write", "users.list"])
      assert PermissionHelpers.has_all?(user, ["admin.read", "admin.write"])
    end

    test "returns false when user is missing some permissions" do
      user = user_with_permissions(["admin.read"])
      refute PermissionHelpers.has_all?(user, ["admin.read", "admin.write"])
    end

    test "returns false when user has none of the required permissions" do
      user = user_with_permissions(["users.read"])
      refute PermissionHelpers.has_all?(user, ["admin.read", "admin.write"])
    end

    test "works with RequestContext" do
      ctx = context_with_permissions(["admin.read", "admin.write"])
      assert PermissionHelpers.has_all?(ctx, ["admin.read", "admin.write"])
      refute PermissionHelpers.has_all?(ctx, ["admin.read", "admin.delete"])
    end

    test "returns true for empty required list" do
      user = user_with_permissions(["admin.read"])
      assert PermissionHelpers.has_all?(user, [])
    end
  end

  describe "in_any_group?/2" do
    test "returns true when user is in one of the required groups" do
      user = user_with_permissions([], ["admins", "users"])
      assert PermissionHelpers.in_any_group?(user, ["admins", "moderators"])
    end

    test "returns false when user is not in any required group" do
      user = user_with_permissions([], ["users"])
      refute PermissionHelpers.in_any_group?(user, ["admins", "moderators"])
    end

    test "works with RequestContext" do
      ctx = context_with_permissions([], ["admins"])
      assert PermissionHelpers.in_any_group?(ctx, ["admins"])
      refute PermissionHelpers.in_any_group?(ctx, ["moderators"])
    end
  end

  describe "in_all_groups?/2" do
    test "returns true when user is in all required groups" do
      user = user_with_permissions([], ["admins", "users", "editors"])
      assert PermissionHelpers.in_all_groups?(user, ["admins", "users"])
    end

    test "returns false when user is missing some groups" do
      user = user_with_permissions([], ["admins"])
      refute PermissionHelpers.in_all_groups?(user, ["admins", "moderators"])
    end

    test "works with RequestContext" do
      ctx = context_with_permissions([], ["admins", "users"])
      assert PermissionHelpers.in_all_groups?(ctx, ["admins", "users"])
      refute PermissionHelpers.in_all_groups?(ctx, ["admins", "moderators"])
    end
  end

  # ============================================================================
  # Result-Based Checks
  # ============================================================================

  describe "require_any/2" do
    test "returns {:ok, :authorized} when user has required permission" do
      user = user_with_permissions(["admin.read"])
      assert {:ok, :authorized} = PermissionHelpers.require_any(user, ["admin.read"])
    end

    test "returns {:error, ErrorStruct} when user lacks permission" do
      user = user_with_permissions(["users.read"])

      assert {:error, %ErrorStruct{reason: :no_permission} = error} =
               PermissionHelpers.require_any(user, ["admin.read", "admin.write"])

      assert error.metadata.mode == :any
      assert error.metadata.required == ["admin.read", "admin.write"]
    end

    test "works with single permission string" do
      user = user_with_permissions(["admin.read"])
      assert {:ok, :authorized} = PermissionHelpers.require_any(user, "admin.read")

      assert {:error, %ErrorStruct{}} = PermissionHelpers.require_any(user, "admin.write")
    end

    test "works in with blocks" do
      user = user_with_permissions(["admin.read"])

      result =
        with {:ok, :authorized} <- PermissionHelpers.require_any(user, ["admin.read"]) do
          {:ok, "success"}
        end

      assert {:ok, "success"} = result
    end

    test "short-circuits with block on failure" do
      user = user_with_permissions(["users.read"])

      result =
        with {:ok, :authorized} <- PermissionHelpers.require_any(user, ["admin.read"]),
             {:ok, _} <- {:ok, "should not reach"} do
          {:ok, "success"}
        end

      assert {:error, %ErrorStruct{reason: :no_permission}} = result
    end
  end

  describe "require_all/2" do
    test "returns {:ok, :authorized} when user has all required permissions" do
      user = user_with_permissions(["admin.read", "admin.write"])

      assert {:ok, :authorized} =
               PermissionHelpers.require_all(user, ["admin.read", "admin.write"])
    end

    test "returns {:error, ErrorStruct} with missing list when user lacks permissions" do
      user = user_with_permissions(["admin.read"])

      assert {:error, %ErrorStruct{reason: :no_permission} = error} =
               PermissionHelpers.require_all(user, ["admin.read", "admin.write", "admin.delete"])

      assert error.metadata.mode == :all
      assert error.metadata.missing == ["admin.write", "admin.delete"]
    end
  end

  describe "require_any_group/2" do
    test "returns {:ok, :authorized} when user is in required group" do
      user = user_with_permissions([], ["admins"])

      assert {:ok, :authorized} =
               PermissionHelpers.require_any_group(user, ["admins", "moderators"])
    end

    test "returns {:error, ErrorStruct} when user is not in any required group" do
      user = user_with_permissions([], ["users"])

      assert {:error, %ErrorStruct{reason: :no_permission} = error} =
               PermissionHelpers.require_any_group(user, ["admins", "moderators"])

      assert error.metadata.required_groups == ["admins", "moderators"]
    end
  end

  describe "require_all_groups/2" do
    test "returns {:ok, :authorized} when user is in all required groups" do
      user = user_with_permissions([], ["admins", "users"])
      assert {:ok, :authorized} = PermissionHelpers.require_all_groups(user, ["admins", "users"])
    end

    test "returns {:error, ErrorStruct} with missing groups when user lacks some" do
      user = user_with_permissions([], ["admins"])

      assert {:error, %ErrorStruct{reason: :no_permission} = error} =
               PermissionHelpers.require_all_groups(user, ["admins", "moderators"])

      assert error.metadata.missing_groups == ["moderators"]
    end
  end

  # ============================================================================
  # Execution Helpers
  # ============================================================================

  describe "with_permission/3" do
    test "executes function when user has permission" do
      user = user_with_permissions(["admin.read"])

      result =
        PermissionHelpers.with_permission(user, ["admin.read"], fn ->
          {:ok, "executed"}
        end)

      assert {:ok, "executed"} = result
    end

    test "returns error without executing when user lacks permission" do
      user = user_with_permissions(["users.read"])

      result =
        PermissionHelpers.with_permission(user, ["admin.read"], fn ->
          raise "should not execute"
        end)

      assert {:error, %ErrorStruct{reason: :no_permission}} = result
    end

    test "works with single permission string" do
      user = user_with_permissions(["admin.read"])

      result =
        PermissionHelpers.with_permission(user, "admin.read", fn ->
          {:ok, "executed"}
        end)

      assert {:ok, "executed"} = result
    end

    test "propagates function return value" do
      user = user_with_permissions(["admin.read"])

      result =
        PermissionHelpers.with_permission(user, ["admin.read"], fn ->
          {:error, :custom_error}
        end)

      assert {:error, :custom_error} = result
    end
  end

  describe "with_all_permissions/3" do
    test "executes function when user has all permissions" do
      user = user_with_permissions(["admin.read", "admin.write"])

      result =
        PermissionHelpers.with_all_permissions(user, ["admin.read", "admin.write"], fn ->
          {:ok, "executed"}
        end)

      assert {:ok, "executed"} = result
    end

    test "returns error when user lacks some permissions" do
      user = user_with_permissions(["admin.read"])

      result =
        PermissionHelpers.with_all_permissions(user, ["admin.read", "admin.write"], fn ->
          raise "should not execute"
        end)

      assert {:error, %ErrorStruct{reason: :no_permission}} = result
    end
  end

  describe "with_group/3" do
    test "executes function when user is in required group" do
      user = user_with_permissions([], ["admins"])

      result =
        PermissionHelpers.with_group(user, ["admins", "moderators"], fn ->
          {:ok, "executed"}
        end)

      assert {:ok, "executed"} = result
    end

    test "returns error when user is not in any required group" do
      user = user_with_permissions([], ["users"])

      result =
        PermissionHelpers.with_group(user, ["admins"], fn ->
          raise "should not execute"
        end)

      assert {:error, %ErrorStruct{reason: :no_permission}} = result
    end
  end

  # ============================================================================
  # Utility Functions
  # ============================================================================

  describe "find_missing/2" do
    test "returns list of missing permissions" do
      user = user_with_permissions(["admin.read"])

      missing =
        PermissionHelpers.find_missing(user, ["admin.read", "admin.write", "admin.delete"])

      assert missing == ["admin.write", "admin.delete"]
    end

    test "returns empty list when user has all permissions" do
      user = user_with_permissions(["admin.read", "admin.write"])
      assert [] = PermissionHelpers.find_missing(user, ["admin.read", "admin.write"])
    end

    test "works with RequestContext" do
      ctx = context_with_permissions(["admin.read"])
      missing = PermissionHelpers.find_missing(ctx, ["admin.read", "admin.write"])
      assert missing == ["admin.write"]
    end
  end

  describe "find_missing_groups/2" do
    test "returns list of missing groups" do
      user = user_with_permissions([], ["admins"])
      missing = PermissionHelpers.find_missing_groups(user, ["admins", "moderators", "editors"])
      assert missing == ["moderators", "editors"]
    end

    test "returns empty list when user is in all groups" do
      user = user_with_permissions([], ["admins", "users"])
      assert [] = PermissionHelpers.find_missing_groups(user, ["admins", "users"])
    end

    test "works with RequestContext" do
      ctx = context_with_permissions([], ["admins"])
      missing = PermissionHelpers.find_missing_groups(ctx, ["admins", "moderators"])
      assert missing == ["moderators"]
    end
  end
end
