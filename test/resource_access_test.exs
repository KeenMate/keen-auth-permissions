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

  defp setup_grant_rt(ctx, code, access_flags \\ ["read", "write"]) do
    {:ok, _} =
      ResourceAccess.create_resource_type(
        ctx,
        code,
        "Test RT",
        nil,
        default_tenant_id(),
        "test",
        %{"id" => "bigint"},
        access_flags,
        "en"
      )
  end

  describe "resource_path lookup" do
    # Granting by resource_id does not auto-synthesize a resource_path; the DB stores
    # whichever identifier the caller supplied. So we grant by path directly and verify
    # the path-based wire format works end-to-end.
    test "grant + has_access? by resource_path (no resource_id)" do
      ctx = system_context()
      code = "rt_path_#{unique_string()}"
      setup_grant_rt(ctx, code)

      path = "#{code}.101"

      assert {:ok, _} =
               ResourceAccess.grant(
                 ctx,
                 code,
                 nil,
                 ctx.user.user_id,
                 nil,
                 ["read"],
                 default_tenant_id(),
                 path
               )

      assert {:ok, true} =
               ResourceAccess.has_access?(
                 ctx,
                 code,
                 nil,
                 "read",
                 default_tenant_id(),
                 false,
                 path
               )
    end

    test "revoke by resource_path removes a path-based grant" do
      ctx = system_context()
      code = "rt_path_rev_#{unique_string()}"
      setup_grant_rt(ctx, code)

      path = "#{code}.202"

      {:ok, _} =
        ResourceAccess.grant(
          ctx,
          code,
          nil,
          ctx.user.user_id,
          nil,
          ["read"],
          default_tenant_id(),
          path
        )

      assert {:ok, _count} =
               ResourceAccess.revoke(
                 ctx,
                 code,
                 nil,
                 ctx.user.user_id,
                 nil,
                 ["read"],
                 default_tenant_id(),
                 path
               )
    end
  end

  describe "filter_accessible/6" do
    test "returns the granted subset by resource_id (system user sees all)" do
      ctx = system_context()
      code = "rt_filter_id_#{unique_string()}"
      setup_grant_rt(ctx, code)

      ids = [%{"id" => 1}, %{"id" => 2}, %{"id" => 3}]

      assert {:ok, results} =
               ResourceAccess.filter_accessible(
                 ctx,
                 code,
                 ids,
                 "read",
                 default_tenant_id()
               )

      assert is_list(results)
    end

    test "returns the granted subset by resource_paths" do
      ctx = system_context()
      code = "rt_filter_path_#{unique_string()}"
      setup_grant_rt(ctx, code)

      {:ok, _} =
        ResourceAccess.grant(
          ctx,
          code,
          %{"id" => 11},
          ctx.user.user_id,
          nil,
          ["read"],
          default_tenant_id()
        )

      {:ok, [%{resource_path: path} | _]} =
        ResourceAccess.get_user_resources(
          ctx,
          ctx.user.user_id,
          code,
          "read",
          default_tenant_id()
        )

      assert {:ok, results} =
               ResourceAccess.filter_accessible(
                 ctx,
                 code,
                 nil,
                 "read",
                 default_tenant_id(),
                 [path]
               )

      assert is_list(results)
    end
  end

  describe "deny/7" do
    test "deny returns ok for a target user" do
      ctx = system_context()
      code = "rt_deny_#{unique_string()}"
      setup_grant_rt(ctx, code)

      resource_id = %{"id" => 33}

      assert {:ok, _} =
               ResourceAccess.deny(
                 ctx,
                 code,
                 resource_id,
                 ctx.user.user_id,
                 ["read"],
                 default_tenant_id()
               )
    end
  end

  describe "revoke_all/5" do
    test "wipes all grants on a resource" do
      ctx = system_context()
      code = "rt_rev_all_#{unique_string()}"
      setup_grant_rt(ctx, code)

      resource_id = %{"id" => 44}

      {:ok, _} =
        ResourceAccess.grant(
          ctx,
          code,
          resource_id,
          ctx.user.user_id,
          nil,
          ["read", "write"],
          default_tenant_id()
        )

      assert {:ok, _count} =
               ResourceAccess.revoke_all(
                 ctx,
                 code,
                 resource_id,
                 default_tenant_id()
               )
    end
  end

  describe "get_matrix/5" do
    test "returns access flags for a resource" do
      ctx = system_context()
      code = "rt_matrix_#{unique_string()}"
      setup_grant_rt(ctx, code)

      resource_id = %{"id" => 55}

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

      assert {:ok, matrix} =
               ResourceAccess.get_matrix(ctx, code, resource_id, default_tenant_id())

      assert is_list(matrix)
    end
  end

  describe "get_grants/5" do
    test "returns the grants on a resource" do
      ctx = system_context()
      code = "rt_grants_#{unique_string()}"
      setup_grant_rt(ctx, code)

      resource_id = %{"id" => 66}

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

      assert {:ok, grants} =
               ResourceAccess.get_grants(ctx, code, resource_id, default_tenant_id())

      assert is_list(grants)
      assert length(grants) >= 1
    end
  end

  describe "get_user_resources/5" do
    test "returns rows with resource_id, resource_path, access_flags, source" do
      ctx = system_context()
      code = "rt_user_res_#{unique_string()}"
      setup_grant_rt(ctx, code)

      {:ok, _} =
        ResourceAccess.grant(
          ctx,
          code,
          %{"id" => 77},
          ctx.user.user_id,
          nil,
          ["read"],
          default_tenant_id()
        )

      assert {:ok, [row | _]} =
               ResourceAccess.get_user_resources(
                 ctx,
                 ctx.user.user_id,
                 code,
                 nil,
                 default_tenant_id()
               )

      assert is_map(row.resource_id) or is_list(row.resource_id)
      assert is_binary(row.resource_path) or is_nil(row.resource_path)
      assert is_list(row.access_flags)
      assert is_binary(row.source) or is_nil(row.source)
    end
  end

  describe "update_resource_type/8" do
    test "updates an existing resource type" do
      ctx = system_context()
      code = "rt_upd_#{unique_string()}"

      {:ok, _} =
        ResourceAccess.create_resource_type(
          ctx,
          code,
          "Original Title",
          "Original desc",
          default_tenant_id(),
          "test",
          %{"id" => "bigint"},
          ["read"],
          "en"
        )

      assert {:ok, updated} =
               ResourceAccess.update_resource_type(
                 ctx,
                 code,
                 "Renamed Title",
                 "New desc",
                 true,
                 "test",
                 default_tenant_id(),
                 "en"
               )

      assert updated.code == code
    end
  end

  describe "negative paths" do
    test "has_access? errors with :resource_identifier_required when both nil (non-system user)" do
      ctx = system_context()
      code = "rt_neg_has_#{unique_string()}"
      setup_grant_rt(ctx, code)

      ctx_other =
        %KeenAuthPermissions.RequestContext{
          ctx
          | user_id: 800,
            user: %KeenAuthPermissions.User{
              ctx.user
              | user_id: 800,
                username: "svc_data_processor"
            }
        }

      assert {:error, %KeenAuthPermissions.Error.ErrorStruct{
               reason: :resource_identifier_required,
               metadata: %{event_id: 35010}
             }} =
               ResourceAccess.has_access?(
                 ctx_other,
                 code,
                 nil,
                 "read",
                 default_tenant_id(),
                 false,
                 nil
               )
    end

    # The DB validates resource identifier presence BEFORE the user_id=1 shortcut, so
    # malformed calls fail loudly regardless of caller identity. This protects against
    # bugs that pass in tests (as the system user) but fail in production (as real users).
    test "has_access? errors even for system user when both identifiers nil" do
      ctx = system_context()
      code = "rt_neg_has_sys_#{unique_string()}"
      setup_grant_rt(ctx, code)

      assert {:error, %KeenAuthPermissions.Error.ErrorStruct{
               reason: :resource_identifier_required
             }} =
               ResourceAccess.has_access?(
                 ctx,
                 code,
                 nil,
                 "read",
                 default_tenant_id(),
                 false,
                 nil
               )
    end

    test "get_flags errors when both identifiers nil" do
      ctx = system_context()
      code = "rt_neg_flags_#{unique_string()}"
      setup_grant_rt(ctx, code)

      assert {:error, %KeenAuthPermissions.Error.ErrorStruct{
               reason: :resource_identifier_required
             }} =
               ResourceAccess.get_flags(ctx, code, nil, default_tenant_id(), nil)
    end

    test "get_matrix errors when both identifiers nil" do
      ctx = system_context()
      code = "rt_neg_matrix_#{unique_string()}"
      setup_grant_rt(ctx, code)

      assert {:error, %KeenAuthPermissions.Error.ErrorStruct{
               reason: :resource_identifier_required
             }} =
               ResourceAccess.get_matrix(ctx, code, nil, default_tenant_id(), nil)
    end

    test "get_grants errors when both identifiers nil" do
      ctx = system_context()
      code = "rt_neg_grants_#{unique_string()}"
      setup_grant_rt(ctx, code)

      assert {:error, %KeenAuthPermissions.Error.ErrorStruct{
               reason: :resource_identifier_required
             }} =
               ResourceAccess.get_grants(ctx, code, nil, default_tenant_id(), nil)
    end

    test "grant errors when both resource_id and resource_path are nil" do
      ctx = system_context()
      code = "rt_neg_grant_#{unique_string()}"
      setup_grant_rt(ctx, code)

      assert {:error, _} =
               ResourceAccess.grant(
                 ctx,
                 code,
                 nil,
                 ctx.user.user_id,
                 nil,
                 ["read"],
                 default_tenant_id(),
                 nil
               )
    end
  end
end
