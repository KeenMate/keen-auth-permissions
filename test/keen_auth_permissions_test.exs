defmodule KeenAuthPermissionsTest do
  @moduledoc """
  Basic smoke tests for KeenAuthPermissions library.
  """

  use ExUnit.Case

  describe "module availability" do
    test "UserGroups module is available" do
      assert Code.ensure_loaded?(KeenAuthPermissions.UserGroups)
    end

    test "Users module is available" do
      assert Code.ensure_loaded?(KeenAuthPermissions.Users)
    end

    test "Permissions module is available" do
      assert Code.ensure_loaded?(KeenAuthPermissions.Permissions)
    end

    test "Tenants module is available" do
      assert Code.ensure_loaded?(KeenAuthPermissions.Tenants)
    end

    test "ApiKeys module is available" do
      assert Code.ensure_loaded?(KeenAuthPermissions.ApiKeys)
    end

    test "Auth module is available" do
      assert Code.ensure_loaded?(KeenAuthPermissions.Auth)
    end

    test "PermSets module is available" do
      assert Code.ensure_loaded?(KeenAuthPermissions.PermSets)
    end

    test "User struct is available" do
      assert Code.ensure_loaded?(KeenAuthPermissions.User)
    end

    test "Database module is available" do
      assert Code.ensure_loaded?(KeenAuthPermissions.Database)
    end
  end

  describe "User struct" do
    test "can create a User struct" do
      user = %KeenAuthPermissions.User{
        user_id: 1,
        code: "test",
        uuid: nil,
        username: "test_user",
        email: "test@example.com",
        display_name: "Test User",
        groups: [],
        permissions: []
      }

      assert user.user_id == 1
      assert user.username == "test_user"
    end
  end
end
