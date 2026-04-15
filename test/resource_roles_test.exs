defmodule KeenAuthPermissions.ResourceRolesTest do
  use KeenAuthPermissions.DataCase, async: false

  alias KeenAuthPermissions.ResourceAccess
  alias KeenAuthPermissions.ResourceRoles

  defp create_resource_type(ctx, code) do
    {:ok, _} =
      ResourceAccess.create_resource_type(
        ctx,
        code,
        "Role Test RT",
        nil,
        default_tenant_id(),
        "test",
        %{"id" => "bigint"},
        ["read", "write", "delete"],
        "en"
      )
  end

  describe "list/4" do
    test "lists resource roles without error" do
      assert {:ok, results} = ResourceRoles.list()
      assert is_list(results)
    end
  end

  describe "create / list / update / delete" do
    test "full role CRUD round-trip" do
      ctx = system_context()
      rt_code = "rr_rt_#{unique_string()}"
      role_code = "rr_#{unique_string()}"

      create_resource_type(ctx, rt_code)

      assert {:ok, role} =
               ResourceRoles.create(
                 ctx,
                 role_code,
                 rt_code,
                 "Viewer",
                 "Read-only access",
                 ["read"],
                 "test",
                 default_tenant_id(),
                 "en"
               )

      assert role.code == role_code

      {:ok, listed} = ResourceRoles.list("test", rt_code, true, nil)
      assert is_list(listed)

      assert {:ok, updated} =
               ResourceRoles.update(
                 ctx,
                 role_code,
                 "Renamed Viewer",
                 nil,
                 true,
                 "test",
                 default_tenant_id(),
                 "en"
               )

      assert updated.code == role_code

      assert {:ok, _} = ResourceRoles.delete(ctx, role_code, default_tenant_id())
    end
  end

  describe "assign / revoke" do
    test "assigns and revokes a role on a resource" do
      ctx = system_context()
      rt_code = "rr_assign_rt_#{unique_string()}"
      role_code = "rr_assign_#{unique_string()}"

      create_resource_type(ctx, rt_code)

      {:ok, _} =
        ResourceRoles.create(
          ctx,
          role_code,
          rt_code,
          "Assignee",
          nil,
          ["read", "write"],
          "test",
          default_tenant_id(),
          "en"
        )

      resource_id = %{"id" => 7}

      assert {:ok, _} =
               ResourceRoles.assign(
                 ctx,
                 rt_code,
                 resource_id,
                 ctx.user.user_id,
                 nil,
                 [role_code],
                 default_tenant_id()
               )

      assert {:ok, _count} =
               ResourceRoles.revoke(
                 ctx,
                 rt_code,
                 resource_id,
                 ctx.user.user_id,
                 nil,
                 [role_code],
                 default_tenant_id()
               )
    end
  end

  describe "get_flags/1" do
    test "returns flags attached to a role" do
      ctx = system_context()
      rt_code = "rr_flags_rt_#{unique_string()}"
      role_code = "rr_flags_#{unique_string()}"

      create_resource_type(ctx, rt_code)

      {:ok, _} =
        ResourceRoles.create(
          ctx,
          role_code,
          rt_code,
          "Editor",
          nil,
          ["read", "write"],
          "test",
          default_tenant_id(),
          "en"
        )

      assert {:ok, flags} = ResourceRoles.get_flags(role_code)
      assert is_list(flags)
    end
  end
end
