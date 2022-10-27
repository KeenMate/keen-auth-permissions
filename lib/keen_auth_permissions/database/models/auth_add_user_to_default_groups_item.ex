# This code has been auto-generated
# Changes to this file will be lost on next generation

defmodule KeenAuthPermissions.Database.Models.AuthAddUserToDefaultGroupsItem do
  @fields [
    :user_id,
    :user_group_id,
    :user_group_code,
    :user_group_title
  ]

  @enforce_keys @fields

  defstruct @fields

  @type t() :: %KeenAuthPermissions.Database.Models.AuthAddUserToDefaultGroupsItem{}
end