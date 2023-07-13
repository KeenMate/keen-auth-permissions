# This code has been auto-generated
# Changes to this file will be lost on next generation

defmodule KeenAuthPermissions.Database.Models.AuthEnableUserIdentityItem do
  @fields [
    :user_identity_id,
    :is_active
  ]

  @enforce_keys @fields

  defstruct @fields

  @type t() :: %KeenAuthPermissions.Database.Models.AuthEnableUserIdentityItem{}
end