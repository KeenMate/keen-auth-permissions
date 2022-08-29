# This code has been auto-generated
# Changes to this file will be lost on next generation

defmodule KeenAuthPermissions.Database.Models.AuthCreateTokenItem do
  @fields [
    :token_id,
    :token_uid,
    :expires_at
  ]

  @enforce_keys @fields

  defstruct @fields

  @type t() :: %KeenAuthPermissions.Database.Models.AuthCreateTokenItem{}
end