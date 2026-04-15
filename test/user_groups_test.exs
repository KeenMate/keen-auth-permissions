defmodule KeenAuthPermissions.UserGroupsTest do
  use KeenAuthPermissions.DataCase, async: false

  alias KeenAuthPermissions.UserGroups

  @moduletag :clean_db

  describe "list/2" do
    test "lists all groups in a tenant" do
      ctx = system_context()

      assert {:ok, groups} = UserGroups.list(ctx, default_tenant_id())
      assert is_list(groups)
    end
  end

  describe "create/7 and get_by_id/3" do
    test "creates a new user group and retrieves it" do
      ctx = system_context()
      title = "Test Group #{unique_string()}"

      assert {:ok, created} =
               UserGroups.create(ctx, title, true, true, false, false, default_tenant_id())

      assert created.title == title

      # Retrieve the created group
      assert {:ok, fetched} =
               UserGroups.get_by_id(ctx, created.user_group_id, default_tenant_id())

      assert fetched.title == title
      assert fetched.is_assignable == true
      assert fetched.is_active == true
    end

    test "returns error when group not found" do
      ctx = system_context()

      assert {:error, :not_found} = UserGroups.get_by_id(ctx, 999_999, default_tenant_id())
    end
  end

  describe "update/8" do
    test "updates an existing user group" do
      ctx = system_context()

      # Create a group first
      {:ok, created} = create_test_group(ctx)

      new_title = "Updated #{unique_string()}"

      assert {:ok, updated} =
               UserGroups.update(
                 ctx,
                 created.user_group_id,
                 new_title,
                 false,
                 true,
                 false,
                 false,
                 default_tenant_id()
               )

      assert updated.title == new_title
      assert updated.is_assignable == false
    end
  end

  describe "enable/3 and disable/3" do
    test "enables and disables a user group" do
      ctx = system_context()

      # Create a group
      {:ok, created} = create_test_group(ctx, %{is_active: true})

      # Disable it
      assert {:ok, disabled} =
               UserGroups.disable(ctx, created.user_group_id, default_tenant_id())

      assert disabled.is_active == false

      # Enable it again
      assert {:ok, enabled} = UserGroups.enable(ctx, created.user_group_id, default_tenant_id())
      assert enabled.is_active == true
    end
  end

  describe "lock/3 and unlock/3" do
    test "locks and unlocks a user group" do
      ctx = system_context()

      # Create a group
      {:ok, created} = create_test_group(ctx)

      # Lock it - returns the group
      assert {:ok, locked} = UserGroups.lock(ctx, created.user_group_id, default_tenant_id())
      assert locked.user_group_id == created.user_group_id

      # Unlock it - returns the group
      assert {:ok, unlocked} = UserGroups.unlock(ctx, created.user_group_id, default_tenant_id())
      assert unlocked.user_group_id == created.user_group_id
    end
  end

  describe "delete/3" do
    test "deletes a user group" do
      ctx = system_context()

      # Create a group
      {:ok, created} = create_test_group(ctx)

      # Delete it
      assert {:ok, _deleted} = UserGroups.delete(ctx, created.user_group_id, default_tenant_id())

      # Verify it's gone
      assert {:error, :not_found} =
               UserGroups.get_by_id(ctx, created.user_group_id, default_tenant_id())
    end
  end

  describe "search/6" do
    test "searches user groups with filters" do
      ctx = system_context()

      # Create a group with a unique title
      unique_title = "SearchTest #{unique_string()}"
      {:ok, _created} = create_test_group(ctx, %{title: unique_title})

      # Search for it
      assert {:ok, results} =
               UserGroups.search(
                 ctx,
                 %{search_text: "SearchTest"},
                 1,
                 100,
                 default_tenant_id()
               )

      assert is_list(results)
      assert Enum.any?(results, fn g -> g.title == unique_title end)
    end
  end

  describe "member operations" do
    test "add_member/4 and remove_member/4" do
      ctx = system_context()

      # Create a group
      {:ok, group} = create_test_group(ctx)

      # Add a member (using the system user as target for simplicity)
      target_user_id = ctx.user.user_id

      assert {:ok, membership} =
               UserGroups.add_member(
                 ctx,
                 group.user_group_id,
                 target_user_id,
                 default_tenant_id()
               )

      assert membership.user_id == target_user_id

      # List members
      assert {:ok, members} =
               UserGroups.list_members(ctx, group.user_group_id, default_tenant_id())

      assert Enum.any?(members, fn m -> m.user_id == target_user_id end)

      # Remove the member
      assert :ok =
               UserGroups.remove_member(
                 ctx,
                 group.user_group_id,
                 target_user_id,
                 default_tenant_id()
               )
    end

    test "list_members/3 returns empty list for new group" do
      ctx = system_context()

      {:ok, group} = create_test_group(ctx)

      assert {:ok, members} =
               UserGroups.list_members(ctx, group.user_group_id, default_tenant_id())

      assert members == []
    end
  end

  describe "is_member?/3" do
    test "returns true when user is a member" do
      ctx = system_context()

      {:ok, group} = create_test_group(ctx)

      {:ok, _} =
        UserGroups.add_member(ctx, group.user_group_id, ctx.user.user_id, default_tenant_id())

      assert {:ok, true} =
               UserGroups.is_member?(ctx.user.user_id, group.user_group_id, default_tenant_id())
    end

    test "returns false when user is not a member" do
      ctx = system_context()

      {:ok, group} = create_test_group(ctx)

      # Use a real, existing user that simply isn't a member of this group.
      # (A non-existent user id would trip `user_group_id_cache.user_id_fkey`.)
      assert {:ok, false} =
               UserGroups.is_member?(ctx.user.user_id, group.user_group_id, default_tenant_id())
    end
  end

  describe "mapping operations" do
    test "create_mapping/7, list_mappings/3, and delete_mapping/3" do
      ctx = system_context()
      provider = ensure_entra_provider()

      {:ok, group} = create_test_group(ctx, %{is_external: true})

      # Create a mapping
      assert {:ok, mapping} =
               UserGroups.create_mapping(
                 ctx,
                 group.user_group_id,
                 provider,
                 "object-id-#{unique_string()}",
                 "Test AD Group",
                 nil,
                 default_tenant_id()
               )

      assert mapping.user_group_id == group.user_group_id

      # List mappings
      assert {:ok, mappings} =
               UserGroups.list_mappings(ctx, group.user_group_id, default_tenant_id())

      assert length(mappings) >= 1

      # Delete the mapping
      assert :ok =
               UserGroups.delete_mapping(
                 ctx,
                 mapping.user_group_mapping_id,
                 default_tenant_id()
               )
    end
  end

  describe "owner operations" do
    test "create_owner/4 and is_owner?/3" do
      ctx = system_context()

      {:ok, group} = create_test_group(ctx)

      # Create owner
      assert {:ok, _owner} =
               UserGroups.create_owner(
                 ctx,
                 ctx.user.user_id,
                 group.user_group_id,
                 default_tenant_id()
               )

      # Check if user is owner
      assert {:ok, true} =
               UserGroups.is_owner?(ctx.user.user_id, group.user_group_id, default_tenant_id())

      # Check has_owner
      assert {:ok, true} = UserGroups.has_owner?(group.user_group_id, default_tenant_id())
    end
  end

  describe "permission operations" do
    test "list_assigned_permissions/3 returns permissions for a group" do
      ctx = system_context()

      {:ok, group} = create_test_group(ctx)

      assert {:ok, permissions} =
               UserGroups.list_assigned_permissions(ctx, group.user_group_id, default_tenant_id())

      assert is_list(permissions)
    end

    test "list_effective_permissions/3 returns effective permissions" do
      ctx = system_context()

      {:ok, group} = create_test_group(ctx)

      assert {:ok, permissions} =
               UserGroups.list_effective_permissions(
                 ctx,
                 group.user_group_id,
                 default_tenant_id()
               )

      assert is_list(permissions)
    end
  end

  describe "external group operations" do
    test "create_external/9 creates an external group" do
      ctx = system_context()
      provider = ensure_entra_provider()

      assert {:ok, result} =
               UserGroups.create_external(
                 ctx,
                 "Test External Group #{unique_string()}",
                 provider,
                 true,
                 true,
                 "object-id-#{unique_string()}",
                 "AD Group Name",
                 nil,
                 default_tenant_id()
               )

      # The stored procedure returns the created group ID
      assert is_integer(result.create_external_user_group)

      # Verify by fetching the group
      {:ok, group} =
        UserGroups.get_by_id(ctx, result.create_external_user_group, default_tenant_id())

      assert group.is_external == true
    end

    test "set_as_external/3, set_as_internal/3, set_as_hybrid/3" do
      ctx = system_context()

      {:ok, group} = create_test_group(ctx)

      # Set as external - these functions return :ok on success (no return value)
      assert :ok = UserGroups.set_as_external(ctx, group.user_group_id, default_tenant_id())

      # Verify by fetching the group
      {:ok, external} = UserGroups.get_by_id(ctx, group.user_group_id, default_tenant_id())
      assert external.is_external == true

      # Set as internal
      assert :ok = UserGroups.set_as_internal(ctx, group.user_group_id, default_tenant_id())

      # Verify by fetching
      {:ok, internal} = UserGroups.get_by_id(ctx, group.user_group_id, default_tenant_id())
      assert internal.is_external == false

      # Set as hybrid
      assert :ok = UserGroups.set_as_hybrid(ctx, group.user_group_id, default_tenant_id())

      # Verify by fetching
      {:ok, _hybrid} = UserGroups.get_by_id(ctx, group.user_group_id, default_tenant_id())
    end
  end
end
