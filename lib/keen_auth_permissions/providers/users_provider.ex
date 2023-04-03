defmodule KeenAuthPermissions.Providers.UsersProvider do
  alias KeenAuthPermissions.Error.ErrorParsers

  def db_context() do
    KeenAuthPermissions.DbContext.get_global_db_context()
  end

  def get_all_users(
        %KeenAuthPermissions.User{username: username, user_id: user_id},
        tenant_id \\ 1
      ) do
    db_context().auth_get_tenant_users(username, user_id, tenant_id)
    |> ErrorParsers.parse_if_error()
  end

  def enable_user(
        %KeenAuthPermissions.User{username: username, user_id: user_id},
        target_user_id
      ) do
    db_context().auth_enable_user(username, user_id, target_user_id)
    |> ErrorParsers.parse_if_error()
  end

  def disable_user(
        %KeenAuthPermissions.User{username: username, user_id: user_id},
        target_user_id
      ) do
    db_context().auth_disable_user(username, user_id, target_user_id)
    |> ErrorParsers.parse_if_error()
  end

  def lock_user(
        %KeenAuthPermissions.User{username: username, user_id: user_id},
        target_user_id
      ) do
    db_context().auth_lock_user(username, user_id, target_user_id)
    |> ErrorParsers.parse_if_error()
  end

  def unlock_user(
        %KeenAuthPermissions.User{username: username, user_id: user_id},
        target_user_id
      ) do
    db_context().auth_unlock_user(username, user_id, target_user_id)
    |> ErrorParsers.parse_if_error()
  end
end
