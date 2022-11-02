# This code has been auto-generated
# Changes to this file will be lost on next generation

defmodule KeenAuthPermissions.Database.Models.AuthGetUserGroupByIdItem do
  @fields [
    :user_group_id,
    :tenant_id,
    :title,
    :code,
    :is_system,
    :is_external,
    :is_assignable,
    :is_active,
    :is_default
  ]

  @enforce_keys @fields

  defstruct @fields

  @type t() :: %KeenAuthPermissions.Database.Models.AuthGetUserGroupByIdItem{}
end