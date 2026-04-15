defmodule KeenAuthPermissions.AuditTest do
  use KeenAuthPermissions.DataCase, async: false

  alias KeenAuthPermissions.Audit

  describe "get_user_audit_trail/6" do
    test "returns a list of audit entries" do
      ctx = system_context()

      assert {:ok, results} =
               Audit.get_user_audit_trail(
                 ctx,
                 %{target_user_id: ctx.user.user_id},
                 1,
                 20,
                 default_tenant_id()
               )

      assert is_list(results)
    end
  end

  describe "get_security_events/6" do
    test "returns a list of security events" do
      ctx = system_context()

      assert {:ok, results} =
               Audit.get_security_events(ctx, nil, 1, 20, default_tenant_id())

      assert is_list(results)
    end
  end

  describe "search_user_events/6" do
    test "lists user events" do
      ctx = system_context()

      assert {:ok, results} =
               Audit.search_user_events(ctx, nil, 1, 20, default_tenant_id())

      assert is_list(results)
    end
  end

  describe "search_journal/13" do
    test "returns journal entries" do
      ctx = system_context()

      assert {:ok, results} =
               Audit.search_journal(
                 ctx,
                 nil,
                 nil,
                 nil,
                 nil,
                 nil,
                 nil,
                 nil,
                 nil,
                 nil,
                 1,
                 20,
                 default_tenant_id()
               )

      assert is_list(results)
    end
  end

  describe "purge/2" do
    test "purges data older than a huge retention window (no-op in practice)" do
      ctx = system_context()

      assert {:ok, result} = Audit.purge(ctx, 36_500)
      assert is_map(result)
    end
  end
end
