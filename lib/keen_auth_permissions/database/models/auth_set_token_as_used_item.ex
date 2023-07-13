# This code has been auto-generated
# Changes to this file will be lost on next generation

defmodule KeenAuthPermissions.Database.Models.AuthSetTokenAsUsedItem do
  @fields [
    :token_id,
    :token_uid,
    :token_state_code,
    :used_at,
    :user_id,
    :user_oid
  ]

  @enforce_keys @fields

  defstruct @fields

  @type t() :: %KeenAuthPermissions.Database.Models.AuthSetTokenAsUsedItem{}
end