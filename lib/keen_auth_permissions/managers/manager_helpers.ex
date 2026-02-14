defmodule KeenAuthPermissions.Managers.ManagerHelpers do
  @moduledoc """
  DEPRECATED: Helper utilities for managers.

  The manager layer is deprecated. Use the new facade modules instead:
  - `KeenAuthPermissions.Users`
  - `KeenAuthPermissions.UserGroups`
  - `KeenAuthPermissions.Permissions`
  - `KeenAuthPermissions.Tenants`
  - `KeenAuthPermissions.ApiKeys`
  - `KeenAuthPermissions.Auth`
  - `KeenAuthPermissions.PermSets`
  """

  @deprecated "Use the new facade modules instead"

  def user(conn) when conn.assigns.current_user != nil, do: conn.assigns.current_user

  @doc """
  Ensure that variable is number
  """
  def num(n) when is_bitstring(n) do
    {n, _} = Integer.parse(n)
    n
  end

  def num(n) when is_number(n), do: n
end
