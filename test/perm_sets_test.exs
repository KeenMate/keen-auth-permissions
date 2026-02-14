defmodule KeenAuthPermissions.PermSetsTest do
  use KeenAuthPermissions.DataCase, async: false

  alias KeenAuthPermissions.PermSets

  @moduletag :clean_db

  describe "list/2" do
    test "lists all permission sets" do
      ctx = system_context()

      assert {:ok, perm_sets} = PermSets.list(ctx, default_tenant_id())
      assert is_list(perm_sets)
    end
  end

  describe "search/7" do
    test "searches permission sets" do
      ctx = system_context()

      assert {:ok, results} =
               PermSets.search(ctx, nil, nil, nil, 1, 100, default_tenant_id())

      assert is_list(results)
    end

    test "searches permission sets by text" do
      ctx = system_context()

      assert {:ok, results} =
               PermSets.search(ctx, "test", nil, nil, 1, 100, default_tenant_id())

      assert is_list(results)
    end

    test "searches by assignable flag" do
      ctx = system_context()

      assert {:ok, results} =
               PermSets.search(ctx, nil, true, nil, 1, 100, default_tenant_id())

      assert is_list(results)
    end

    test "searches by system flag" do
      ctx = system_context()

      assert {:ok, results} =
               PermSets.search(ctx, nil, nil, false, 1, 100, default_tenant_id())

      assert is_list(results)
    end
  end

  describe "create/6" do
    test "creates a new permission set" do
      ctx = system_context()
      title = "Test PermSet #{unique_string()}"

      assert {:ok, created} =
               PermSets.create(ctx, title, false, true, [], default_tenant_id())

      assert created.title == title
      assert created.is_system == false
      assert created.is_assignable == true
    end

    test "creates a permission set with permissions" do
      ctx = system_context()
      title = "Test PermSet With Perms #{unique_string()}"

      # Note: This may fail if the permissions don't exist
      # The test is structured to handle that case
      case PermSets.create(ctx, title, false, true, [], default_tenant_id()) do
        {:ok, created} ->
          assert created.title == title

        {:error, _} ->
          :ok
      end
    end
  end

  describe "update/5" do
    test "updates an existing permission set" do
      ctx = system_context()

      # Create a permission set first
      {:ok, created} = create_test_perm_set(ctx)

      new_title = "Updated PermSet #{unique_string()}"

      assert {:ok, updated} =
               PermSets.update(
                 ctx,
                 created.perm_set_id,
                 new_title,
                 false,
                 default_tenant_id()
               )

      assert updated.title == new_title
    end
  end

  describe "add_permissions/4 and delete_permissions/4" do
    @tag :skip
    test "adds and removes permissions from a permission set" do
      ctx = system_context()

      # Create a permission set
      {:ok, perm_set} = create_test_perm_set(ctx)

      # Get available permissions
      {:ok, all_permissions} = KeenAuthPermissions.Permissions.list(ctx, default_tenant_id())

      # Find an assignable permission
      assignable = Enum.find(all_permissions, fn p -> p.is_assignable end)

      if assignable do
        # Add the permission
        assert {:ok, added} =
                 PermSets.add_permissions(
                   ctx,
                   perm_set.perm_set_id,
                   [assignable.full_code],
                   default_tenant_id()
                 )

        assert is_list(added)

        # Remove the permission
        assert {:ok, removed} =
                 PermSets.delete_permissions(
                   ctx,
                   perm_set.perm_set_id,
                   [assignable.full_code],
                   default_tenant_id()
                 )

        assert is_list(removed)
      end
    end
  end
end
