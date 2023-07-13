# This code has been auto-generated
# Changes to this file will be lost on next generation

defmodule KeenAuthPermissions.Database.Models.AuthCreateApiKeyItem do
  @fields [
    :api_key_id,
    :api_key,
    :api_secret
  ]

  @enforce_keys @fields

  defstruct @fields

  @type t() :: %KeenAuthPermissions.Database.Models.AuthCreateApiKeyItem{}
end