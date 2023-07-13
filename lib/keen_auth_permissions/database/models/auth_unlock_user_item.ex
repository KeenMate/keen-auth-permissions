# This code has been auto-generated
# Changes to this file will be lost on next generation

defmodule KeenAuthPermissions.Database.Models.AuthUnlockUserItem do
  @fields [
    :user_id,
    :is_active,
    :is_locked
  ]

  @enforce_keys @fields

  defstruct @fields

  @type t() :: %KeenAuthPermissions.Database.Models.AuthUnlockUserItem{}
end