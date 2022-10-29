# This code has been auto-generated
# Changes to this file will be lost on next generation

defmodule KeenAuthPermissions.Database.Models.AuthGetUserGroupMembersItem do
  @fields [
    :created,
    :created_by,
    :member_id,
    :manual_assignment,
    :user_id,
    :user_display_name,
    :user_is_system,
    :user_is_active,
    :user_is_locked,
    :mapping_id,
    :mapping_mapped_object_name,
    :mapping_provider_code
  ]

  @enforce_keys @fields

  defstruct @fields

  @type t() :: %KeenAuthPermissions.Database.Models.AuthGetUserGroupMembersItem{}
end