# This code has been auto-generated
# Changes to this file will be lost on next generation

defmodule KeenAuthPermissions.Database.Models.AuthUnassignPermissionItem do
  @fields [
    :created,
    :created_by,
    :assignment_id,
    :tenant_id,
    :group_id,
    :user_id,
    :perm_set_id,
    :permission_id
  ]

  @enforce_keys @fields

  defstruct @fields

  @type t() :: %KeenAuthPermissions.Database.Models.AuthUnassignPermissionItem{}
end