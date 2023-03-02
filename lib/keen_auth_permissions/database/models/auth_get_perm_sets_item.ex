# This code has been auto-generated
# Changes to this file will be lost on next generation

defmodule KeenAuthPermissions.Database.Models.AuthGetPermSetsItem do
  @fields [
    :perm_set_id,
    :title,
    :code,
    :is_system,
    :is_assignable,
    :permissions
  ]

  @enforce_keys @fields

  defstruct @fields

  @type t() :: %KeenAuthPermissions.Database.Models.AuthGetPermSetsItem{}
end