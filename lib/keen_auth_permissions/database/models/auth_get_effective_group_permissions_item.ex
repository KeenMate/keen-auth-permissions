# This code has been auto-generated
# Changes to this file will be lost on next generation

defmodule KeenAuthPermissions.Database.Models.AuthGetEffectiveGroupPermissionsItem do
  @fields [
    :full_code,
    :permission_title,
    :perm_set_title,
    :perm_set_code,
    :perm_set_id,
    :assignment_id
  ]

  @enforce_keys @fields

  defstruct @fields

  @type t() :: %KeenAuthPermissions.Database.Models.AuthGetEffectiveGroupPermissionsItem{}
end