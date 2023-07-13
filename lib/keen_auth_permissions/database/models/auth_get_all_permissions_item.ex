# This code has been auto-generated
# Changes to this file will be lost on next generation

defmodule KeenAuthPermissions.Database.Models.AuthGetAllPermissionsItem do
  @fields [
    :permission_id,
    :is_assignable,
    :title,
    :code,
    :full_code,
    :has_children
  ]

  @enforce_keys @fields

  defstruct @fields

  @type t() :: %KeenAuthPermissions.Database.Models.AuthGetAllPermissionsItem{}
end