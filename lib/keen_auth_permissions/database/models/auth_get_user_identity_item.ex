# This code has been auto-generated
# Changes to this file will be lost on next generation

defmodule KeenAuthPermissions.Database.Models.AuthGetUserIdentityItem do
  @fields [
    :user_identity_id,
    :provider_code,
    :uid,
    :user_id,
    :provider_groups,
    :provider_roles,
    :user_data
  ]

  @enforce_keys @fields

  defstruct @fields

  @type t() :: %KeenAuthPermissions.Database.Models.AuthGetUserIdentityItem{}
end