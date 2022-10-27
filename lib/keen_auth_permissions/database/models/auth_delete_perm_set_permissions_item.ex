# This code has been auto-generated
# Changes to this file will be lost on next generation

defmodule KeenAuthPermissions.Database.Models.AuthDeletePermSetPermissionsItem do
  @fields [
    :perm_set_id,
    :perm_set_code,
    :permission_id,
    :permission_code
  ]

  @enforce_keys @fields

  defstruct @fields

  @type t() :: %KeenAuthPermissions.Database.Models.AuthDeletePermSetPermissionsItem{}
end