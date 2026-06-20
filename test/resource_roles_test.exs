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

  defp setup_rt_and_role(ctx, rt_code, role_code, flags \\ ["read", "write"]) do
    create_resource_type(ctx, rt_code)

    {:ok, _} =
      ResourceRoles.create(
        ctx,
        role_code,
        rt_code,
        "Test Role",
        nil,
        flags,
        "test",
        default_tenant_id(),
        "en"
      )
  end

  describe "resource_path lookup" do
    test "assign + revoke by resource_path (no resource_id)" do
      ctx = system_context()
      rt_code = "rr_path_rt_#{unique_string()}"
      role_code = "rr_path_#{unique_string()}"
      setup_rt_and_role(ctx, rt_code, role_code)

      path = "#{rt_code}.301"

      assert {:ok, _} =
               ResourceRoles.assign(
                 ctx,
                 rt_code,
                 nil,
                 ctx.user.user_id,
                 nil,
                 [role_code],
                 default_tenant_id(),
                 path
               )

      assert {:ok, _count} =
               ResourceRoles.revoke(
                 ctx,
                 rt_code,
                 nil,
                 ctx.user.user_id,
                 nil,
                 [role_code],
                 default_tenant_id(),
                 path
               )
    end
  end

  describe "revoke_all/4" do
    test "removes every role assignment on a resource" do
      ctx = system_context()
      rt_code = "rr_rev_all_rt_#{unique_string()}"
      role_code = "rr_rev_all_#{unique_string()}"
      setup_rt_and_role(ctx, rt_code, role_code)

      resource_id = %{"id" => 401}

      {:ok, _} =
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
               ResourceRoles.revoke_all(ctx, rt_code, resource_id, default_tenant_id())
    end
  end

  describe "get_assignments/5" do
    test "lists role assignments on a resource" do
      ctx = system_context()
      rt_code = "rr_assigns_rt_#{unique_string()}"
      role_code = "rr_assigns_#{unique_string()}"
      setup_rt_and_role(ctx, rt_code, role_code)

      resource_id = %{"id" => 501}

      {:ok, _} =
        ResourceRoles.assign(
          ctx,
          rt_code,
          resource_id,
          ctx.user.user_id,
          nil,
          [role_code],
          default_tenant_id()
        )

      assert {:ok, assignments} =
               ResourceRoles.get_assignments(
                 ctx,
                 rt_code,
                 resource_id,
                 default_tenant_id(),
                 "en"
               )

      assert is_list(assignments)
      assert length(assignments) >= 1
    end
  end

  describe "ensure/6" do
    test "upserts a batch of roles from JSONB" do
      ctx = system_context()
      rt_code = "rr_ensure_rt_#{unique_string()}"
      role_code_a = "rr_ens_a_#{unique_string()}"
      role_code_b = "rr_ens_b_#{unique_string()}"

      create_resource_type(ctx, rt_code)

      payload = [
        %{
          "code" => role_code_a,
          "resource_type" => rt_code,
          "title" => "Role A",
          "description" => nil,
          "access_flags" => ["read"]
        },
        %{
          "code" => role_code_b,
          "resource_type" => rt_code,
          "title" => "Role B",
          "description" => nil,
          "access_flags" => ["read", "write"]
        }
      ]

      assert {:ok, _first} =
               ResourceRoles.ensure(ctx, payload, "test", false, default_tenant_id(), "en")

      assert {:ok, _second} =
               ResourceRoles.ensure(ctx, payload, "test", false, default_tenant_id(), "en")
    end
  end

  describe "ensure_flags/4" do
    test "syncs the access-flag set attached to a role" do
      ctx = system_context()
      rt_code = "rr_ef_rt_#{unique_string()}"
      role_code = "rr_ef_#{unique_string()}"
      setup_rt_and_role(ctx, rt_code, role_code, ["read", "write", "delete"])

      assert {:ok, _} =
               ResourceRoles.ensure_flags(ctx, role_code, ["read", "delete"], default_tenant_id())
    end
  end

  describe "negative paths" do
    test "assign errors when both resource_id and resource_path are nil" do
      ctx = system_context()
      rt_code = "rr_neg_rt_#{unique_string()}"
      role_code = "rr_neg_#{unique_string()}"
      setup_rt_and_role(ctx, rt_code, role_code)

      assert {:error, _} =
               ResourceRoles.assign(
                 ctx,
                 rt_code,
                 nil,
                 ctx.user.user_id,
                 nil,
                 [role_code],
                 default_tenant_id(),
                 nil
               )
    end
  end
end
