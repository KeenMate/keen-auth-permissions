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

    test "deletes a tenant" do
      ctx = system_context()

      # Create a tenant first
      {:ok, created} = create_test_tenant(ctx)

      # Delete it
      assert {:ok, _deleted} = Tenants.delete(ctx, created.uuid)

      # Verify it's gone
      assert {:error, _} = Tenants.get_by_id(created.tenant_id)
    end
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
