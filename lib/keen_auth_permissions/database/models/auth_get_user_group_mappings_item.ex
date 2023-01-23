# This code has been auto-generated
# Changes to this file will be lost on next generation

defmodule KeenAuthPermissions.Database.Models.AuthGetUserGroupMappingsItem do
  @fields [
    :created,
    :created_by,
    :ug_mapping_id,
    :group_id,
    :provider_code,
    :mapped_object_id,
    :mapped_object_name,
    :mapped_role
  ]

  @enforce_keys @fields

  defstruct @fields

  @type t() :: %KeenAuthPermissions.Database.Models.AuthGetUserGroupMappingsItem{}
end