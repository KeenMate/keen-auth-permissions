defmodule KeenAuthPermissions.Managers.GroupsManager do
  require Logger

  alias KeenAuthPermissions.Providers.GroupsProvider
  alias KeenAuthPermissions.Providers.PermissionsProvider
  alias KeenAuthPermissions.User

  import KeenAuthPermissions.Managers.ManagerHelpers

  def get_groups(%User{} = user, tenant \\ 1) do
    GroupsProvider.get_groups(user, num(tenant))
  end

  def enable_group(%User{} = user, group_id, tenant \\ 1) do
    GroupsProvider.enable_group(user, num(group_id), num(tenant))
  end

  def disable_group(%User{} = user, group_id, tenant \\ 1) do
    GroupsProvider.disable_group(user, num(group_id), num(tenant))
  end

  def lock_group(%User{} = user, group_id, tenant \\ 1) do
    GroupsProvider.lock_group(user, num(group_id), num(tenant))
  end

  def unlock_group(%User{} = user, group_id, tenant \\ 1) do
    GroupsProvider.unlock_group(user, num(group_id), num(tenant))
  end

  def delete_group(%User{} = user, group_id, tenant \\ 1) do
    GroupsProvider.delete_group(user, num(group_id), num(tenant))
  end

  def group_info(%User{} = user, group_id, tenant \\ 1) do
    with {:ok, [group_info]} <- GroupsProvider.group_info(user, num(group_id), num(tenant)),
         {:ok, members} <-
           GroupsProvider.get_group_members(user, num(group_id), num(tenant)),
         {:ok, mappings} <-
           get_user_group_mappings(%User{} = user, num(group_id), num(tenant)) do
      group_info = Map.put(group_info, :members, members)
      group_info = Map.put(group_info, :mappings, mappings)
      {:ok, group_info}
    end
  end

  def get_group_members(%User{} = user, group, tenant \\ 1) do
    GroupsProvider.get_group_members(user, num(group), num(tenant))
  end

  def create_group(%User{} = user, group, tenant \\ 1) do
    is_assignable = Map.get(group, :is_assignable, true)
    is_active = Map.get(group, :is_active, true)
    is_external = Map.get(group, :is_external, false)
    is_default = Map.get(group, :is_default, false)

    with {:ok, [new_group_id]} <-
           GroupsProvider.create_group(
             user,
             group.title,
             is_assignable,
             is_active,
             is_external,
             is_default,
             num(tenant)
           ) do
      {:ok, new_group_id}
    end
  end

  def add_member_to_group(%User{} = user, group_id, target_user_id, tenant \\ 1) do
    user = user
    tenant = num(tenant)
    group_id = num(group_id)
    target_user_id = num(target_user_id)

    with {:ok, [member_id]} <-
           GroupsProvider.add_group_member(user, group_id, target_user_id, tenant) do
      {:ok, member_id}
    end
  end

  def remove_member_from_group(%User{} = user, group_id, target_user_id, tenant \\ 1) do
    user = user
    tenant = num(tenant)
    group_id = num(group_id)
    target_user_id = num(target_user_id)

    with {:ok, [member_id]} <-
           GroupsProvider.remove_group_member(user, group_id, target_user_id, tenant) do
      {:ok, member_id}
    end
  end

  def get_user_group_mappings(
        %User{} = user,
        group_id,
        tenant
      ) do
    user = user
    tenant = num(tenant)
    group_id = num(group_id)

    case GroupsProvider.get_user_group_mapping(
           user,
           group_id,
           tenant
         ) do
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

  def create_user_group_mapping(
        %User{} = user,
        group_id,
        provider_code,
        mapped_object_name,
        mapped_target,
        mapping_type,
        tenant \\ 1
      ) do
    user = user
    tenant = num(tenant)
    group_id = num(group_id)

    {mapped_object_id, mapped_role} =
      case mapping_type do
        "role" ->
          {nil, mapped_target}

        "group" ->
          {mapped_target, nil}
      end

    with {:ok, [result]} <-
           GroupsProvider.create_user_group_mapping(
             user,
             group_id,
             provider_code,
             mapped_object_id,
             mapped_object_name,
             mapped_role,
             tenant
           ) do
      {:ok, result}
    end
  end

  def delete_user_group_mapping(%User{} = user, group_mapping_id, tenant \\ 1) do
    user = user
    tenant = num(tenant)
    group_mapping_id = num(group_mapping_id)

    GroupsProvider.delete_user_group_mapping(user, group_mapping_id, tenant)
  end

  def get_assigned_permissions(%User{} = user, group, tenant \\ 1) do
    user = user
    tenant = num(tenant)
    group = num(group)

    GroupsProvider.get_assigned_permissions(user, group, tenant)
  end

  def assign_permission(%User{} = user, group_id, perm_code, perm_set_code, tenant \\ 1) do
    user = user
    group_id = num(group_id)

    cond do
      perm_code == nil and perm_set_code == nil ->
        {:error, :both_cant_be_null}

      perm_code != nil and perm_set_code != nil ->
        {:error, :cannot_use_both}

      true ->
        PermissionsProvider.assign_permission(
          user,
          group_id,
          nil,
          perm_set_code,
          perm_code,
          tenant
        )
    end
  end

  def unassign_permission(%User{} = user, assignment_id, tenant \\ 1) do
    user = user
    assignment_id = num(assignment_id)

    PermissionsProvider.unassign_permission(user, assignment_id, tenant)
  end
end
