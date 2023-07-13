# This code has been auto-generated
# Changes to this file will be lost on next generation

defmodule KeenAuthPermissions.Database.Models.AuthEnsureGroupsAndPermissionsItem do
  @fields [
    :tenant_id,
    :groups,
    :permissions
  ]

  @enforce_keys @fields

  defstruct @fields

  @type t() :: %KeenAuthPermissions.Database.Models.AuthEnsureGroupsAndPermissionsItem{}
end