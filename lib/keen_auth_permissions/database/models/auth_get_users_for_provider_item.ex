# This code has been auto-generated
# Changes to this file will be lost on next generation

defmodule KeenAuthPermissions.Database.Models.AuthGetUsersForProviderItem do
  @fields [
    :user_id,
    :user_identity_id,
    :username,
    :display_name
  ]

  @enforce_keys @fields

  defstruct @fields

  @type t() :: %KeenAuthPermissions.Database.Models.AuthGetUsersForProviderItem{}
end