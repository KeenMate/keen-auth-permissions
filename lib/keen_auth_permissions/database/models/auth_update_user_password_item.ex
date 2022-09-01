# This code has been auto-generated
# Changes to this file will be lost on next generation

defmodule KeenAuthPermissions.Database.Models.AuthUpdateUserPasswordItem do
  @fields [
    :user_id,
    :provider_code,
    :provider_uid
  ]

  @enforce_keys @fields

  defstruct @fields

  @type t() :: %KeenAuthPermissions.Database.Models.AuthUpdateUserPasswordItem{}
end