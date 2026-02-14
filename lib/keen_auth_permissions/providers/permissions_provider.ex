defmodule KeenAuthPermissions.Providers.PermissionsProvider do
  @moduledoc """
  DEPRECATED: Use `KeenAuthPermissions.Permissions` and `KeenAuthPermissions.PermSets` instead.

  This module is kept for backward compatibility and delegates to the new facades.
  """

  @deprecated "Use KeenAuthPermissions.Permissions or KeenAuthPermissions.PermSets instead"

  alias KeenAuthPermissions.Permissions
  alias KeenAuthPermissions.PermSets
  alias KeenAuthPermissions.User
  alias KeenAuthPermissions.RequestContext

  defp ctx(%User{} = user), do: RequestContext.new(user)

  @doc deprecated: "Use KeenAuthPermissions.Permissions.assign/6 instead"
  def assign_permission(
        %User{} = user,
        user_group_id,
        target_user_id,
        perm_set_code,
        perm_code,
        tenant_id \\ 1
      ) do
    # Returns list for backward compatibility
    case Permissions.assign(
           ctx(user),
           user_group_id,
           target_user_id,
           perm_set_code,
           perm_code,
           tenant_id
         ) do
      {:ok, result} -> {:ok, [result]}
      error -> error
    end
  end

  @doc deprecated: "Use KeenAuthPermissions.Permissions.unassign/3 instead"
  def unassign_permission(%User{} = user, assignment_id, tenant_id \\ 1) do
    # Returns list for backward compatibility
    case Permissions.unassign(ctx(user), assignment_id, tenant_id) do
      {:ok, result} -> {:ok, [result]}
      error -> error
    end
  end

  @doc deprecated: "Use KeenAuthPermissions.Permissions.list/2 instead"
  def get_permissions(%User{} = user, tenant_id \\ 1) do
    Permissions.list(ctx(user), tenant_id)
  end

  @doc deprecated: "Use KeenAuthPermissions.PermSets.list/2 instead"
  def get_perm_sets(%User{} = user, tenant_id \\ 1) do
    PermSets.list(ctx(user), tenant_id)
  end
end
