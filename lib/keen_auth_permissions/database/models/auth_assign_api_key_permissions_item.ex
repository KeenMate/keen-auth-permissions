# This code has been auto-generated
# Changes to this file will be lost on next generation

defmodule KeenAuthPermissions.Database.Models.AuthAssignApiKeyPermissionsItem do
  @fields [
    :assignment_id,
    :perm_set_id,
    :perm_set_code,
    :perm_set_title,
    :permission_full_code,
    :permission_full_title,
    :permission_title
  ]

  @enforce_keys @fields

  defstruct @fields

  @type t() :: %KeenAuthPermissions.Database.Models.AuthAssignApiKeyPermissionsItem{}
end