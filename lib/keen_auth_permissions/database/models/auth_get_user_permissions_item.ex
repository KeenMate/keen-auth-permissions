# This code has been auto-generated
# Changes to this file will be lost on next generation

defmodule KeenAuthPermissions.Database.Models.AuthGetUserPermissionsItem do
  @fields [
    :assignment_id,
    :perm_set_code,
    :perm_set_title,
    :user_group_member_id,
    :user_group_title,
    :permission_inheritance_type,
    :permission_code,
    :permission_title
  ]

  @enforce_keys @fields

  defstruct @fields

  @type t() :: %KeenAuthPermissions.Database.Models.AuthGetUserPermissionsItem{}
end