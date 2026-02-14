defmodule KeenAuthPermissions.Managers.UsersManager do
  @moduledoc """
  DEPRECATED: Use `KeenAuthPermissions.Users` instead.

  This module is kept for backward compatibility and delegates to the new facade.
  """

  @deprecated "Use KeenAuthPermissions.Users instead"

  import KeenAuthPermissions.Managers.ManagerHelpers

  alias KeenAuthPermissions.Users
  alias KeenAuthPermissions.User
  alias KeenAuthPermissions.RequestContext

  defp ctx(%User{} = user), do: RequestContext.new(user)

  @doc deprecated: "Use KeenAuthPermissions.Users.list/2 instead"
  def get_tenant_users(%User{} = user, tenant_id) do
    tenant_id = num(tenant_id)

    with {:ok, users} <- Users.list(ctx(user), tenant_id) do
      with_decoded_groups =
        users
        |> Enum.map(&parse_user_group_json!/1)

      {:ok, with_decoded_groups}
    end
  end

  defp parse_user_group_json!(%{user_groups: groups} = user) when is_list(groups) do
    decoded_groups =
      Enum.map(groups, fn
        group when is_binary(group) -> Jason.decode!(group)
        group -> group
      end)

    %{user | user_groups: decoded_groups}
  end

  defp parse_user_group_json!(user), do: user

  @doc deprecated: "Use KeenAuthPermissions.Users.enable/2 instead"
  def enable_user(%User{} = user, target_user_id) do
    Users.enable(ctx(user), num(target_user_id))
  end

  @doc deprecated: "Use KeenAuthPermissions.Users.disable/2 instead"
  def disable_user(%User{} = user, target_user_id) do
    Users.disable(ctx(user), num(target_user_id))
  end

  @doc deprecated: "Use KeenAuthPermissions.Users.lock/2 instead"
  def lock_user(%User{} = user, target_user_id) do
    Users.lock(ctx(user), num(target_user_id))
  end

  @doc deprecated: "Use KeenAuthPermissions.Users.unlock/2 instead"
  def unlock_user(%User{} = user, target_user_id) do
    Users.unlock(ctx(user), num(target_user_id))
  end
end
