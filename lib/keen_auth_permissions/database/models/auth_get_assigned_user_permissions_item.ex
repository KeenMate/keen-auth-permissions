# This code has been auto-generated
# Changes to this file will be lost on next generation

defmodule KeenAuthPermissions.Database.Models.AuthGetAssignedUserPermissionsItem do
  @fields [
    :permissions,
    :perm_set_title,
    :perm_set_id,
    :perm_set_code,
    :assignment_id,
    :group_id
  ]

  @enforce_keys @fields

  defstruct @fields

  @type t() :: %KeenAuthPermissions.Database.Models.AuthGetAssignedUserPermissionsItem{}
end