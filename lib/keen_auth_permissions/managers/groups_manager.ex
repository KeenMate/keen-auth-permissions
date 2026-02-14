defmodule KeenAuthPermissions.Managers.GroupsManager do
  @moduledoc """
  DEPRECATED: Use `KeenAuthPermissions.UserGroups` and `KeenAuthPermissions.Permissions` instead.

  This module is kept for backward compatibility and delegates to the new facades.
  """

  @deprecated "Use KeenAuthPermissions.UserGroups or KeenAuthPermissions.Permissions instead"

  require Logger

  alias KeenAuthPermissions.UserGroups
  alias KeenAuthPermissions.Permissions
  alias KeenAuthPermissions.User
  alias KeenAuthPermissions.RequestContext

  import KeenAuthPermissions.Managers.ManagerHelpers

  defp ctx(%User{} = user), do: RequestContext.new(user)

  @doc deprecated: "Use KeenAuthPermissions.UserGroups.list/2 instead"
  def get_groups(%User{} = user, tenant \\ 1) do
    UserGroups.list(ctx(user), num(tenant))
  end

  @doc deprecated: "Use KeenAuthPermissions.UserGroups.enable/3 instead"
  def enable_group(%User{} = user, group_id, tenant \\ 1) do
    UserGroups.enable(ctx(user), num(group_id), num(tenant))
  end

  @doc deprecated: "Use KeenAuthPermissions.UserGroups.disable/3 instead"
  def disable_group(%User{} = user, group_id, tenant \\ 1) do
    UserGroups.disable(ctx(user), num(group_id), num(tenant))
  end

  @doc deprecated: "Use KeenAuthPermissions.UserGroups.lock/3 instead"
  def lock_group(%User{} = user, group_id, tenant \\ 1) do
    UserGroups.lock(ctx(user), num(group_id), num(tenant))
  end

  @doc deprecated: "Use KeenAuthPermissions.UserGroups.unlock/3 instead"
  def unlock_group(%User{} = user, group_id, tenant \\ 1) do
    UserGroups.unlock(ctx(user), num(group_id), num(tenant))
  end

  @doc deprecated: "Use KeenAuthPermissions.UserGroups.delete/3 instead"
  def delete_group(%User{} = user, group_id, tenant \\ 1) do
    UserGroups.delete(ctx(user), num(group_id), num(tenant))
  end

  @doc deprecated:
         "Use KeenAuthPermissions.UserGroups.get_by_id/3, list_members/3, and list_mappings/3 instead"
  def group_info(%User{} = user, group_id, tenant \\ 1) do
    with {:ok, group_info} <- UserGroups.get_by_id(ctx(user), num(group_id), num(tenant)),
         {:ok, members} <- UserGroups.list_members(ctx(user), num(group_id), num(tenant)),
         {:ok, mappings} <- get_user_group_mappings(user, num(group_id), num(tenant)) do
      group_info = Map.put(group_info, :members, members)
      group_info = Map.put(group_info, :mappings, mappings)
      {:ok, group_info}
    end
  end

  @doc deprecated: "Use KeenAuthPermissions.UserGroups.list_members/3 instead"
  def get_group_members(%User{} = user, group, tenant \\ 1) do
    UserGroups.list_members(ctx(user), num(group), num(tenant))
  end

  @doc deprecated: "Use KeenAuthPermissions.UserGroups.create/7 instead"
  def create_group(%User{} = user, group, tenant \\ 1) do
    is_assignable = Map.get(group, :is_assignable, true)
    is_active = Map.get(group, :is_active, true)
    is_external = Map.get(group, :is_external, false)
    is_default = Map.get(group, :is_default, false)

    UserGroups.create(
      ctx(user),
      group.title,
      is_assignable,
      is_active,
      is_external,
      is_default,
      num(tenant)
    )
  end

  @doc deprecated: "Use KeenAuthPermissions.UserGroups.add_member/4 instead"
  def add_member_to_group(%User{} = user, group_id, target_user_id, tenant \\ 1) do
    UserGroups.add_member(ctx(user), num(group_id), num(target_user_id), num(tenant))
  end

  @doc deprecated: "Use KeenAuthPermissions.UserGroups.remove_member/4 instead"
  def remove_member_from_group(%User{} = user, group_id, target_user_id, tenant \\ 1) do
    UserGroups.remove_member(ctx(user), num(group_id), num(target_user_id), num(tenant))
  end

  @doc deprecated: "Use KeenAuthPermissions.UserGroups.list_mappings/3 instead"
  def get_user_group_mappings(%User{} = user, group_id, tenant) do
    case UserGroups.list_mappings(ctx(user), num(group_id), num(tenant)) do
      {:ok, data} ->
        data = Enum.map(data, &transform_group_maping(&1))
        {:ok, data}

      {:error, reason} ->
        Logger.error("Could not get mappings for group",
          reason: inspect(reason),
          detail: %{user: user, tenant: tenant, group_id: group_id}
        )

        {:error, reason}
    end
  end

  defp transform_group_maping(mapping) do
    # add value and type fields matching values you send when creating new mapping
    type = if mapping.mapped_role != nil, do: :role, else: :group

    value =
      case type do
        :role -> Map.get(mapping, :mapped_role)
        :group -> Map.get(mapping, :mapped_object_id)
      end

    mapping
    |> Map.put(:type, type)
    |> Map.put(:mapped_value, value)
    |> Map.put(:name, mapping.mapped_object_name)
  end

  @doc deprecated: "Use KeenAuthPermissions.UserGroups.create_mapping/7 instead"
  def create_user_group_mapping(
        %User{} = user,
        group_id,
        provider_code,
        mapped_object_name,
        mapped_target,
        mapping_type,
        tenant \\ 1
      ) do
    {mapped_object_id, mapped_role} =
      case mapping_type do
        "role" -> {nil, mapped_target}
        "group" -> {mapped_target, nil}
      end

    UserGroups.create_mapping(
      ctx(user),
      num(group_id),
      provider_code,
      mapped_object_id,
      mapped_object_name,
      mapped_role,
      num(tenant)
    )
  end

  @doc deprecated: "Use KeenAuthPermissions.UserGroups.delete_mapping/3 instead"
  def delete_user_group_mapping(%User{} = user, group_mapping_id, tenant \\ 1) do
    UserGroups.delete_mapping(ctx(user), num(group_mapping_id), num(tenant))
  end

  @doc deprecated: "Use KeenAuthPermissions.UserGroups.list_assigned_permissions/3 instead"
  def get_assigned_permissions(%User{} = user, group, tenant \\ 1) do
    UserGroups.list_assigned_permissions(ctx(user), num(group), num(tenant))
  end

  @doc deprecated: "Use KeenAuthPermissions.Permissions.assign/6 instead"
  def assign_permission(%User{} = user, group_id, perm_code, perm_set_code, tenant \\ 1) do
    cond do
      perm_code == nil and perm_set_code == nil ->
        {:error, :both_cant_be_null}

      perm_code != nil and perm_set_code != nil ->
        {:error, :cannot_use_both}

      true ->
        Permissions.assign(ctx(user), num(group_id), nil, perm_set_code, perm_code, tenant)
    end
  end

  @doc deprecated: "Use KeenAuthPermissions.Permissions.unassign/3 instead"
  def unassign_permission(%User{} = user, assignment_id, tenant \\ 1) do
    Permissions.unassign(ctx(user), num(assignment_id), tenant)
  end
end
