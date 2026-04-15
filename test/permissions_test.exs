defmodule KeenAuthPermissions.PermissionsTest do
  use KeenAuthPermissions.DataCase, async: false

  alias KeenAuthPermissions.Permissions

  @moduletag :clean_db

  describe "list/2" do
    test "lists all permissions" do
      ctx = system_context()

      assert {:ok, permissions} = Permissions.list(ctx, default_tenant_id())
      assert is_list(permissions)
    end

    test "permissions include short_code field" do
      ctx = system_context()

      {:ok, permissions} = Permissions.list(ctx, default_tenant_id())

      if length(permissions) > 0 do
        permission = List.first(permissions)
        assert Map.has_key?(permission, :short_code)
      end
    end
  end

  describe "get_permissions_map/0" do
    test "returns permission code mapping" do
      assert {:ok, permissions_map} = Permissions.get_permissions_map()
      assert is_list(permissions_map)

      if length(permissions_map) > 0 do
        entry = List.first(permissions_map)
        assert Map.has_key?(entry, :permission_id)
        assert Map.has_key?(entry, :full_code)
        assert Map.has_key?(entry, :short_code)
        assert Map.has_key?(entry, :title)
      end
    end
  end

  describe "search/5" do
    test "searches permissions with filters" do
      ctx = system_context()

      assert {:ok, results} =
               Permissions.search(ctx, nil, 1, 100, default_tenant_id())

      assert is_list(results)
    end

    test "searches by assignable flag" do
      ctx = system_context()

      assert {:ok, results} =
               Permissions.search(ctx, %{is_assignable: true}, 1, 100, default_tenant_id())

      assert is_list(results)
    end
  end

  describe "has_permission?/4" do
    test "returns boolean for permission check" do
      ctx = system_context()

      assert {:ok, result} =
               Permissions.has_permission?(
                 ctx.user.user_id,
                 "test_permission",
                 default_tenant_id()
               )

      assert is_boolean(result)
    end
  end

  describe "has_permissions?/4" do
    test "returns boolean for multiple permissions check" do
      ctx = system_context()

      assert {:ok, result} =
               Permissions.has_permissions?(
                 ctx.user.user_id,
                 ["perm1", "perm2"],
                 default_tenant_id()
               )

      assert is_boolean(result)
    end
  end

  describe "assign/6 and unassign/3" do
    test "assigns and unassigns a permission to a group" do
      ctx = system_context()

      # Create a test group
      {:ok, group} = create_test_group(ctx)

      # Get an assignable permission
      {:ok, permissions} = Permissions.list(ctx, default_tenant_id())

      # Find an assignable permission
      assignable = Enum.find(permissions, fn p -> p.is_assignable end)

      if assignable do
        # Assign the permission
        assert {:ok, assignment} =
                 Permissions.assign(
                   ctx,
                   group.user_group_id,
                   nil,
                   nil,
                   assignable.full_code,
                   default_tenant_id()
                 )

        # Unassign the permission
        assert {:ok, _} =
                 Permissions.unassign(ctx, assignment.assignment_id, default_tenant_id())
      end
    end
  end

  describe "create/4" do
    test "creates a new permission" do
      ctx = system_context()

      code = "test_permission_#{unique_string()}"

      {:ok, permissions} = Permissions.list(ctx, default_tenant_id())
      parent = List.first(permissions)

      if parent do
        assert {:ok, created} =
                 Permissions.create(ctx, code, parent.full_code, true)

        assert created.code == code
      end
    end
  end

  describe "set_assignable/4" do
    test "sets a permission as assignable" do
      ctx = system_context()

      {:ok, permissions} = Permissions.list(ctx, default_tenant_id())
      permission = List.first(permissions)

      if permission do
        assert {:ok, _} =
                 Permissions.set_assignable(
                   ctx,
                   permission.permission_id,
                   permission.full_code,
                   true
                 )
      end
    end
  end

  describe "error throwing operations" do
    test "throw_no_access/2 returns error" do
      ctx = system_context()

      assert {:error, _} = Permissions.throw_no_access(ctx.user.username, default_tenant_id())
    end
  end
end
