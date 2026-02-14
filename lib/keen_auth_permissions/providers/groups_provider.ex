defmodule KeenAuthPermissions.Providers.GroupsProvider do
  @moduledoc """
  DEPRECATED: Use `KeenAuthPermissions.UserGroups` instead.

  This module is kept for backward compatibility and delegates to the new facade.
  """

  @deprecated "Use KeenAuthPermissions.UserGroups instead"

  alias KeenAuthPermissions.UserGroups
  alias KeenAuthPermissions.User
  alias KeenAuthPermissions.RequestContext

  defp ctx(%User{} = user), do: RequestContext.new(user)

  @doc deprecated: "Use KeenAuthPermissions.UserGroups.list/2 instead"
  def get_groups(%User{} = user, tenant_id) do
    UserGroups.list(ctx(user), tenant_id)
  end

  @doc deprecated: "Use KeenAuthPermissions.UserGroups.enable/3 instead"
  def enable_group(%User{} = user, group_id, tenant_id) do
    UserGroups.enable(ctx(user), group_id, tenant_id)
  end

  @doc deprecated: "Use KeenAuthPermissions.UserGroups.disable/3 instead"
  def disable_group(%User{} = user, group_id, tenant_id) do
    UserGroups.disable(ctx(user), group_id, tenant_id)
  end

  @doc deprecated: "Use KeenAuthPermissions.UserGroups.lock/3 instead"
  def lock_group(%User{} = user, group_id, tenant_id) do
    UserGroups.lock(ctx(user), group_id, tenant_id)
  end

  @doc deprecated: "Use KeenAuthPermissions.UserGroups.unlock/3 instead"
  def unlock_group(%User{} = user, group_id, tenant_id) do
    UserGroups.unlock(ctx(user), group_id, tenant_id)
  end

  @doc deprecated: "Use KeenAuthPermissions.UserGroups.delete/3 instead"
  def delete_group(%User{} = user, group_id, tenant_id) do
    UserGroups.delete(ctx(user), group_id, tenant_id)
  end

  @doc deprecated: "Use KeenAuthPermissions.UserGroups.get_by_id/3 instead"
  def group_info(%User{} = user, group_id, tenant_id) do
    # Returns list for backward compatibility
    case UserGroups.get_by_id(ctx(user), group_id, tenant_id) do
      {:ok, result} -> {:ok, [result]}
      error -> error
    end
  end

  @doc deprecated: "Use KeenAuthPermissions.UserGroups.list_members/3 instead"
  def get_group_members(%User{} = user, group_id, tenant_id) do
    UserGroups.list_members(ctx(user), group_id, tenant_id)
  end

  @doc deprecated: "Use KeenAuthPermissions.UserGroups.create/7 instead"
  def create_group(
        %User{} = user,
        title,
        is_assignable,
        is_active,
        is_external,
        is_default,
        tenant_id
      ) do
    # Returns list for backward compatibility
    case UserGroups.create(
           ctx(user),
           title,
           is_assignable,
           is_active,
           is_external,
           is_default,
           tenant_id
         ) do
      {:ok, result} -> {:ok, [result]}
      error -> error
    end
  end

  @doc deprecated: "Use KeenAuthPermissions.UserGroups.add_member/4 instead"
  def add_group_member(%User{} = user, group_id, target_user_id, tenant_id) do
    # Returns list for backward compatibility
    case UserGroups.add_member(ctx(user), group_id, target_user_id, tenant_id) do
      {:ok, result} -> {:ok, [result]}
      error -> error
    end
  end

  @doc deprecated: "Use KeenAuthPermissions.UserGroups.remove_member/4 instead"
  def remove_group_member(%User{} = user, group_id, target_user_id, tenant_id) do
    # Returns list for backward compatibility
    case UserGroups.remove_member(ctx(user), group_id, target_user_id, tenant_id) do
      {:ok, result} -> {:ok, [result]}
      error -> error
    end
  end

  @doc deprecated: "Use KeenAuthPermissions.UserGroups.list_mappings/3 instead"
  def get_user_group_mapping(%User{} = user, group_id, tenant_id) do
    UserGroups.list_mappings(ctx(user), group_id, tenant_id)
  end

  @doc deprecated: "Use KeenAuthPermissions.UserGroups.create_mapping/7 instead"
  def create_user_group_mapping(
        %User{} = user,
        user_group_id,
        provider_code,
        mapped_object_id,
        mapped_object_name,
        mapped_role,
        tenant_id
      ) do
    # Returns list for backward compatibility
    case UserGroups.create_mapping(
           ctx(user),
           user_group_id,
           provider_code,
           mapped_object_id,
           mapped_object_name,
           mapped_role,
           tenant_id
         ) do
      {:ok, result} -> {:ok, [result]}
      error -> error
    end
  end

  @doc deprecated: "Use KeenAuthPermissions.UserGroups.delete_mapping/3 instead"
  def delete_user_group_mapping(%User{} = user, user_group_mapping_id, tenant_id) do
    UserGroups.delete_mapping(ctx(user), user_group_mapping_id, tenant_id)
  end

  @doc deprecated: "Use KeenAuthPermissions.UserGroups.list_assigned_permissions/3 instead"
  def get_assigned_permissions(%User{} = user, group_id, tenant_id) do
    UserGroups.list_assigned_permissions(ctx(user), group_id, tenant_id)
  end
end
