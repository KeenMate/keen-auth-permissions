defmodule KeenAuthPermissions.Providers.UsersProvider do
  @moduledoc """
  DEPRECATED: Use `KeenAuthPermissions.Users` instead.

  This module is kept for backward compatibility and delegates to the new facade.
  """

  @deprecated "Use KeenAuthPermissions.Users instead"

  alias KeenAuthPermissions.Users
  alias KeenAuthPermissions.User
  alias KeenAuthPermissions.RequestContext

  defp ctx(%User{} = user), do: RequestContext.new(user)

  @doc deprecated: "Use KeenAuthPermissions.Users.list/2 instead"
  def get_all_users(%User{} = user, tenant_id \\ 1) do
    Users.list(ctx(user), tenant_id)
  end

  @doc deprecated: "Use KeenAuthPermissions.Users.enable/2 instead"
  def enable_user(%User{} = user, target_user_id) do
    Users.enable(ctx(user), target_user_id)
  end

  @doc deprecated: "Use KeenAuthPermissions.Users.disable/2 instead"
  def disable_user(%User{} = user, target_user_id) do
    Users.disable(ctx(user), target_user_id)
  end

  @doc deprecated: "Use KeenAuthPermissions.Users.lock/2 instead"
  def lock_user(%User{} = user, target_user_id) do
    Users.lock(ctx(user), target_user_id)
  end

  @doc deprecated: "Use KeenAuthPermissions.Users.unlock/2 instead"
  def unlock_user(%User{} = user, target_user_id) do
    Users.unlock(ctx(user), target_user_id)
  end
end
