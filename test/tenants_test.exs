defmodule KeenAuthPermissions.TenantsTest do
  use KeenAuthPermissions.DataCase, async: false

  alias KeenAuthPermissions.Tenants

  @moduletag :clean_db

  describe "list_all/0" do
    test "lists all tenants" do
      assert {:ok, tenants} = Tenants.list_all()
      assert is_list(tenants)
    end
  end

  describe "list/1" do
    test "lists tenants for a user" do
      ctx = system_context()

      assert {:ok, tenants} = Tenants.list(ctx.user.user_id)
      assert is_list(tenants)
    end
  end

  describe "get_by_id/1" do
    test "returns tenant when found" do
      # Default tenant should exist
      assert {:ok, tenant} = Tenants.get_by_id(default_tenant_id())
      assert tenant.tenant_id == default_tenant_id()
    end

    test "returns error when tenant not found" do
      assert {:error, _} = Tenants.get_by_id(999_999)
    end
  end

  describe "search/4" do
    test "searches tenants" do
      ctx = system_context()

      assert {:ok, results} = Tenants.search(ctx, nil, 1, 100)
      assert is_list(results)
    end

    test "searches tenants by text" do
      ctx = system_context()

      assert {:ok, results} = Tenants.search(ctx, "test", 1, 100)
      assert is_list(results)
    end
  end

  describe "create/6, update/7, and delete/2" do
    test "creates a new tenant" do
      ctx = system_context()
      title = "Test Tenant #{unique_string()}"
      code = "test_#{unique_string()}"

      assert {:ok, created} =
               Tenants.create(ctx, title, code, true, true, ctx.user.user_id)

      assert created.title == title
      assert created.code == code
    end

    test "updates an existing tenant" do
      ctx = system_context()

      # Create a tenant first
      {:ok, created} = create_test_tenant(ctx)

      new_title = "Updated Tenant #{unique_string()}"

      assert {:ok, updated} =
               Tenants.update(
                 ctx,
                 created.tenant_id,
                 new_title,
                 created.code,
                 true,
                 true,
                 ctx.user.user_id
               )

      assert updated.title == new_title
    end

    test "soft-deletes a tenant" do
      ctx = system_context()

      # Create a tenant first
      {:ok, created} = create_test_tenant(ctx)

      # Delete it (soft delete)
      assert {:ok, _deleted} = Tenants.delete(ctx, created.uuid)

      # Soft delete: the tenant is still fetchable, not hard-removed
      assert {:ok, _tenant} = Tenants.get_by_id(created.tenant_id)

      # ...and it is marked as deleted in the listing
      assert %{deleted_at: deleted_at} = find_in_list(ctx, created.tenant_id)
      refute is_nil(deleted_at)
    end
  end

  describe "restore/2" do
    test "restores a soft-deleted tenant" do
      ctx = system_context()

      {:ok, created} = create_test_tenant(ctx)
      assert {:ok, _} = Tenants.delete(ctx, created.uuid)
      assert %{deleted_at: deleted_at} = find_in_list(ctx, created.tenant_id)
      refute is_nil(deleted_at)

      # Restore clears the soft-delete marker
      assert {:ok, _restored} = Tenants.restore(ctx, created.uuid)
      assert %{deleted_at: nil} = find_in_list(ctx, created.tenant_id)
      assert {:ok, _tenant} = Tenants.get_by_id(created.tenant_id)
    end
  end

  describe "purge/2" do
    test "permanently purges a tenant" do
      ctx = system_context()

      {:ok, created} = create_test_tenant(ctx)
      assert {:ok, _} = Tenants.delete(ctx, created.uuid)

      # Purge hard-deletes the tenant
      assert {:ok, _purged} = Tenants.purge(ctx, created.uuid)
      assert {:error, _} = Tenants.get_by_id(created.tenant_id)
    end
  end

  # Finds a tenant by id in the user's tenant listing, or fails the assertion.
  defp find_in_list(ctx, tenant_id) do
    {:ok, tenants} = Tenants.list(ctx.user.user_id)
    Enum.find(tenants, fn t -> t.tenant_id == tenant_id end)
  end

  describe "list_users/2" do
    test "lists users in a tenant" do
      ctx = system_context()

      assert {:ok, users} = Tenants.list_users(ctx, default_tenant_id())
      assert is_list(users)
    end
  end

  describe "list_members/2" do
    test "lists members in a tenant" do
      ctx = system_context()

      assert {:ok, members} = Tenants.list_members(ctx, default_tenant_id())
      assert is_list(members)
    end
  end

  describe "list_groups/2" do
    test "lists groups in a tenant" do
      ctx = system_context()

      assert {:ok, groups} = Tenants.list_groups(ctx, default_tenant_id())
      assert is_list(groups)
    end
  end
end
