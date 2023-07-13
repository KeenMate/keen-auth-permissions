defmodule KeenAuthPermissions.Providers.PermissionsProvider do
  alias KeenAuthPermissions.Error.ErrorParsers

  def db_context() do
    KeenAuthPermissions.DbContext.get_global_db_context()
  end

  def assign_permission(
        %KeenAuthPermissions.User{username: username, user_id: user_id},
        user_group_id,
        target_user_id,
        perm_set_code,
        perm_code,
        tenant_id \\ 1
      ) do
    db_context().auth_assign_permission(
      username,
      user_id,
      user_group_id,
      target_user_id,
      perm_set_code,
      perm_code,
      tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  def unassign_permission(
        %KeenAuthPermissions.User{username: username, user_id: user_id},
        assignment_id,
        tenant_id \\ 1
      ) do
    db_context().auth_unassign_permission(
      username,
      user_id,
      assignment_id,
      tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  def get_permissions(
        %KeenAuthPermissions.User{username: username, user_id: user_id},
        tenant_id \\ 1
      ) do
    db_context().auth_get_all_permissions(username, user_id, tenant_id)
    |> ErrorParsers.parse_if_error()
  end

  def get_perm_sets(
        %KeenAuthPermissions.User{username: username, user_id: user_id},
        tenant_id \\ 1
      ) do
    db_context().auth_get_perm_sets(username, user_id, tenant_id) |> ErrorParsers.parse_if_error()
  end

  # get all permissions
  # get all perm sets
end
