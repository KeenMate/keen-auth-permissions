# This code has been auto-generated
# Changes to this file will be lost on next generation

defmodule KeenAuthPermissions.Database do
  defmacro __using__(opts) do
    quote do
      require Logger

      import unquote(opts[:repo]), only: [query: 2]

      @spec auth_assign_permission(
              binary(),
              integer(),
              integer(),
              integer(),
              integer(),
              binary(),
              binary()
            ) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthAssignPermissionItem.t()]}
      def auth_assign_permission(
            created_by,
            user_id,
            tenant_id,
            user_group_id,
            target_user_id,
            perm_set_code,
            perm_code
          ) do
        Logger.debug("Calling stored procedure", procedure: "assign_permission")

        query(
          "select * from auth.assign_permission($1, $2, $3, $4, $5, $6, $7)",
          [
            created_by,
            user_id,
            tenant_id,
            user_group_id,
            target_user_id,
            perm_set_code,
            perm_code
          ]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthAssignPermissionParser.parse_auth_assign_permission_result()
      end

      @spec auth_create_auth_event(
              binary(),
              integer(),
              binary(),
              integer(),
              binary(),
              binary(),
              binary()
            ) :: {:error, any()} | {:ok, [integer()]}
      def auth_create_auth_event(
            created_by,
            user_id,
            event_type_code,
            target_user_id,
            ip_address,
            user_agent,
            origin
          ) do
        Logger.debug("Calling stored procedure", procedure: "create_auth_event")

        query(
          "select * from auth.create_auth_event($1, $2, $3, $4, $5, $6, $7)",
          [created_by, user_id, event_type_code, target_user_id, ip_address, user_agent, origin]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthCreateAuthEventParser.parse_auth_create_auth_event_result()
      end

      @spec auth_create_external_user_group(
              binary(),
              integer(),
              binary(),
              integer(),
              binary(),
              boolean(),
              boolean(),
              binary(),
              binary(),
              binary()
            ) :: {:error, any()} | {:ok, [integer()]}
      def auth_create_external_user_group(
            created_by,
            user_id,
            title,
            tenant_id,
            provider,
            is_assignable,
            is_active,
            mapped_object_id,
            mapped_object_name,
            mapped_role
          ) do
        Logger.debug("Calling stored procedure", procedure: "create_external_user_group")

        query(
          "select * from auth.create_external_user_group($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)",
          [
            created_by,
            user_id,
            title,
            tenant_id,
            provider,
            is_assignable,
            is_active,
            mapped_object_id,
            mapped_object_name,
            mapped_role
          ]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthCreateExternalUserGroupParser.parse_auth_create_external_user_group_result()
      end

      @spec auth_create_perm_set(
              binary(),
              binary(),
              binary(),
              integer(),
              boolean(),
              boolean(),
              any()
            ) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthCreatePermSetItem.t()]}
      def auth_create_perm_set(
            created_by,
            user_id,
            title,
            tenant_id,
            is_system,
            is_assignable,
            permissions
          ) do
        Logger.debug("Calling stored procedure", procedure: "create_perm_set")

        query(
          "select * from auth.create_perm_set($1, $2, $3, $4, $5, $6, $7)",
          [created_by, user_id, title, tenant_id, is_system, is_assignable, permissions]
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

      @spec auth_create_token(
              binary(),
              integer(),
              integer(),
              integer(),
              binary(),
              binary(),
              binary(),
              DateTime.t()
            ) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthCreateTokenItem.t()]}
      def auth_create_token(
            created_by,
            user_id,
            target_user_id,
            auth_event_id,
            token_type_code,
            token_channel_code,
            token,
            expires_at
          ) do
        Logger.debug("Calling stored procedure", procedure: "create_token")

        query(
          "select * from auth.create_token($1, $2, $3, $4, $5, $6, $7, $8)",
          [
            created_by,
            user_id,
            target_user_id,
            auth_event_id,
            token_type_code,
            token_channel_code,
            token,
            expires_at
          ]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthCreateTokenParser.parse_auth_create_token_result()
      end

      @spec auth_create_user_group(
              binary(),
              integer(),
              binary(),
              integer(),
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
            is_external
          ) do
        Logger.debug("Calling stored procedure", procedure: "create_user_group")

        query(
          "select * from auth.create_user_group($1, $2, $3, $4, $5, $6, $7)",
          [created_by, user_id, title, tenant_id, is_assignable, is_active, is_external]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthCreateUserGroupParser.parse_auth_create_user_group_result()
      end

      @spec auth_create_user_group_mapping(
              binary(),
              integer(),
              integer(),
              integer(),
              binary(),
              binary(),
              binary(),
              binary()
            ) :: {:error, any()} | {:ok, [integer()]}
      def auth_create_user_group_mapping(
            created_by,
            user_id,
            tenant_id,
            user_group_id,
            provider_code,
            mapped_object_id,
            mapped_object_name,
            mapped_role
          ) do
        Logger.debug("Calling stored procedure", procedure: "create_user_group_mapping")

        query(
          "select * from auth.create_user_group_mapping($1, $2, $3, $4, $5, $6, $7, $8)",
          [
            created_by,
            user_id,
            tenant_id,
            user_group_id,
            provider_code,
            mapped_object_id,
            mapped_object_name,
            mapped_role
          ]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthCreateUserGroupMappingParser.parse_auth_create_user_group_mapping_result()
      end

      @spec auth_create_user_group_member(binary(), integer(), integer(), integer(), integer()) ::
              {:error, any()} | {:ok, [integer()]}
      def auth_create_user_group_member(
            created_by,
            user_id,
            tenant_id,
            user_group_id,
            target_user_id
          ) do
        Logger.debug("Calling stored procedure", procedure: "create_user_group_member")

        query(
          "select * from auth.create_user_group_member($1, $2, $3, $4, $5)",
          [created_by, user_id, tenant_id, user_group_id, target_user_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthCreateUserGroupMemberParser.parse_auth_create_user_group_member_result()
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
      def auth_delete_user_group(deleted_by, user_id, tenant_id, user_group_id) do
        Logger.debug("Calling stored procedure", procedure: "delete_user_group")

        query(
          "select * from auth.delete_user_group($1, $2, $3, $4)",
          [deleted_by, user_id, tenant_id, user_group_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthDeleteUserGroupParser.parse_auth_delete_user_group_result()
      end

      @spec auth_delete_user_group_mapping(binary(), integer(), integer(), integer()) ::
              {:error, any()} | {:ok, [any()]}
      def auth_delete_user_group_mapping(deleted_by, user_id, tenant_id, ug_mapping_id) do
        Logger.debug("Calling stored procedure", procedure: "delete_user_group_mapping")

        query(
          "select * from auth.delete_user_group_mapping($1, $2, $3, $4)",
          [deleted_by, user_id, tenant_id, ug_mapping_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthDeleteUserGroupMappingParser.parse_auth_delete_user_group_mapping_result()
      end

      @spec auth_delete_user_group_member(binary(), integer(), integer(), integer(), integer()) ::
              {:error, any()} | {:ok, [any()]}
      def auth_delete_user_group_member(deleted_by, user_id, tenant_id, ug_id, user_member_id) do
        Logger.debug("Calling stored procedure", procedure: "delete_user_group_member")

        query(
          "select * from auth.delete_user_group_member($1, $2, $3, $4, $5)",
          [deleted_by, user_id, tenant_id, ug_id, user_member_id]
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
      def auth_disable_user_group(modified_by, user_id, tenant_id, user_group_id) do
        Logger.debug("Calling stored procedure", procedure: "disable_user_group")

        query(
          "select * from auth.disable_user_group($1, $2, $3, $4)",
          [modified_by, user_id, tenant_id, user_group_id]
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
      def auth_enable_user_group(modified_by, user_id, tenant_id, user_group_id) do
        Logger.debug("Calling stored procedure", procedure: "enable_user_group")

        query(
          "select * from auth.enable_user_group($1, $2, $3, $4)",
          [modified_by, user_id, tenant_id, user_group_id]
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
              integer(),
              binary(),
              any(),
              any()
            ) ::
              {:error, any()}
              | {:ok,
                 [KeenAuthPermissions.Database.Models.AuthEnsureGroupsAndPermissionsItem.t()]}
      def auth_ensure_groups_and_permissions(
            created_by,
            user_id,
            target_user_id,
            tenant_id,
            provider_code,
            provider_groups,
            provider_roles
          ) do
        Logger.debug("Calling stored procedure", procedure: "ensure_groups_and_permissions")

        query(
          "select * from auth.ensure_groups_and_permissions($1, $2, $3, $4, $5, $6, $7)",
          [
            created_by,
            user_id,
            target_user_id,
            tenant_id,
            provider_code,
            provider_groups,
            provider_roles
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
              binary()
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

      @spec auth_get_user_random_code() :: {:error, any()} | {:ok, [binary()]}
      def auth_get_user_random_code() do
        Logger.debug("Calling stored procedure", procedure: "get_user_random_code")

        query(
          "select * from auth.get_user_random_code()",
          []
        )
        |> KeenAuthPermissions.Database.Parsers.AuthGetUserRandomCodeParser.parse_auth_get_user_random_code_result()
      end

      @spec auth_get_users_by_provider(binary(), integer(), binary()) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthGetUsersByProviderItem.t()]}
      def auth_get_users_by_provider(requested_user, user_id, provider_code) do
        Logger.debug("Calling stored procedure", procedure: "get_users_by_provider")

        query(
          "select * from auth.get_users_by_provider($1, $2, $3)",
          [requested_user, user_id, provider_code]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthGetUsersByProviderParser.parse_auth_get_users_by_provider_result()
      end

      @spec auth_has_permission(integer(), integer(), binary(), boolean()) ::
              {:error, any()} | {:ok, [boolean()]}
      def auth_has_permission(tenant_id, target_user_id, perm_code, throw_err) do
        Logger.debug("Calling stored procedure", procedure: "has_permission")

        query(
          "select * from auth.has_permission($1, $2, $3, $4)",
          [tenant_id, target_user_id, perm_code, throw_err]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthHasPermissionParser.parse_auth_has_permission_result()
      end

      @spec auth_has_permissions(integer(), integer(), any(), boolean()) ::
              {:error, any()} | {:ok, [boolean()]}
      def auth_has_permissions(tenant_id, target_user_id, perm_codes, throw_err) do
        Logger.debug("Calling stored procedure", procedure: "has_permissions")

        query(
          "select * from auth.has_permissions($1, $2, $3, $4)",
          [tenant_id, target_user_id, perm_codes, throw_err]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthHasPermissionsParser.parse_auth_has_permissions_result()
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
      def auth_lock_user_group(modified_by, user_id, tenant_id, user_group_id) do
        Logger.debug("Calling stored procedure", procedure: "lock_user_group")

        query(
          "select * from auth.lock_user_group($1, $2, $3, $4)",
          [modified_by, user_id, tenant_id, user_group_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthLockUserGroupParser.parse_auth_lock_user_group_result()
      end

      @spec auth_register_user(binary(), integer(), binary(), binary(), binary(), binary()) ::
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

      @spec auth_set_user_group_as_external(binary(), integer(), integer(), integer()) ::
              {:error, any()} | {:ok, [any()]}
      def auth_set_user_group_as_external(modified_by, user_id, tenant_id, user_group_id) do
        Logger.debug("Calling stored procedure", procedure: "set_user_group_as_external")

        query(
          "select * from auth.set_user_group_as_external($1, $2, $3, $4)",
          [modified_by, user_id, tenant_id, user_group_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthSetUserGroupAsExternalParser.parse_auth_set_user_group_as_external_result()
      end

      @spec auth_set_user_group_as_hybrid(binary(), integer(), integer(), integer()) ::
              {:error, any()} | {:ok, [any()]}
      def auth_set_user_group_as_hybrid(modified_by, user_id, tenant_id, user_group_id) do
        Logger.debug("Calling stored procedure", procedure: "set_user_group_as_hybrid")

        query(
          "select * from auth.set_user_group_as_hybrid($1, $2, $3, $4)",
          [modified_by, user_id, tenant_id, user_group_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthSetUserGroupAsHybridParser.parse_auth_set_user_group_as_hybrid_result()
      end

      @spec auth_throw_no_access(integer(), binary()) :: {:error, any()} | {:ok, [any()]}
      def auth_throw_no_access(tenant_id, username) do
        Logger.debug("Calling stored procedure", procedure: "throw_no_access")

        query(
          "select * from auth.throw_no_access($1, $2)",
          [tenant_id, username]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthThrowNoAccessParser.parse_auth_throw_no_access_result()
      end

      @spec auth_throw_no_permission(integer(), integer(), binary()) ::
              {:error, any()} | {:ok, [any()]}
      def auth_throw_no_permission(tenant_id, user_id, perm_code) do
        Logger.debug("Calling stored procedure", procedure: "throw_no_permission")

        query(
          "select * from auth.throw_no_permission($1, $2, $3)",
          [tenant_id, user_id, perm_code]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthThrowNoPermissionParser.parse_auth_throw_no_permission_result()
      end

      @spec auth_throw_no_permission_1(integer(), integer(), any()) ::
              {:error, any()} | {:ok, [any()]}
      def auth_throw_no_permission_1(tenant_id, user_id, perm_codes) do
        Logger.debug("Calling stored procedure", procedure: "throw_no_permission")

        query(
          "select * from auth.throw_no_permission($1, $2, $3)",
          [tenant_id, user_id, perm_codes]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthThrowNoPermission1Parser.parse_auth_throw_no_permission_1_result()
      end

      @spec auth_unassign_permission(binary(), integer(), integer(), integer()) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthUnassignPermissionItem.t()]}
      def auth_unassign_permission(deleted_by, user_id, tenant_id, assignment_id) do
        Logger.debug("Calling stored procedure", procedure: "unassign_permission")

        query(
          "select * from auth.unassign_permission($1, $2, $3, $4)",
          [deleted_by, user_id, tenant_id, assignment_id]
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
      def auth_unlock_user_group(modified_by, user_id, tenant_id, user_group_id) do
        Logger.debug("Calling stored procedure", procedure: "unlock_user_group")

        query(
          "select * from auth.unlock_user_group($1, $2, $3, $4)",
          [modified_by, user_id, tenant_id, user_group_id]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthUnlockUserGroupParser.parse_auth_unlock_user_group_result()
      end

      @spec auth_update_perm_set(binary(), binary(), integer(), integer(), binary(), boolean()) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthUpdatePermSetItem.t()]}
      def auth_update_perm_set(modified_by, user_id, tenant_id, perm_set_id, title, is_assignable) do
        Logger.debug("Calling stored procedure", procedure: "update_perm_set")

        query(
          "select * from auth.update_perm_set($1, $2, $3, $4, $5, $6)",
          [modified_by, user_id, tenant_id, perm_set_id, title, is_assignable]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthUpdatePermSetParser.parse_auth_update_perm_set_result()
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

      @spec auth_update_user_data(binary(), integer(), integer(), binary(), binary()) ::
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
              integer(),
              binary(),
              boolean(),
              boolean()
            ) :: {:error, any()} | {:ok, [integer()]}
      def auth_update_user_group(
            modified_by,
            user_id,
            tenant_id,
            ug_id,
            title,
            is_assignable,
            is_active
          ) do
        Logger.debug("Calling stored procedure", procedure: "update_user_group")

        query(
          "select * from auth.update_user_group($1, $2, $3, $4, $5, $6, $7)",
          [modified_by, user_id, tenant_id, ug_id, title, is_assignable, is_active]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthUpdateUserGroupParser.parse_auth_update_user_group_result()
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
              binary()
            ) ::
              {:error, any()}
              | {:ok, [KeenAuthPermissions.Database.Models.AuthValidateTokenItem.t()]}
      def auth_validate_token(
            modified_by,
            user_id,
            target_user_id,
            token,
            ip_address,
            user_agent,
            origin
          ) do
        Logger.debug("Calling stored procedure", procedure: "validate_token")

        query(
          "select * from auth.validate_token($1, $2, $3, $4, $5, $6, $7)",
          [modified_by, user_id, target_user_id, token, ip_address, user_agent, origin]
        )
        |> KeenAuthPermissions.Database.Parsers.AuthValidateTokenParser.parse_auth_validate_token_result()
      end
    end
  end
end