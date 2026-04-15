defmodule KeenAuthPermissions.InvitationsTest do
  use KeenAuthPermissions.DataCase, async: false

  alias KeenAuthPermissions.Invitations

  describe "list/5" do
    test "lists invitations for the default tenant" do
      ctx = system_context()
      assert {:ok, results} = Invitations.list(ctx, default_tenant_id())
      assert is_list(results)
    end
  end

  describe "create/7 and full lifecycle" do
    test "creates, lists, revokes an invitation" do
      ctx = system_context()

      email = "invite_#{unique_string()}@example.com"
      actions = [%{"action_type_code" => "send_welcome_email", "payload" => %{}}]

      assert {:ok, created} =
               Invitations.create(ctx, default_tenant_id(), email, actions, "Welcome", nil, nil)

      invitation_id = created.invitation_id || Map.get(created, :id)
      assert is_integer(invitation_id)

      {:ok, listed} =
        Invitations.list(ctx, default_tenant_id(), nil, nil, email)

      assert Enum.any?(listed, fn i ->
               (Map.get(i, :invitation_id) || Map.get(i, :id)) == invitation_id
             end)

      assert {:ok, actions_list} = Invitations.get_actions(ctx, invitation_id, default_tenant_id())
      assert is_list(actions_list)

      assert :ok = Invitations.revoke(ctx, invitation_id)
    end

    test "reject/3 on a fresh invitation returns the action list" do
      ctx = system_context()
      email = "reject_#{unique_string()}@example.com"
      actions = [%{"action_type_code" => "send_welcome_email", "payload" => %{}}]

      {:ok, created} =
        Invitations.create(ctx, default_tenant_id(), email, actions, nil, nil, nil)

      invitation_id = created.invitation_id || Map.get(created, :id)

      assert {:ok, _} = Invitations.reject(ctx, invitation_id, default_tenant_id())
    end
  end

  describe "templates" do
    test "creates, updates, and deletes a template" do
      ctx = system_context()
      code = "tpl_#{unique_string()}"

      assert {:ok, template_id} =
               Invitations.create_template(
                 ctx,
                 default_tenant_id(),
                 code,
                 "Test Template",
                 "A test",
                 "Default msg",
                 [%{"action_type_code" => "send_welcome_email", "payload" => %{}}]
               )

      assert is_integer(template_id)

      assert :ok =
               Invitations.update_template(
                 ctx,
                 template_id,
                 "Renamed",
                 "Updated desc",
                 "Updated msg",
                 true,
                 default_tenant_id()
               )

      assert :ok = Invitations.delete_template(ctx, template_id)
    end
  end
end
