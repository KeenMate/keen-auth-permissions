# This code has been auto-generated
# Changes to this file will be lost on next generation

defmodule KeenAuthPermissions.Database.Models.AuthGetUserByEmailForAuthenticationItem do
  @fields [
    :user_id,
    :code,
    :uuid,
    :username,
    :email,
    :display_name,
    :provider,
    :password_hash,
    :password_salt
  ]

  @enforce_keys @fields

  defstruct @fields

  @type t() :: %KeenAuthPermissions.Database.Models.AuthGetUserByEmailForAuthenticationItem{}
end