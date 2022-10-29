# This code has been auto-generated
# Changes to this file will be lost on next generation

defmodule KeenAuthPermissions.Database.Models.AuthGetTenantMembersItem do
  @fields [
    :user_id,
    :user_display_name,
    :user_code,
    :user_uuid,
    :user_tenant_groups
  ]

  @enforce_keys @fields

  defstruct @fields

  @type t() :: %KeenAuthPermissions.Database.Models.AuthGetTenantMembersItem{}
end