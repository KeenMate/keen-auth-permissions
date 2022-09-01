# This code has been auto-generated
# Changes to this file will be lost on next generation

defmodule KeenAuthPermissions.Database.Models.AuthGetUserByUsernameItem do
  @fields [
    :user_id,
    :code,
    :uuid,
    :username,
    :email,
    :display_name,
    :roles,
    :permissions
  ]

  @enforce_keys @fields

  defstruct @fields

  @type t() :: %KeenAuthPermissions.Database.Models.AuthGetUserByUsernameItem{}
end