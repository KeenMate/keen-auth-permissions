# This code has been auto-generated
# Changes to this file will be lost on next generation

defmodule KeenAuthPermissions.Database.Models.AuthSearchApiKeysItem do
  @fields [
    :created_by,
    :created,
    :modified_by,
    :modified,
    :api_key_id,
    :tenant_id,
    :title,
    :description,
    :api_key,
    :expire_at,
    :notification_email,
    :total_items
  ]

  @enforce_keys @fields

  defstruct @fields

  @type t() :: %KeenAuthPermissions.Database.Models.AuthSearchApiKeysItem{}
end