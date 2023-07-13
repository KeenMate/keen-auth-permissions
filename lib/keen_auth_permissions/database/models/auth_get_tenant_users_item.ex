# This code has been auto-generated
# Changes to this file will be lost on next generation

defmodule KeenAuthPermissions.Database.Models.AuthGetTenantUsersItem do
  @fields [
    :user_id,
    :username,
    :display_name,
    :user_groups
  ]

  @enforce_keys @fields

  defstruct @fields

  @type t() :: %KeenAuthPermissions.Database.Models.AuthGetTenantUsersItem{}
end