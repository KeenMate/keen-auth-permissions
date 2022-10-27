# This code has been auto-generated
# Changes to this file will be lost on next generation

defmodule KeenAuthPermissions.Database.Models.AuthGetTenantByIdItem do
  @fields [
    :created,
    :created_by,
    :modified,
    :modified_by,
    :tenant_id,
    :uuid,
    :title,
    :code,
    :is_removable,
    :is_assignable
  ]

  @enforce_keys @fields

  defstruct @fields

  @type t() :: %KeenAuthPermissions.Database.Models.AuthGetTenantByIdItem{}
end