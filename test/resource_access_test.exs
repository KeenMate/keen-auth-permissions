defmodule KeenAuthPermissions.ResourceAccessTest do
  use KeenAuthPermissions.DataCase, async: false

  alias KeenAuthPermissions.ResourceAccess

  describe "list_resource_types/3" do
    test "lists resource types without error" do
      assert {:ok, results} = ResourceAccess.list_resource_types()
      assert is_list(results)
    end
  end

  describe "access-flag helpers" do
    test "list_access_flags/2 returns a list" do
      assert {:ok, results} = ResourceAccess.list_access_flags()
      assert is_list(results)
    end

    test "ensure_access_flags/5 upserts a batch idempotently" do
      ctx = system_context()
      source = "test_flags_#{unique_string()}"

      flags = [
        %{
          "code" => "read_#{unique_string()}",
          "title" => "Read",
          "description" => "Read access"
        },
        %{
          "code" => "write_#{unique_string()}",
          "title" => "Write",
          "description" => "Write access"
        }
      ]

      assert {:ok, _first} =
               ResourceAccess.ensure_access_flags(ctx, flags, source, default_tenant_id(), "en")

      assert {:ok, _second} =
               ResourceAccess.ensure_access_flags(ctx, flags, source, default_tenant_id(), "en")
    end

    test "ensure_resource_type_flags/4 syncs the flag set attached to a resource type" do
      ctx = system_context()
      rt_code = "rt_flags_#{unique_string()}"

      {:ok, _} =
        ResourceAccess.create_resource_type(
          ctx,
          rt_code,
          "Flag Sync RT",
          nil,
          default_tenant_id(),
          "test",
          %{"id" => "bigint"},
          ["read", "write"],
          "en"
        )

      assert {:ok, _} =
               ResourceAccess.ensure_resource_type_flags(
                 ctx,
                 rt_code,
                 ["read", "delete"],
                 default_tenant_id()
               )
    end
  end

  describe "create_resource_type/9 and ensure_resource_types/5" do
    test "creates a new resource type" do
      ctx = system_context()
      code = "test_rt_#{unique_string()}"

      assert {:ok, created} =
               ResourceAccess.create_resource_type(
                 ctx,
                 code,
                 "Test Resource Type",
                 "description",
                 default_tenant_id(),
                 "test",
                 %{"id" => "bigint"},
                 ["read", "write"],
                 "en"
               )

      assert created.code == code
    end

    test "ensure_resource_types/5 accepts a JSONB list" do
      ctx = system_context()

      payload = [
        %{
          "code" => "test_ensure_#{unique_string()}",
          "title" => "Ensured RT",
          "description" => nil,
          "key_schema" => %{"id" => "bigint"},
          "access_flags" => ["read", "write"]
        }
      ]

      assert {:ok, _} =
               ResourceAccess.ensure_resource_types(
                 ctx,
                 payload,
                 "test",
                 default_tenant_id(),
                 "en"
               )
    end
  end

  describe "grant / has_access? / get_flags / revoke" do
    test "grant → has_access? → revoke round-trip for a user" do
      ctx = system_context()
      code = "rt_grant_#{unique_string()}"

      {:ok, _rt} =
        ResourceAccess.create_resource_type(
          ctx,
          code,
          "Grant RT",
          nil,
          default_tenant_id(),
          "test",
          %{"id" => "bigint"},
          ["read", "write"],
          "en"
        )

      resource_id = %{"id" => 42}

      {:ok, _} =
        ResourceAccess.grant(
          ctx,
          code,
          resource_id,
          ctx.user.user_id,
          nil,
          ["read"],
          default_tenant_id()
        )

      assert {:ok, true} =
               ResourceAccess.has_access?(ctx, code, resource_id, "read", default_tenant_id())

      assert {:ok, flags} =
               ResourceAccess.get_flags(ctx, code, resource_id, default_tenant_id())

      assert is_list(flags)

      assert {:ok, _count} =
               ResourceAccess.revoke(
                 ctx,
                 code,
                 resource_id,
                 ctx.user.user_id,
                 nil,
                 ["read"],
                 default_tenant_id()
               )
    end

    test "has_access? is false when checked against a non-system, non-owner user" do
      ctx = system_context()
      code = "rt_none_#{unique_string()}"

      {:ok, _} =
        ResourceAccess.create_resource_type(
          ctx,
          code,
          "Empty RT",
          nil,
          default_tenant_id(),
          "test",
          %{"id" => "bigint"},
          ["read"],
          "en"
        )

      # The system user (id 1) is always allowed by the resource-access algorithm,
      # so we ask the question on behalf of a non-system user via a synthetic context.
      ctx_for_other =
        %KeenAuthPermissions.RequestContext{
          ctx
          | user_id: 800,
            user: %KeenAuthPermissions.User{
              ctx.user
              | user_id: 800,
                username: "svc_data_processor"
            }
        }

      assert {:ok, false} =
               ResourceAccess.has_access?(
                 ctx_for_other,
                 code,
                 %{"id" => 99_999},
                 "read",
                 default_tenant_id()
               )
    end
  end
end
