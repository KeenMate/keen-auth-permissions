# This code has been auto-generated
# Changes to this file will be lost on next generation

defmodule KeenAuthPermissions.Database.Models.AuthGetUserDataItem do
  @fields [
    :created,
    :created_by,
    :modified,
    :modified_by,
    :user_data_id,
    :user_id,
    :first_name,
    :middle_name,
    :last_name
  ]

  @enforce_keys @fields

  defstruct @fields

  @type t() :: %KeenAuthPermissions.Database.Models.AuthGetUserDataItem{}
end