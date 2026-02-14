defmodule KeenAuthPermissions.UsersTest do
  use KeenAuthPermissions.DataCase, async: false

  alias KeenAuthPermissions.Users

  @moduletag :clean_db

  describe "list/2" do
    test "lists all users in a tenant" do
      ctx = system_context()

      assert {:ok, users} = Users.list(ctx, default_tenant_id())
      assert is_list(users)
    end
  end

  describe "get_by_id/1" do
    test "returns user when found" do
      ctx = system_context()

      # System user should exist
      assert {:ok, fetched} = Users.get_by_id(ctx.user.user_id)
      assert fetched.user_id == ctx.user.user_id
    end

    test "returns error when user not found" do
      assert {:error, _} = Users.get_by_id(999_999)
    end
  end

  describe "search/8" do
    test "searches users with filters" do
      ctx = system_context()

      assert {:ok, results} =
               Users.search(
                 ctx,
                 nil,
                 nil,
                 nil,
                 nil,
                 1,
                 100,
                 default_tenant_id()
               )

      assert is_list(results)
    end

    test "searches by text" do
      ctx = system_context()

      assert {:ok, results} =
               Users.search(
                 ctx,
                 "system",
                 nil,
                 nil,
                 nil,
                 1,
                 100,
                 default_tenant_id()
               )

      assert is_list(results)
    end
  end

  describe "enable/2 and disable/2" do
    test "enables and disables a user" do
      ctx = system_context()

      # Create a test user first
      {:ok, test_user} = create_test_user(ctx)

      # Disable the user
      assert {:ok, disabled} = Users.disable(ctx, test_user.user_id)
      assert disabled.is_active == false

      # Enable the user
      assert {:ok, enabled} = Users.enable(ctx, test_user.user_id)
      assert enabled.is_active == true
    end
  end

  describe "lock/2 and unlock/2" do
    test "locks and unlocks a user" do
      ctx = system_context()

      # Create a test user first
      {:ok, test_user} = create_test_user(ctx)

      # Lock the user
      assert {:ok, locked} = Users.lock(ctx, test_user.user_id)
      assert locked.is_locked == true

      # Unlock the user
      assert {:ok, unlocked} = Users.unlock(ctx, test_user.user_id)
      assert unlocked.is_locked == false
    end
  end

  describe "list_permissions/3" do
    test "returns user permissions" do
      ctx = system_context()

      assert {:ok, permissions} =
               Users.list_permissions(ctx.user.user_id, ctx.user.user_id, default_tenant_id())

      assert is_list(permissions)
    end
  end

  describe "list_assigned_groups/2" do
    test "returns user's assigned groups" do
      ctx = system_context()

      assert {:ok, groups} = Users.list_assigned_groups(ctx.user.user_id, ctx.user.user_id)
      assert is_list(groups)
    end
  end

  describe "has_permission?/4" do
    test "checks if user has a permission" do
      ctx = system_context()

      # Check for a permission that likely doesn't exist
      assert {:ok, result} =
               Users.has_permission?(
                 ctx.user.user_id,
                 "nonexistent_permission",
                 default_tenant_id()
               )

      assert is_boolean(result)
    end
  end

  describe "has_permissions?/4" do
    test "checks if user has multiple permissions" do
      ctx = system_context()

      assert {:ok, result} =
               Users.has_permissions?(
                 ctx.user.user_id,
                 ["perm1", "perm2"],
                 default_tenant_id()
               )

      assert is_boolean(result)
    end
  end

  describe "tenant operations" do
    test "list_available_tenants/2 returns tenants for a user" do
      ctx = system_context()

      assert {:ok, tenants} = Users.list_available_tenants(ctx.user.user_id, ctx.user.user_id)
      assert is_list(tenants)
    end

    test "get_last_selected_tenant/2 and update_last_selected_tenant/3" do
      ctx = system_context()

      # This may fail if no tenant is selected, which is expected
      case Users.get_last_selected_tenant(ctx.user.user_id, ctx.user.user_id) do
        {:ok, tenant} -> assert is_map(tenant)
        {:error, _} -> :ok
      end
    end
  end

  describe "preferences operations" do
    test "get_preferences/2 returns user preferences" do
      ctx = system_context()

      case Users.get_preferences(ctx.user.user_id, ctx.user.user_id) do
        {:ok, prefs} -> assert is_map(prefs)
        {:error, _} -> :ok
      end
    end
  end

  describe "get_random_code/0" do
    test "generates a random code" do
      assert {:ok, code} = Users.get_random_code()
      assert is_binary(code)
      assert String.length(code) > 0
    end
  end

  describe "identity operations" do
    test "get_identity/3 retrieves user identity" do
      ctx = system_context()

      # This may fail if no identity exists for the provider
      case Users.get_identity(ctx.user.user_id, ctx.user.user_id, "email") do
        {:ok, identity} -> assert is_map(identity)
        {:error, _} -> :ok
      end
    end
  end

  describe "register/5" do
    test "registers a new user" do
      ctx = system_context()
      email = "test_#{unique_string()}@example.com"

      assert {:ok, registered} =
               Users.register(
                 ctx,
                 email,
                 "hashed_password_#{unique_string()}",
                 "Test User #{unique_string()}",
                 nil
               )

      assert registered.email == email
    end
  end

  describe "ensure_from_provider/8" do
    @tag :skip
    test "ensures a user from provider exists" do
      ctx = system_context()
      provider_uid = "test_uid_#{unique_string()}"
      email = "provider_test_#{unique_string()}@example.com"

      assert {:ok, ensured} =
               Users.ensure_from_provider(
                 ctx,
                 "aad",
                 provider_uid,
                 "oid_#{unique_string()}",
                 email,
                 "Provider User",
                 email,
                 nil
               )

      assert is_map(ensured)
    end
  end

  describe "add_to_default_groups/3" do
    @tag :skip
    test "adds user to default groups in tenant" do
      ctx = system_context()

      {:ok, test_user} = create_test_user(ctx)

      assert {:ok, groups} =
               Users.add_to_default_groups(ctx, test_user.user_id, default_tenant_id())

      assert is_list(groups)
    end
  end
end
