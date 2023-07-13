# This code has been auto-generated
# Changes to this file will be lost on next generation

defmodule KeenAuthPermissions.Database.Models.AuthCreatePermSetItem do
  @fields [
    :created,
    :created_by,
    :modified,
    :modified_by,
    :perm_set_id,
    :tenant_id,
    :title,
    :code,
    :is_system,
    :is_assignable
  ]

  @enforce_keys @fields

  defstruct @fields

  @type t() :: %KeenAuthPermissions.Database.Models.AuthCreatePermSetItem{}
end