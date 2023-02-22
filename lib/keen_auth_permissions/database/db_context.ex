# This code has been auto-generated
# Changes to this file will be lost on next generation

defmodule KeenAuthPermissions.Database do
  defmacro __using__(opts) do
    quote do
      require Logger

      import unquote(opts[:repo]), only: [query: 2]

      @spec auth_add_perm_set_permissions(binary(), integer(), integer(), any(), integer()) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthAddPermSetPermissionsItem.t()]}
      def auth_add_perm_set_permissions(created_by, user_id, perm_set_id, permissions, tenant_id) do
        Logger.debug("Calling stored procedure", procedure: "add_perm_set_permissions")

        query(
          "select * from auth.add_perm_set_permissions($1, $2, $3, $4, $5)",
          [created_by, user_id, perm_set_id, permissions, tenant_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthAddPermSetPermissionsParser.parse_auth_add_perm_set_permissions_result()
      end

      @spec auth_add_user_to_default_groups(binary(), integer(), integer(), integer()) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthAddUserToDefaultGroupsItem.t()]}
      def auth_add_user_to_default_groups(created_by, user_id, target_user_id, tenant_id) do
        Logger.debug("Calling stored procedure", procedure: "add_user_to_default_groups")

        query(
          "select * from auth.add_user_to_default_groups($1, $2, $3, $4)",
          [created_by, user_id, target_user_id, tenant_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthAddUserToDefaultGroupsParser.parse_auth_add_user_to_default_groups_result()
      end

      @spec auth_assign_api_key_permissions(
              binary(),
              integer(),
              integer(),
              binary(),
              any(),
              integer()
            ) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthAssignApiKeyPermissionsItem.t()]}
      def auth_assign_api_key_permissions(
            created_by,
            user_id,
            api_key_id,
            perm_set_code,
            permission_codes,
            tenant_id
          ) do
        Logger.debug("Calling stored procedure", procedure: "assign_api_key_permissions")

        query(
          "select * from auth.assign_api_key_permissions($1, $2, $3, $4, $5, $6)",
          [created_by, user_id, api_key_id, perm_set_code, permission_codes, tenant_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthAssignApiKeyPermissionsParser.parse_auth_assign_api_key_permissions_result()
      end

      @spec auth_assign_permission(
              binary(),
              integer(),
              integer(),
              integer(),
              binary(),
              binary(),
              integer()
            ) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthAssignPermissionItem.t()]}
      def auth_assign_permission(
            created_by,
            user_id,
            user_group_id,
            target_user_id,
            perm_set_code,
            perm_code,
            tenant_id
          ) do
        Logger.debug("Calling stored procedure", procedure: "assign_permission")

        query(
          "select * from auth.assign_permission($1, $2, $3, $4, $5, $6, $7)",
          [
            created_by,
            user_id,
            user_group_id,
            target_user_id,
            perm_set_code,
            perm_code,
            tenant_id
          ]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthAssignPermissionParser.parse_auth_assign_permission_result()
      end

      @spec auth_can_manage_user_group(integer(), integer(), binary(), integer()) ::
              {:error, any()} | {:ok, [boolean()]}
      def auth_can_manage_user_group(user_id, user_group_id, permission, tenant_id) do
        Logger.debug("Calling stored procedure", procedure: "can_manage_user_group")

        query(
          "select * from auth.can_manage_user_group($1, $2, $3, $4)",
          [user_id, user_group_id, permission, tenant_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthCanManageUserGroupParser.parse_auth_can_manage_user_group_result()
      end

      @spec auth_create_api_key(
              binary(),
              integer(),
              binary(),
              binary(),
              binary(),
              any(),
              binary(),
              binary(),
              integer()
            ) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthCreateApiKeyItem.t()]}
      def auth_create_api_key(
            created_by,
            user_id,
            title,
            description,
            perm_set_code,
            permission_codes,
            api_key,
            api_secret,
            tenant_id
          ) do
        Logger.debug("Calling stored procedure", procedure: "create_api_key")

        query(
          "select * from auth.create_api_key($1, $2, $3, $4, $5, $6, $7, $8, $9)",
          [
            created_by,
            user_id,
            title,
            description,
            perm_set_code,
            permission_codes,
            api_key,
            api_secret,
            tenant_id
          ]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthCreateApiKeyParser.parse_auth_create_api_key_result()
      end

      @spec auth_create_external_user_group(
              binary(),
              integer(),
              binary(),
              binary(),
              boolean(),
              boolean(),
              binary(),
              binary(),
              binary(),
              integer()
            ) :: {:error, any()} | {:ok, [integer()]}
      def auth_create_external_user_group(
            created_by,
            user_id,
            title,
            provider,
            is_assignable,
            is_active,
            mapped_object_id,
            mapped_object_name,
            mapped_role,
            tenant_id
          ) do
        Logger.debug("Calling stored procedure", procedure: "create_external_user_group")

        query(
          "select * from auth.create_external_user_group($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)",
          [
            created_by,
            user_id,
            title,
            provider,
            is_assignable,
            is_active,
            mapped_object_id,
            mapped_object_name,
            mapped_role,
            tenant_id
          ]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthCreateExternalUserGroupParser.parse_auth_create_external_user_group_result()
      end

      @spec auth_create_owner(binary(), integer(), integer(), integer(), integer()) ::
              {:error, any()} | {:ok, [integer()]}
      def auth_create_owner(created_by, user_id, target_user_id, user_group_id, tenant_id) do
        Logger.debug("Calling stored procedure", procedure: "create_owner")

        query(
          "select * from auth.create_owner($1, $2, $3, $4, $5)",
          [created_by, user_id, target_user_id, user_group_id, tenant_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthCreateOwnerParser.parse_auth_create_owner_result()
      end

      @spec auth_create_perm_set(
              binary(),
              binary(),
              binary(),
              boolean(),
              boolean(),
              any(),
              integer()
            ) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthCreatePermSetItem.t()]}
      def auth_create_perm_set(
            created_by,
            user_id,
            title,
            is_system,
            is_assignable,
            permissions,
            tenant_id
          ) do
        Logger.debug("Calling stored procedure", procedure: "create_perm_set")

        query(
          "select * from auth.create_perm_set($1, $2, $3, $4, $5, $6, $7)",
          [created_by, user_id, title, is_system, is_assignable, permissions, tenant_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthCreatePermSetParser.parse_auth_create_perm_set_result()
      end

      @spec auth_create_permission_by_code(binary(), integer(), binary(), binary(), boolean()) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthCreatePermissionByCodeItem.t()]}
      def auth_create_permission_by_code(created_by, user_id, title, parent_code, is_assignable) do
        Logger.debug("Calling stored procedure", procedure: "create_permission_by_code")

        query(
          "select * from auth.create_permission_by_code($1, $2, $3, $4, $5)",
          [created_by, user_id, title, parent_code, is_assignable]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthCreatePermissionByCodeParser.parse_auth_create_permission_by_code_result()
      end

      @spec auth_create_permission_by_path(
              binary(),
              integer(),
              binary(),
              binary(),
              binary(),
              boolean()
            ) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthCreatePermissionByPathItem.t()]}
      def auth_create_permission_by_path(
            created_by,
            user_id,
            data_node_path,
            title,
            parent_path,
            is_assignable
          ) do
        Logger.debug("Calling stored procedure", procedure: "create_permission_by_path")

        query(
          "select * from auth.create_permission_by_path($1, $2, $3, $4, $5, $6)",
          [created_by, user_id, data_node_path, title, parent_path, is_assignable]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthCreatePermissionByPathParser.parse_auth_create_permission_by_path_result()
      end

      @spec auth_create_provider(binary(), integer(), binary(), binary(), boolean()) ::
              {:error, any()} | {:ok, [integer()]}
      def auth_create_provider(created_by, user_id, provider_code, provider_name, is_active) do
        Logger.debug("Calling stored procedure", procedure: "create_provider")

        query(
          "select * from auth.create_provider($1, $2, $3, $4, $5)",
          [created_by, user_id, provider_code, provider_name, is_active]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthCreateProviderParser.parse_auth_create_provider_result()
      end

      @spec auth_create_tenant(
              binary(),
              integer(),
              binary(),
              binary(),
              boolean(),
              boolean(),
              integer()
            ) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthCreateTenantItem.t()]}
      def auth_create_tenant(
            created_by,
            user_id,
            title,
            code,
            is_removable,
            is_assignable,
            tenant_owner_id
          ) do
        Logger.debug("Calling stored procedure", procedure: "create_tenant")

        query(
          "select * from auth.create_tenant($1, $2, $3, $4, $5, $6, $7)",
          [created_by, user_id, title, code, is_removable, is_assignable, tenant_owner_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthCreateTenantParser.parse_auth_create_tenant_result()
      end

      @spec auth_create_token(
              binary(),
              integer(),
              integer(),
              binary(),
              integer(),
              binary(),
              binary(),
              binary(),
              DateTime.t(),
              any()
            ) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthCreateTokenItem.t()]}
      def auth_create_token(
            created_by,
            user_id,
            target_user_id,
            target_user_oid,
            user_event_id,
            token_type_code,
            token_channel_code,
            token,
            expires_at,
            token_data
          ) do
        Logger.debug("Calling stored procedure", procedure: "create_token")

        query(
          "select * from auth.create_token($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)",
          [
            created_by,
            user_id,
            target_user_id,
            target_user_oid,
            user_event_id,
            token_type_code,
            token_channel_code,
            token,
            expires_at,
            token_data
          ]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthCreateTokenParser.parse_auth_create_token_result()
      end

      @spec auth_create_user_event(
              binary(),
              integer(),
              binary(),
              integer(),
              binary(),
              binary(),
              binary(),
              any(),
              binary(),
              binary()
            ) :: {:error, any()} | {:ok, [integer()]}
      def auth_create_user_event(
            created_by,
            user_id,
            event_type_code,
            target_user_id,
            ip_address,
            user_agent,
            origin,
            event_data,
            target_user_oid,
            target_username
          ) do
        Logger.debug("Calling stored procedure", procedure: "create_user_event")

        query(
          "select * from auth.create_user_event($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)",
          [
            created_by,
            user_id,
            event_type_code,
            target_user_id,
            ip_address,
            user_agent,
            origin,
            event_data,
            target_user_oid,
            target_username
          ]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthCreateUserEventParser.parse_auth_create_user_event_result()
      end

      @spec auth_create_user_group(
              binary(),
              integer(),
              binary(),
              integer(),
              boolean(),
              boolean(),
              boolean(),
              boolean()
            ) :: {:error, any()} | {:ok, [integer()]}
      def auth_create_user_group(
            created_by,
            user_id,
            title,
            tenant_id,
            is_assignable,
            is_active,
            is_external,
            is_default
          ) do
        Logger.debug("Calling stored procedure", procedure: "create_user_group")

        query(
          "select * from auth.create_user_group($1, $2, $3, $4, $5, $6, $7, $8)",
          [
            created_by,
            user_id,
            title,
            tenant_id,
            is_assignable,
            is_active,
            is_external,
            is_default
          ]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthCreateUserGroupParser.parse_auth_create_user_group_result()
      end

      @spec auth_create_user_group_mapping(
              binary(),
              integer(),
              integer(),
              binary(),
              binary(),
              binary(),
              binary(),
              integer()
            ) :: {:error, any()} | {:ok, [integer()]}
      def auth_create_user_group_mapping(
            created_by,
            user_id,
            user_group_id,
            provider_code,
            mapped_object_id,
            mapped_object_name,
            mapped_role,
            tenant_id
          ) do
        Logger.debug("Calling stored procedure", procedure: "create_user_group_mapping")

        query(
          "select * from auth.create_user_group_mapping($1, $2, $3, $4, $5, $6, $7, $8)",
          [
            created_by,
            user_id,
            user_group_id,
            provider_code,
            mapped_object_id,
            mapped_object_name,
            mapped_role,
            tenant_id
          ]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthCreateUserGroupMappingParser.parse_auth_create_user_group_mapping_result()
      end

      @spec auth_create_user_group_member(binary(), integer(), integer(), integer(), integer()) ::
              {:error, any()} | {:ok, [integer()]}
      def auth_create_user_group_member(
            created_by,
            user_id,
            user_group_id,
            target_user_id,
            tenant_id
          ) do
        Logger.debug("Calling stored procedure", procedure: "create_user_group_member")

        query(
          "select * from auth.create_user_group_member($1, $2, $3, $4, $5)",
          [created_by, user_id, user_group_id, target_user_id, tenant_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthCreateUserGroupMemberParser.parse_auth_create_user_group_member_result()
      end

      @spec auth_delete_api_key(binary(), integer(), integer()) ::
              {:error, any()} | {:ok, [integer()]}
      def auth_delete_api_key(deleted_by, user_id, api_key_id) do
        Logger.debug("Calling stored procedure", procedure: "delete_api_key")

        query(
          "select * from auth.delete_api_key($1, $2, $3)",
          [deleted_by, user_id, api_key_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthDeleteApiKeyParser.parse_auth_delete_api_key_result()
      end

      @spec auth_delete_owner(binary(), integer(), integer(), integer(), integer()) ::
              {:error, any()} | {:ok, [any()]}
      def auth_delete_owner(deleted_by, user_id, target_user_id, user_group_id, tenant_id) do
        Logger.debug("Calling stored procedure", procedure: "delete_owner")

        query(
          "select * from auth.delete_owner($1, $2, $3, $4, $5)",
          [deleted_by, user_id, target_user_id, user_group_id, tenant_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthDeleteOwnerParser.parse_auth_delete_owner_result()
      end

      @spec auth_delete_perm_set_permissions(binary(), integer(), integer(), any(), integer()) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthDeletePermSetPermissionsItem.t()]}
      def auth_delete_perm_set_permissions(
            created_by,
            user_id,
            perm_set_id,
            permissions,
            tenant_id
          ) do
        Logger.debug("Calling stored procedure", procedure: "delete_perm_set_permissions")

        query(
          "select * from auth.delete_perm_set_permissions($1, $2, $3, $4, $5)",
          [created_by, user_id, perm_set_id, permissions, tenant_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthDeletePermSetPermissionsParser.parse_auth_delete_perm_set_permissions_result()
      end

      @spec auth_delete_provider(binary(), integer(), binary()) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthDeleteProviderItem.t()]}
      def auth_delete_provider(deleted_by, user_id, provider_code) do
        Logger.debug("Calling stored procedure", procedure: "delete_provider")

        query(
          "select * from auth.delete_provider($1, $2, $3)",
          [deleted_by, user_id, provider_code]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthDeleteProviderParser.parse_auth_delete_provider_result()
      end

      @spec auth_delete_user_group(binary(), integer(), integer(), integer()) ::
              {:error, any()} | {:ok, [integer()]}
      def auth_delete_user_group(deleted_by, user_id, user_group_id, tenant_id) do
        Logger.debug("Calling stored procedure", procedure: "delete_user_group")

        query(
          "select * from auth.delete_user_group($1, $2, $3, $4)",
          [deleted_by, user_id, user_group_id, tenant_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthDeleteUserGroupParser.parse_auth_delete_user_group_result()
      end

      @spec auth_delete_user_group_mapping(binary(), integer(), integer(), integer()) ::
              {:error, any()} | {:ok, [any()]}
      def auth_delete_user_group_mapping(deleted_by, user_id, ug_mapping_id, tenant_id) do
        Logger.debug("Calling stored procedure", procedure: "delete_user_group_mapping")

        query(
          "select * from auth.delete_user_group_mapping($1, $2, $3, $4)",
          [deleted_by, user_id, ug_mapping_id, tenant_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthDeleteUserGroupMappingParser.parse_auth_delete_user_group_mapping_result()
      end

      @spec auth_delete_user_group_member(binary(), integer(), integer(), integer(), integer()) ::
              {:error, any()} | {:ok, [any()]}
      def auth_delete_user_group_member(
            deleted_by,
            user_id,
            user_group_id,
            target_user_id,
            tenant_id
          ) do
        Logger.debug("Calling stored procedure", procedure: "delete_user_group_member")

        query(
          "select * from auth.delete_user_group_member($1, $2, $3, $4, $5)",
          [deleted_by, user_id, user_group_id, target_user_id, tenant_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthDeleteUserGroupMemberParser.parse_auth_delete_user_group_member_result()
      end

      @spec auth_disable_provider(binary(), integer(), binary()) ::
              {:error, any()} | {:ok, [integer()]}
      def auth_disable_provider(modified_by, user_id, provider_code) do
        Logger.debug("Calling stored procedure", procedure: "disable_provider")

        query(
          "select * from auth.disable_provider($1, $2, $3)",
          [modified_by, user_id, provider_code]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthDisableProviderParser.parse_auth_disable_provider_result()
      end

      @spec auth_disable_user(binary(), integer(), integer()) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthDisableUserItem.t()]}
      def auth_disable_user(modified_by, user_id, target_user_id) do
        Logger.debug("Calling stored procedure", procedure: "disable_user")

        query(
          "select * from auth.disable_user($1, $2, $3)",
          [modified_by, user_id, target_user_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthDisableUserParser.parse_auth_disable_user_result()
      end

      @spec auth_disable_user_group(binary(), integer(), integer(), integer()) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthDisableUserGroupItem.t()]}
      def auth_disable_user_group(modified_by, user_id, user_group_id, tenant_id) do
        Logger.debug("Calling stored procedure", procedure: "disable_user_group")

        query(
          "select * from auth.disable_user_group($1, $2, $3, $4)",
          [modified_by, user_id, user_group_id, tenant_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthDisableUserGroupParser.parse_auth_disable_user_group_result()
      end

      @spec auth_disable_user_identity(binary(), integer(), integer(), binary()) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthDisableUserIdentityItem.t()]}
      def auth_disable_user_identity(modified_by, user_id, target_user_id, provider_code) do
        Logger.debug("Calling stored procedure", procedure: "disable_user_identity")

        query(
          "select * from auth.disable_user_identity($1, $2, $3, $4)",
          [modified_by, user_id, target_user_id, provider_code]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthDisableUserIdentityParser.parse_auth_disable_user_identity_result()
      end

      @spec auth_enable_provider(binary(), integer(), binary()) ::
              {:error, any()} | {:ok, [integer()]}
      def auth_enable_provider(modified_by, user_id, provider_code) do
        Logger.debug("Calling stored procedure", procedure: "enable_provider")

        query(
          "select * from auth.enable_provider($1, $2, $3)",
          [modified_by, user_id, provider_code]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthEnableProviderParser.parse_auth_enable_provider_result()
      end

      @spec auth_enable_user(binary(), integer(), integer()) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthEnableUserItem.t()]}
      def auth_enable_user(modified_by, user_id, target_user_id) do
        Logger.debug("Calling stored procedure", procedure: "enable_user")

        query(
          "select * from auth.enable_user($1, $2, $3)",
          [modified_by, user_id, target_user_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthEnableUserParser.parse_auth_enable_user_result()
      end

      @spec auth_enable_user_group(binary(), integer(), integer(), integer()) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthEnableUserGroupItem.t()]}
      def auth_enable_user_group(modified_by, user_id, user_group_id, tenant_id) do
        Logger.debug("Calling stored procedure", procedure: "enable_user_group")

        query(
          "select * from auth.enable_user_group($1, $2, $3, $4)",
          [modified_by, user_id, user_group_id, tenant_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthEnableUserGroupParser.parse_auth_enable_user_group_result()
      end

      @spec auth_enable_user_identity(binary(), integer(), integer(), binary()) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthEnableUserIdentityItem.t()]}
      def auth_enable_user_identity(modified_by, user_id, target_user_id, provider_code) do
        Logger.debug("Calling stored procedure", procedure: "enable_user_identity")

        query(
          "select * from auth.enable_user_identity($1, $2, $3, $4)",
          [modified_by, user_id, target_user_id, provider_code]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthEnableUserIdentityParser.parse_auth_enable_user_identity_result()
      end

      @spec auth_ensure_groups_and_permissions(
              binary(),
              integer(),
              integer(),
              binary(),
              any(),
              any(),
              integer()
            ) ::
              {:error, any()}
              | {:ok,
                 [KeenAuthPermissions.Database.Models.AuthEnsureGroupsAndPermissionsItem.t()]}
      def auth_ensure_groups_and_permissions(
            created_by,
            user_id,
            target_user_id,
            provider_code,
            provider_groups,
            provider_roles,
            tenant_id
          ) do
        Logger.debug("Calling stored procedure", procedure: "ensure_groups_and_permissions")

        query(
          "select * from auth.ensure_groups_and_permissions($1, $2, $3, $4, $5, $6, $7)",
          [
            created_by,
            user_id,
            target_user_id,
            provider_code,
            provider_groups,
            provider_roles,
            tenant_id
          ]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthEnsureGroupsAndPermissionsParser.parse_auth_ensure_groups_and_permissions_result()
      end

      @spec auth_ensure_user_from_provider(
              binary(),
              integer(),
              binary(),
              binary(),
              binary(),
              binary(),
              binary(),
              any()
            ) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthEnsureUserFromProviderItem.t()]}
      def auth_ensure_user_from_provider(
            created_by,
            user_id,
            provider_code,
            provider_uid,
            username,
            display_name,
            email,
            user_data
          ) do
        Logger.debug("Calling stored procedure", procedure: "ensure_user_from_provider")

        query(
          "select * from auth.ensure_user_from_provider($1, $2, $3, $4, $5, $6, $7, $8)",
          [
            created_by,
            user_id,
            provider_code,
            provider_uid,
            username,
            display_name,
            email,
            user_data
          ]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthEnsureUserFromProviderParser.parse_auth_ensure_user_from_provider_result()
      end

      @spec auth_ensure_user_info(
              binary(),
              integer(),
              binary(),
              binary(),
              binary(),
              binary(),
              any()
            ) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthEnsureUserInfoItem.t()]}
      def auth_ensure_user_info(
            created_by,
            user_id,
            username,
            display_name,
            provider_code,
            email,
            user_data
          ) do
        Logger.debug("Calling stored procedure", procedure: "ensure_user_info")

        query(
          "select * from auth.ensure_user_info($1, $2, $3, $4, $5, $6, $7)",
          [created_by, user_id, username, display_name, provider_code, email, user_data]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthEnsureUserInfoParser.parse_auth_ensure_user_info_result()
      end

      @spec auth_generate_api_key() :: {:error, any()} | {:ok, [binary()]}
      def auth_generate_api_key() do
        Logger.debug("Calling stored procedure", procedure: "generate_api_key")

        query(
          "select * from auth.generate_api_key()",
          []
        )
        |> KeenAuthPermissions.Database.Parsers.AuthGenerateApiKeyParser.parse_auth_generate_api_key_result()
      end

      @spec auth_generate_api_key_username(binary()) :: {:error, any()} | {:ok, [binary()]}
      def auth_generate_api_key_username(api_key) do
        Logger.debug("Calling stored procedure", procedure: "generate_api_key_username")

        query(
          "select * from auth.generate_api_key_username($1)",
          [api_key]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthGenerateApiKeyUsernameParser.parse_auth_generate_api_key_username_result()
      end

      @spec auth_generate_api_secret() :: {:error, any()} | {:ok, [binary()]}
      def auth_generate_api_secret() do
        Logger.debug("Calling stored procedure", procedure: "generate_api_secret")

        query(
          "select * from auth.generate_api_secret()",
          []
        )
        |> KeenAuthPermissions.Database.Parsers.AuthGenerateApiSecretParser.parse_auth_generate_api_secret_result()
      end

      @spec auth_generate_api_secret_hash(binary()) :: {:error, any()} | {:ok, [any()]}
      def auth_generate_api_secret_hash(secret) do
        Logger.debug("Calling stored procedure", procedure: "generate_api_secret_hash")

        query(
          "select * from auth.generate_api_secret_hash($1)",
          [secret]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthGenerateApiSecretHashParser.parse_auth_generate_api_secret_hash_result()
      end

      @spec auth_get_provider_users(binary(), integer(), binary()) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthGetProviderUsersItem.t()]}
      def auth_get_provider_users(requested_by, user_id, provider_code) do
        Logger.debug("Calling stored procedure", procedure: "get_provider_users")

        query(
          "select * from auth.get_provider_users($1, $2, $3)",
          [requested_by, user_id, provider_code]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthGetProviderUsersParser.parse_auth_get_provider_users_result()
      end

      @spec auth_get_tenant_by_id(integer()) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthGetTenantByIdItem.t()]}
      def auth_get_tenant_by_id(tenant_id) do
        Logger.debug("Calling stored procedure", procedure: "get_tenant_by_id")

        query(
          "select * from auth.get_tenant_by_id($1)",
          [tenant_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthGetTenantByIdParser.parse_auth_get_tenant_by_id_result()
      end

      @spec auth_get_tenant_groups(binary(), integer(), integer()) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthGetTenantGroupsItem.t()]}
      def auth_get_tenant_groups(requested_by, user_id, tenant_id) do
        Logger.debug("Calling stored procedure", procedure: "get_tenant_groups")

        query(
          "select * from auth.get_tenant_groups($1, $2, $3)",
          [requested_by, user_id, tenant_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthGetTenantGroupsParser.parse_auth_get_tenant_groups_result()
      end

      @spec auth_get_tenant_members(binary(), integer(), integer()) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthGetTenantMembersItem.t()]}
      def auth_get_tenant_members(requested_by, user_id, tenant_id) do
        Logger.debug("Calling stored procedure", procedure: "get_tenant_members")

        query(
          "select * from auth.get_tenant_members($1, $2, $3)",
          [requested_by, user_id, tenant_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthGetTenantMembersParser.parse_auth_get_tenant_members_result()
      end

      @spec auth_get_tenant_users(binary(), integer(), integer()) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthGetTenantUsersItem.t()]}
      def auth_get_tenant_users(requested_by, user_id, tenant_id) do
        Logger.debug("Calling stored procedure", procedure: "get_tenant_users")

        query(
          "select * from auth.get_tenant_users($1, $2, $3)",
          [requested_by, user_id, tenant_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthGetTenantUsersParser.parse_auth_get_tenant_users_result()
      end

      @spec auth_get_tenants(integer()) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthGetTenantsItem.t()]}
      def auth_get_tenants(user_id) do
        Logger.debug("Calling stored procedure", procedure: "get_tenants")

        query(
          "select * from auth.get_tenants($1)",
          [user_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthGetTenantsParser.parse_auth_get_tenants_result()
      end

      @spec auth_get_user_by_email_for_authentication(integer(), binary()) ::
              {:error, any()}
              | {:ok,
                 [KeenAuthPermissions.Database.Models.AuthGetUserByEmailForAuthenticationItem.t()]}
      def auth_get_user_by_email_for_authentication(user_id, email) do
        Logger.debug("Calling stored procedure", procedure: "get_user_by_email_for_authentication")

        query(
          "select * from auth.get_user_by_email_for_authentication($1, $2)",
          [user_id, email]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthGetUserByEmailForAuthenticationParser.parse_auth_get_user_by_email_for_authentication_result()
      end

      @spec auth_get_user_by_id(integer()) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthGetUserByIdItem.t()]}
      def auth_get_user_by_id(user_id) do
        Logger.debug("Calling stored procedure", procedure: "get_user_by_id")

        query(
          "select * from auth.get_user_by_id($1)",
          [user_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthGetUserByIdParser.parse_auth_get_user_by_id_result()
      end

      @spec auth_get_user_data(integer(), integer()) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthGetUserDataItem.t()]}
      def auth_get_user_data(user_id, target_user_id) do
        Logger.debug("Calling stored procedure", procedure: "get_user_data")

        query(
          "select * from auth.get_user_data($1, $2)",
          [user_id, target_user_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthGetUserDataParser.parse_auth_get_user_data_result()
      end

      @spec auth_get_user_group_by_id(binary(), integer(), integer(), integer()) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthGetUserGroupByIdItem.t()]}
      def auth_get_user_group_by_id(requested_by, user_id, user_group_id, tenant_id) do
        Logger.debug("Calling stored procedure", procedure: "get_user_group_by_id")

        query(
          "select * from auth.get_user_group_by_id($1, $2, $3, $4)",
          [requested_by, user_id, user_group_id, tenant_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthGetUserGroupByIdParser.parse_auth_get_user_group_by_id_result()
      end

      @spec auth_get_user_group_mappings(binary(), integer(), integer(), integer()) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthGetUserGroupMappingsItem.t()]}
      def auth_get_user_group_mappings(requested_by, user_id, user_group_id, tenant_id) do
        Logger.debug("Calling stored procedure", procedure: "get_user_group_mappings")

        query(
          "select * from auth.get_user_group_mappings($1, $2, $3, $4)",
          [requested_by, user_id, user_group_id, tenant_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthGetUserGroupMappingsParser.parse_auth_get_user_group_mappings_result()
      end

      @spec auth_get_user_group_members(binary(), integer(), integer(), integer()) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthGetUserGroupMembersItem.t()]}
      def auth_get_user_group_members(requested_by, user_id, user_group_id, tenant_id) do
        Logger.debug("Calling stored procedure", procedure: "get_user_group_members")

        query(
          "select * from auth.get_user_group_members($1, $2, $3, $4)",
          [requested_by, user_id, user_group_id, tenant_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthGetUserGroupMembersParser.parse_auth_get_user_group_members_result()
      end

      @spec auth_get_user_identity(integer(), integer(), binary()) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthGetUserIdentityItem.t()]}
      def auth_get_user_identity(user_id, target_user_id, provider_code) do
        Logger.debug("Calling stored procedure", procedure: "get_user_identity")

        query(
          "select * from auth.get_user_identity($1, $2, $3)",
          [user_id, target_user_id, provider_code]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthGetUserIdentityParser.parse_auth_get_user_identity_result()
      end

      @spec auth_get_user_identity_by_email(integer(), binary(), binary()) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthGetUserIdentityByEmailItem.t()]}
      def auth_get_user_identity_by_email(user_id, email, provider_code) do
        Logger.debug("Calling stored procedure", procedure: "get_user_identity_by_email")

        query(
          "select * from auth.get_user_identity_by_email($1, $2, $3)",
          [user_id, email, provider_code]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthGetUserIdentityByEmailParser.parse_auth_get_user_identity_by_email_result()
      end

      @spec auth_get_user_random_code() :: {:error, any()} | {:ok, [binary()]}
      def auth_get_user_random_code() do
        Logger.debug("Calling stored procedure", procedure: "get_user_random_code")

        query(
          "select * from auth.get_user_random_code()",
          []
        )
        |> KeenAuthPermissions.Database.Parsers.AuthGetUserRandomCodeParser.parse_auth_get_user_random_code_result()
      end

      @spec auth_has_owner(integer(), integer()) :: {:error, any()} | {:ok, [boolean()]}
      def auth_has_owner(user_group_id, tenant_id) do
        Logger.debug("Calling stored procedure", procedure: "has_owner")

        query(
          "select * from auth.has_owner($1, $2)",
          [user_group_id, tenant_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthHasOwnerParser.parse_auth_has_owner_result()
      end

      @spec auth_has_permission(integer(), binary(), integer(), boolean()) ::
              {:error, any()} | {:ok, [boolean()]}
      def auth_has_permission(target_user_id, perm_code, tenant_id, throw_err) do
        Logger.debug("Calling stored procedure", procedure: "has_permission")

        query(
          "select * from auth.has_permission($1, $2, $3, $4)",
          [target_user_id, perm_code, tenant_id, throw_err]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthHasPermissionParser.parse_auth_has_permission_result()
      end

      @spec auth_has_permissions(integer(), any(), integer(), boolean()) ::
              {:error, any()} | {:ok, [boolean()]}
      def auth_has_permissions(target_user_id, perm_codes, tenant_id, throw_err) do
        Logger.debug("Calling stored procedure", procedure: "has_permissions")

        query(
          "select * from auth.has_permissions($1, $2, $3, $4)",
          [target_user_id, perm_codes, tenant_id, throw_err]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthHasPermissionsParser.parse_auth_has_permissions_result()
      end

      @spec auth_is_group_member(integer(), integer(), integer()) ::
              {:error, any()} | {:ok, [boolean()]}
      def auth_is_group_member(user_id, user_group_id, tenant_id) do
        Logger.debug("Calling stored procedure", procedure: "is_group_member")

        query(
          "select * from auth.is_group_member($1, $2, $3)",
          [user_id, user_group_id, tenant_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthIsGroupMemberParser.parse_auth_is_group_member_result()
      end

      @spec auth_is_owner(integer(), integer(), integer()) :: {:error, any()} | {:ok, [boolean()]}
      def auth_is_owner(user_id, user_group_id, tenant_id) do
        Logger.debug("Calling stored procedure", procedure: "is_owner")

        query(
          "select * from auth.is_owner($1, $2, $3)",
          [user_id, user_group_id, tenant_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthIsOwnerParser.parse_auth_is_owner_result()
      end

      @spec auth_lock_user(binary(), integer(), integer()) ::
              {:error, any()} | {:ok, [KeenAuthPermissions.Database.Models.AuthLockUserItem.t()]}
      def auth_lock_user(modified_by, user_id, target_user_id) do
        Logger.debug("Calling stored procedure", procedure: "lock_user")

        query(
          "select * from auth.lock_user($1, $2, $3)",
          [modified_by, user_id, target_user_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthLockUserParser.parse_auth_lock_user_result()
      end

      @spec auth_lock_user_group(binary(), integer(), integer(), integer()) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthLockUserGroupItem.t()]}
      def auth_lock_user_group(modified_by, user_id, user_group_id, tenant_id) do
        Logger.debug("Calling stored procedure", procedure: "lock_user_group")

        query(
          "select * from auth.lock_user_group($1, $2, $3, $4)",
          [modified_by, user_id, user_group_id, tenant_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthLockUserGroupParser.parse_auth_lock_user_group_result()
      end

      @spec auth_register_user(binary(), integer(), binary(), binary(), binary(), any()) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthRegisterUserItem.t()]}
      def auth_register_user(created_by, user_id, email, password_hash, display_name, user_data) do
        Logger.debug("Calling stored procedure", procedure: "register_user")

        query(
          "select * from auth.register_user($1, $2, $3, $4, $5, $6)",
          [created_by, user_id, email, password_hash, display_name, user_data]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthRegisterUserParser.parse_auth_register_user_result()
      end

      @spec auth_set_permission_as_assignable(binary(), integer(), integer(), binary(), boolean()) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthSetPermissionAsAssignableItem.t()]}
      def auth_set_permission_as_assignable(
            modified_by,
            user_id,
            permission_id,
            permission_full_code,
            is_assignable
          ) do
        Logger.debug("Calling stored procedure", procedure: "set_permission_as_assignable")

        query(
          "select * from auth.set_permission_as_assignable($1, $2, $3, $4, $5)",
          [modified_by, user_id, permission_id, permission_full_code, is_assignable]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthSetPermissionAsAssignableParser.parse_auth_set_permission_as_assignable_result()
      end

      @spec auth_set_token_as_used(
              binary(),
              integer(),
              binary(),
              binary(),
              binary(),
              binary(),
              binary(),
              binary()
            ) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthSetTokenAsUsedItem.t()]}
      def auth_set_token_as_used(
            modified_by,
            user_id,
            token_uid,
            token,
            token_type_code,
            ip_address,
            user_agent,
            origin
          ) do
        Logger.debug("Calling stored procedure", procedure: "set_token_as_used")

        query(
          "select * from auth.set_token_as_used($1, $2, $3, $4, $5, $6, $7, $8)",
          [
            modified_by,
            user_id,
            token_uid,
            token,
            token_type_code,
            ip_address,
            user_agent,
            origin
          ]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthSetTokenAsUsedParser.parse_auth_set_token_as_used_result()
      end

      @spec auth_set_token_as_used_by_token(
              binary(),
              integer(),
              binary(),
              binary(),
              binary(),
              binary(),
              binary()
            ) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthSetTokenAsUsedByTokenItem.t()]}
      def auth_set_token_as_used_by_token(
            modified_by,
            user_id,
            token,
            token_type,
            ip_address,
            user_agent,
            origin
          ) do
        Logger.debug("Calling stored procedure", procedure: "set_token_as_used_by_token")

        query(
          "select * from auth.set_token_as_used_by_token($1, $2, $3, $4, $5, $6, $7)",
          [modified_by, user_id, token, token_type, ip_address, user_agent, origin]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthSetTokenAsUsedByTokenParser.parse_auth_set_token_as_used_by_token_result()
      end

      @spec auth_set_user_group_as_external(binary(), integer(), integer(), integer()) ::
              {:error, any()} | {:ok, [any()]}
      def auth_set_user_group_as_external(modified_by, user_id, user_group_id, tenant_id) do
        Logger.debug("Calling stored procedure", procedure: "set_user_group_as_external")

        query(
          "select * from auth.set_user_group_as_external($1, $2, $3, $4)",
          [modified_by, user_id, user_group_id, tenant_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthSetUserGroupAsExternalParser.parse_auth_set_user_group_as_external_result()
      end

      @spec auth_set_user_group_as_hybrid(binary(), integer(), integer(), integer()) ::
              {:error, any()} | {:ok, [any()]}
      def auth_set_user_group_as_hybrid(modified_by, user_id, user_group_id, tenant_id) do
        Logger.debug("Calling stored procedure", procedure: "set_user_group_as_hybrid")

        query(
          "select * from auth.set_user_group_as_hybrid($1, $2, $3, $4)",
          [modified_by, user_id, user_group_id, tenant_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthSetUserGroupAsHybridParser.parse_auth_set_user_group_as_hybrid_result()
      end

      @spec auth_throw_no_access(binary(), integer()) :: {:error, any()} | {:ok, [any()]}
      def auth_throw_no_access(username, tenant_id) do
        Logger.debug("Calling stored procedure", procedure: "throw_no_access")

        query(
          "select * from auth.throw_no_access($1, $2)",
          [username, tenant_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthThrowNoAccessParser.parse_auth_throw_no_access_result()
      end

      @spec auth_throw_no_permission(integer(), any()) :: {:error, any()} | {:ok, [any()]}
      def auth_throw_no_permission(user_id, perm_codes) do
        Logger.debug("Calling stored procedure", procedure: "throw_no_permission")

        query(
          "select * from auth.throw_no_permission($1, $2)",
          [user_id, perm_codes]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthThrowNoPermissionParser.parse_auth_throw_no_permission_result()
      end

      @spec auth_throw_no_permission_1(integer(), any(), integer()) ::
              {:error, any()} | {:ok, [any()]}
      def auth_throw_no_permission_1(user_id, perm_codes, tenant_id) do
        Logger.debug("Calling stored procedure", procedure: "throw_no_permission")

        query(
          "select * from auth.throw_no_permission($1, $2, $3)",
          [user_id, perm_codes, tenant_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthThrowNoPermission1Parser.parse_auth_throw_no_permission_1_result()
      end

      @spec auth_throw_no_permission_2(integer(), binary()) :: {:error, any()} | {:ok, [any()]}
      def auth_throw_no_permission_2(user_id, perm_code) do
        Logger.debug("Calling stored procedure", procedure: "throw_no_permission")

        query(
          "select * from auth.throw_no_permission($1, $2)",
          [user_id, perm_code]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthThrowNoPermission2Parser.parse_auth_throw_no_permission_2_result()
      end

      @spec auth_throw_no_permission_3(integer(), binary(), integer()) ::
              {:error, any()} | {:ok, [any()]}
      def auth_throw_no_permission_3(user_id, perm_code, tenant_id) do
        Logger.debug("Calling stored procedure", procedure: "throw_no_permission")

        query(
          "select * from auth.throw_no_permission($1, $2, $3)",
          [user_id, perm_code, tenant_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthThrowNoPermission3Parser.parse_auth_throw_no_permission_3_result()
      end

      @spec auth_unassign_api_key_permissions(
              binary(),
              integer(),
              integer(),
              binary(),
              any(),
              integer()
            ) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthUnassignApiKeyPermissionsItem.t()]}
      def auth_unassign_api_key_permissions(
            created_by,
            user_id,
            api_key_id,
            perm_set_code,
            permission_codes,
            tenant_id
          ) do
        Logger.debug("Calling stored procedure", procedure: "unassign_api_key_permissions")

        query(
          "select * from auth.unassign_api_key_permissions($1, $2, $3, $4, $5, $6)",
          [created_by, user_id, api_key_id, perm_set_code, permission_codes, tenant_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthUnassignApiKeyPermissionsParser.parse_auth_unassign_api_key_permissions_result()
      end

      @spec auth_unassign_permission(binary(), integer(), integer(), integer()) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthUnassignPermissionItem.t()]}
      def auth_unassign_permission(deleted_by, user_id, assignment_id, tenant_id) do
        Logger.debug("Calling stored procedure", procedure: "unassign_permission")

        query(
          "select * from auth.unassign_permission($1, $2, $3, $4)",
          [deleted_by, user_id, assignment_id, tenant_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthUnassignPermissionParser.parse_auth_unassign_permission_result()
      end

      @spec auth_unlock_user(binary(), integer(), integer()) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthUnlockUserItem.t()]}
      def auth_unlock_user(modified_by, user_id, target_user_id) do
        Logger.debug("Calling stored procedure", procedure: "unlock_user")

        query(
          "select * from auth.unlock_user($1, $2, $3)",
          [modified_by, user_id, target_user_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthUnlockUserParser.parse_auth_unlock_user_result()
      end

      @spec auth_unlock_user_group(binary(), integer(), integer(), integer()) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthUnlockUserGroupItem.t()]}
      def auth_unlock_user_group(modified_by, user_id, user_group_id, tenant_id) do
        Logger.debug("Calling stored procedure", procedure: "unlock_user_group")

        query(
          "select * from auth.unlock_user_group($1, $2, $3, $4)",
          [modified_by, user_id, user_group_id, tenant_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthUnlockUserGroupParser.parse_auth_unlock_user_group_result()
      end

      @spec auth_update_api_key(binary(), integer(), integer(), binary(), binary()) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthUpdateApiKeyItem.t()]}
      def auth_update_api_key(updated_by, user_id, api_key_id, title, description) do
        Logger.debug("Calling stored procedure", procedure: "update_api_key")

        query(
          "select * from auth.update_api_key($1, $2, $3, $4, $5)",
          [updated_by, user_id, api_key_id, title, description]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthUpdateApiKeyParser.parse_auth_update_api_key_result()
      end

      @spec auth_update_api_key_secret(binary(), integer(), integer(), binary()) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthUpdateApiKeySecretItem.t()]}
      def auth_update_api_key_secret(updated_by, user_id, api_key_id, api_secret) do
        Logger.debug("Calling stored procedure", procedure: "update_api_key_secret")

        query(
          "select * from auth.update_api_key_secret($1, $2, $3, $4)",
          [updated_by, user_id, api_key_id, api_secret]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthUpdateApiKeySecretParser.parse_auth_update_api_key_secret_result()
      end

      @spec auth_update_perm_set(binary(), binary(), integer(), binary(), boolean(), integer()) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthUpdatePermSetItem.t()]}
      def auth_update_perm_set(modified_by, user_id, perm_set_id, title, is_assignable, tenant_id) do
        Logger.debug("Calling stored procedure", procedure: "update_perm_set")

        query(
          "select * from auth.update_perm_set($1, $2, $3, $4, $5, $6)",
          [modified_by, user_id, perm_set_id, title, is_assignable, tenant_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthUpdatePermSetParser.parse_auth_update_perm_set_result()
      end

      @spec auth_update_permission_data_v1() :: {:error, any()} | {:ok, [integer()]}
      def auth_update_permission_data_v1() do
        Logger.debug("Calling stored procedure", procedure: "update_permission_data_v1")

        query(
          "select * from auth.update_permission_data_v1()",
          []
        )
        |> KeenAuthPermissions.Database.Parsers.AuthUpdatePermissionDataV1Parser.parse_auth_update_permission_data_v1_result()
      end

      @spec auth_update_provider(binary(), integer(), integer(), binary(), binary(), boolean()) ::
              {:error, any()} | {:ok, [integer()]}
      def auth_update_provider(
            modified_by,
            user_id,
            provider_id,
            provider_code,
            provider_name,
            is_active
          ) do
        Logger.debug("Calling stored procedure", procedure: "update_provider")

        query(
          "select * from auth.update_provider($1, $2, $3, $4, $5, $6)",
          [modified_by, user_id, provider_id, provider_code, provider_name, is_active]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthUpdateProviderParser.parse_auth_update_provider_result()
      end

      @spec auth_update_user_data(binary(), integer(), integer(), binary(), any()) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthUpdateUserDataItem.t()]}
      def auth_update_user_data(modified_by, user_id, target_user_id, provider, user_data) do
        Logger.debug("Calling stored procedure", procedure: "update_user_data")

        query(
          "select * from auth.update_user_data($1, $2, $3, $4, $5)",
          [modified_by, user_id, target_user_id, provider, user_data]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthUpdateUserDataParser.parse_auth_update_user_data_result()
      end

      @spec auth_update_user_group(
              binary(),
              integer(),
              integer(),
              binary(),
              boolean(),
              boolean(),
              boolean(),
              boolean(),
              integer()
            ) :: {:error, any()} | {:ok, [integer()]}
      def auth_update_user_group(
            modified_by,
            user_id,
            user_group_id,
            title,
            is_assignable,
            is_active,
            is_external,
            is_default,
            tenant_id
          ) do
        Logger.debug("Calling stored procedure", procedure: "update_user_group")

        query(
          "select * from auth.update_user_group($1, $2, $3, $4, $5, $6, $7, $8, $9)",
          [
            modified_by,
            user_id,
            user_group_id,
            title,
            is_assignable,
            is_active,
            is_external,
            is_default,
            tenant_id
          ]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthUpdateUserGroupParser.parse_auth_update_user_group_result()
      end

      @spec auth_update_user_password(
              binary(),
              integer(),
              integer(),
              binary(),
              binary(),
              binary(),
              binary(),
              binary()
            ) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthUpdateUserPasswordItem.t()]}
      def auth_update_user_password(
            modified_by,
            user_id,
            target_user_id,
            password_hash,
            ip_address,
            user_agent,
            origin,
            password_salt
          ) do
        Logger.debug("Calling stored procedure", procedure: "update_user_password")

        query(
          "select * from auth.update_user_password($1, $2, $3, $4, $5, $6, $7, $8)",
          [
            modified_by,
            user_id,
            target_user_id,
            password_hash,
            ip_address,
            user_agent,
            origin,
            password_salt
          ]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthUpdateUserPasswordParser.parse_auth_update_user_password_result()
      end

      @spec auth_validate_api_key(binary(), integer(), binary(), binary(), integer()) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthValidateApiKeyItem.t()]}
      def auth_validate_api_key(requested_by, user_id, api_key, api_secret, tenant_id) do
        Logger.debug("Calling stored procedure", procedure: "validate_api_key")

        query(
          "select * from auth.validate_api_key($1, $2, $3, $4, $5)",
          [requested_by, user_id, api_key, api_secret, tenant_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthValidateApiKeyParser.parse_auth_validate_api_key_result()
      end

      @spec auth_validate_provider_is_active(binary()) :: {:error, any()} | {:ok, [any()]}
      def auth_validate_provider_is_active(provider_code) do
        Logger.debug("Calling stored procedure", procedure: "validate_provider_is_active")

        query(
          "select * from auth.validate_provider_is_active($1)",
          [provider_code]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthValidateProviderIsActiveParser.parse_auth_validate_provider_is_active_result()
      end

      @spec auth_validate_token(
              binary(),
              integer(),
              integer(),
              binary(),
              binary(),
              binary(),
              binary(),
              binary(),
              binary(),
              boolean()
            ) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthValidateTokenItem.t()]}
      def auth_validate_token(
            modified_by,
            user_id,
            target_user_id,
            token_uid,
            token,
            token_type,
            ip_address,
            user_agent,
            origin,
            set_as_used
          ) do
        Logger.debug("Calling stored procedure", procedure: "validate_token")

        query(
          "select * from auth.validate_token($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)",
          [
            modified_by,
            user_id,
            target_user_id,
            token_uid,
            token,
            token_type,
            ip_address,
            user_agent,
            origin,
            set_as_used
          ]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthValidateTokenParser.parse_auth_validate_token_result()
      end
    end
  end
end