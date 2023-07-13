defmodule KeenAuthPermissions.Providers.GroupsProvider do
  alias KeenAuthPermissions.Error.ErrorParsers

  def db_context() do
    KeenAuthPermissions.DbContext.get_global_db_context()
  end

  def get_groups(%KeenAuthPermissions.User{username: requested_by, user_id: id}, tenant_id) do
    db_context().auth_get_tenant_groups(requested_by, id, tenant_id)
    |> ErrorParsers.parse_if_error()
  end

  def enable_group(
        %KeenAuthPermissions.User{username: username, user_id: id},
        group_id,
        tenant_id
      ) do
    db_context().auth_enable_user_group(username, id, group_id, tenant_id)
    |> ErrorParsers.parse_if_error()
  end

  def disable_group(
        %KeenAuthPermissions.User{username: username, user_id: id},
        group_id,
        tenant_id
      ) do
    db_context().auth_disable_user_group(username, id, group_id, tenant_id)
    |> ErrorParsers.parse_if_error()
  end

  def lock_group(
        %KeenAuthPermissions.User{username: username, user_id: id},
        group_id,
        tenant_id
      ) do
    db_context().auth_lock_user_group(username, id, group_id, tenant_id)
    |> ErrorParsers.parse_if_error()
  end

  def unlock_group(
        %KeenAuthPermissions.User{username: username, user_id: id},
        group_id,
        tenant_id
      ) do
    db_context().auth_unlock_user_group(username, id, group_id, tenant_id)
    |> ErrorParsers.parse_if_error()
  end

  def delete_group(
        %KeenAuthPermissions.User{username: username, user_id: id},
        group_id,
        tenant_id
      ) do
    db_context().auth_delete_user_group(username, id, group_id, tenant_id)
    |> ErrorParsers.parse_if_error()
  end

  def group_info(
        %KeenAuthPermissions.User{username: username, user_id: id},
        group_id,
        tenant_id
      ) do
    db_context().auth_get_user_group_by_id(username, id, group_id, tenant_id)
    |> ErrorParsers.parse_if_error()
  end

  def get_group_members(
        %KeenAuthPermissions.User{username: username, user_id: id},
        group_id,
        tenant_id
      ) do
    db_context().auth_get_user_group_members(username, id, group_id, tenant_id)
    |> ErrorParsers.parse_if_error()
  end

  def create_group(
        %KeenAuthPermissions.User{username: username, user_id: id},
        title,
        is_assignable,
        is_active,
        is_external,
        is_default,
        tenant_id
      ) do
    IO.inspect(
      [
        username,
        id,
        title,
        is_assignable,
        is_active,
        is_external,
        is_default,
        tenant_id
      ],
      label: "params"
    )

    db_context().auth_create_user_group(
      username,
      id,
      title,
      is_assignable,
      is_active,
      is_external,
      is_default,
      tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  def add_group_member(
        %KeenAuthPermissions.User{username: username, user_id: user_id},
        group_id,
        target_user_id,
        tenant_id
      ) do
    db_context().auth_create_user_group_member(
      username,
      user_id,
      group_id,
      target_user_id,
      tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  def remove_group_member(
        %KeenAuthPermissions.User{username: username, user_id: user_id},
        group_id,
        target_user_id,
        tenant_id
      ) do
    IO.puts(user_id)
    IO.puts(target_user_id)

    db_context().auth_delete_user_group_member(
      username,
      user_id,
      group_id,
      target_user_id,
      tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  def get_user_group_mapping(
        %KeenAuthPermissions.User{username: username, user_id: user_id},
        group_id,
        tenant_id
      ) do
    db_context().auth_get_user_group_mappings(username, user_id, group_id, tenant_id)
    |> ErrorParsers.parse_if_error()
  end

  def create_user_group_mapping(
        %KeenAuthPermissions.User{username: username, user_id: user_id},
        user_group_id,
        provider_code,
        mapped_object_id,
        mapped_object_name,
        mapped_role,
        tenant_id
      ) do
    db_context().auth_create_user_group_mapping(
      username,
      user_id,
      user_group_id,
      provider_code,
      mapped_object_id,
      mapped_object_name,
      mapped_role,
      tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  def delete_user_group_mapping(
        %KeenAuthPermissions.User{username: username, user_id: user_id},
        user_group_mapping_id,
        tenant_id
      ) do
    db_context().auth_delete_user_group_mapping(
      username,
      user_id,
      user_group_mapping_id,
      tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  def get_assigned_permissions(
        %KeenAuthPermissions.User{username: username, user_id: user_id},
        group_id,
        tenant_id
      ) do
    db_context().auth_get_assigned_group_permissions(
      username,
      user_id,
      group_id,
      tenant_id
    )
  end
end
