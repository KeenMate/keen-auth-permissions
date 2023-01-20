# This code has been auto-generated
# Changes to this file will be lost on next generation

defmodule KeenAuthPermissions.Database.Models.AuthLockUserGroupItem do
  @fields [
    :user_group_id,
    :is_active,
    :is_assignable,
    :modified,
    :modified_by
  ]

  @enforce_keys @fields

  defstruct @fields

  @type t() :: %KeenAuthPermissions.Database.Models.AuthLockUserGroupItem{}
end