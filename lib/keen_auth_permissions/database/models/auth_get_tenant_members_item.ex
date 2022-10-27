# This code has been auto-generated
# Changes to this file will be lost on next generation

defmodule KeenAuthPermissions.Database.Models.AuthGetTenantMembersItem do
  @fields [
    :user_group_id,
    :group_code,
    :group_title,
    :members_count
  ]

  @enforce_keys @fields

  defstruct @fields

  @type t() :: %KeenAuthPermissions.Database.Models.AuthGetTenantMembersItem{}
end