defmodule KeenAuthPermissions.MfaTest do
  use KeenAuthPermissions.DataCase, async: false

  alias KeenAuthPermissions.Mfa

  describe "get_policies/4" do
    test "lists policies without error" do
      ctx = system_context()
      assert {:ok, results} = Mfa.get_policies(ctx, default_tenant_id(), nil, nil)
      assert is_list(results)
    end
  end

  describe "create_policy/5 and delete_policy/2" do
    test "creates a user-scoped policy and deletes it" do
      ctx = system_context()

      # Need a real user (FK constraint mfa_policy_user_id_fkey).
      {:ok, target_user} = create_test_user(ctx)
      target_user_id = target_user.user_id

      # Defensive cleanup in case a previous run left a stale policy for this id.
      {:ok, existing} =
        Mfa.get_policies(ctx, default_tenant_id(), nil, target_user_id)

      Enum.each(existing, fn p ->
        if id = Map.get(p, :mfa_policy_id) || Map.get(p, :id) do
          Mfa.delete_policy(ctx, id)
        end
      end)

      assert {:ok, policy} =
               Mfa.create_policy(ctx, default_tenant_id(), nil, target_user_id, true)

      # Model exposes the returning scalar under :create_mfa_policy.
      policy_id = Map.get(policy, :create_mfa_policy)
      assert is_integer(policy_id)

      assert :ok = Mfa.delete_policy(ctx, policy_id)
    end
  end

  describe "get_status/2" do
    test "returns the MFA status rows for the system user" do
      ctx = system_context()
      assert {:ok, results} = Mfa.get_status(ctx, ctx.user.user_id)
      assert is_list(results)
    end
  end

  describe "is_required?/3" do
    test "returns a boolean for the system user" do
      ctx = system_context()
      assert {:ok, required} = Mfa.is_required?(ctx, ctx.user.user_id, default_tenant_id())
      assert is_boolean(required)
    end
  end
end
