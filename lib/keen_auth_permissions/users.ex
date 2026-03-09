# This module provides a clean API for user operations.
# It wraps the auto-generated database context functions with a cleaner interface.

defmodule KeenAuthPermissions.Users do
  @moduledoc """
  Clean facade API for user management operations.

  All functions take a `%RequestContext{}` struct as the first parameter for authentication context,
  and return single items instead of lists where appropriate.

  ## Examples

      # List all users in a tenant
      KeenAuthPermissions.Users.list(request_context, tenant_id)

      # Get a user by ID
      KeenAuthPermissions.Users.get_by_id(user_id)

      # Search users
      KeenAuthPermissions.Users.search(request_context, "john", nil, nil, nil, 1, 20, tenant_id)
  """

  alias KeenAuthPermissions.User
  alias KeenAuthPermissions.RequestContext
  alias KeenAuthPermissions.Notifier
  alias KeenAuthPermissions.Error.{ErrorParsers, ErrorStruct}

  defp db_context(), do: KeenAuthPermissions.DbContext.get_global_db_context()

  # ============================================================================
  # User Query Operations
  # ============================================================================

  @doc """
  Lists all users in a tenant.

  Calls `auth.get_tenant_users`.
  """
  @spec list(RequestContext.t(), integer()) :: {:ok, list()} | {:error, any()}
  def list(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        tenant_id,
        target_tenant_id \\ nil
      ) do
    db_context().auth_get_tenant_users(
      username,
      user_id,
      request_id,
      tenant_id,
      target_tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Gets a user by ID.

  Calls `auth.get_user_by_id`.
  Returns a single user or error.
  """
  @spec get_by_id(integer()) :: {:ok, map()} | {:error, any()}
  def get_by_id(user_id) do
    case db_context().auth_get_user_by_id(user_id, nil) do
      {:ok, [user | _]} -> {:ok, user}
      {:ok, []} -> {:error, ErrorStruct.create(:user_not_found, "User not found")}
      {:error, error} -> {:error, ErrorParsers.parse_error(error)}
    end
  end

  @doc """
  Gets a user by provider OID.

  Calls `auth.get_user_by_provider_oid`.
  Returns a single user or error.
  """
  @spec get_by_provider_oid(integer(), String.t()) :: {:ok, map()} | {:error, any()}
  def get_by_provider_oid(user_id, provider_oid) do
    case db_context().auth_get_user_by_provider_oid(user_id, nil, provider_oid) do
      {:ok, [user | _]} -> {:ok, user}
      {:ok, []} -> {:error, ErrorStruct.create(:user_not_found, "User not found")}
      {:error, error} -> {:error, ErrorParsers.parse_error(error)}
    end
  end

  @doc """
  Gets a user by email for authentication.

  Calls `auth.get_user_by_email_for_authentication`.
  Returns a single user or error.
  """
  @spec get_by_email_for_auth(RequestContext.t(), String.t()) :: {:ok, map()} | {:error, any()}
  def get_by_email_for_auth(
        %RequestContext{user: %User{user_id: user_id}, request_id: request_id} = ctx,
        email,
        tenant_id \\ 1
      ) do
    case db_context().auth_get_user_by_email_for_authentication(
           user_id,
           request_id,
           email,
           RequestContext.to_context_map(ctx),
           tenant_id
         ) do
      {:ok, [user | _]} -> {:ok, user}
      {:ok, []} -> {:error, ErrorStruct.create(:user_not_found, "User not found")}
      {:error, error} -> {:error, ErrorParsers.parse_error(error)}
    end
  end

  @doc """
  Gets user data.

  Calls `auth.get_user_data`.
  Returns a single user data record or error.
  """
  @spec get_data(integer(), integer()) :: {:ok, map()} | {:error, any()}
  def get_data(user_id, target_user_id, tenant_id \\ 1) do
    case db_context().auth_get_user_data(user_id, nil, target_user_id, tenant_id) do
      {:ok, [data | _]} -> {:ok, data}
      {:ok, []} -> {:error, ErrorStruct.create(:user_not_found, "User data not found")}
      {:error, error} -> {:error, ErrorParsers.parse_error(error)}
    end
  end

  @doc """
  Searches users with filters.

  Calls `auth.search_users`.
  """
  @spec search(
          RequestContext.t(),
          String.t() | nil,
          String.t() | nil,
          boolean() | nil,
          boolean() | nil,
          integer(),
          integer(),
          integer()
        ) :: {:ok, list()} | {:error, any()}
  def search(
        %RequestContext{user: %User{user_id: user_id}, request_id: request_id},
        search_text,
        user_type_code,
        is_active,
        is_locked,
        page,
        page_size,
        tenant_id,
        target_tenant_id \\ nil
      ) do
    db_context().auth_search_users(
      user_id,
      request_id,
      search_text,
      user_type_code,
      is_active,
      is_locked,
      page,
      page_size,
      tenant_id,
      target_tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Gets users from a specific provider.

  Calls `auth.get_provider_users`.
  """
  @spec list_by_provider(RequestContext.t(), String.t()) :: {:ok, list()} | {:error, any()}
  def list_by_provider(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        provider_code,
        tenant_id \\ 1
      ) do
    db_context().auth_get_provider_users(
      username,
      user_id,
      request_id,
      provider_code,
      tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  # ============================================================================
  # User State Operations
  # ============================================================================

  @doc """
  Enables a user.

  Calls `auth.enable_user`.
  """
  @spec enable(RequestContext.t(), integer()) :: {:ok, map()} | {:error, any()}
  def enable(
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id} =
          ctx,
        target_user_id,
        tenant_id \\ 1
      ) do
    case db_context().auth_enable_user(
           username,
           user_id,
           request_id,
           target_user_id,
           RequestContext.to_context_map(ctx),
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} ->
        Notifier.user_enabled(target_user_id)
        {:ok, result}

      {:ok, []} ->
        {:error, :enable_failed}

      error ->
        error
    end
  end

  @doc """
  Disables a user.

  Calls `auth.disable_user`.
  """
  @spec disable(RequestContext.t(), integer()) :: {:ok, map()} | {:error, any()}
  def disable(
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id} =
          ctx,
        target_user_id,
        tenant_id \\ 1
      ) do
    case db_context().auth_disable_user(
           username,
           user_id,
           request_id,
           target_user_id,
           RequestContext.to_context_map(ctx),
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} ->
        Notifier.user_disabled(target_user_id)
        {:ok, result}

      {:ok, []} ->
        {:error, :disable_failed}

      error ->
        error
    end
  end

  @doc """
  Locks a user.

  Calls `auth.lock_user`.
  """
  @spec lock(RequestContext.t(), integer()) :: {:ok, map()} | {:error, any()}
  def lock(
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id} =
          ctx,
        target_user_id,
        tenant_id \\ 1
      ) do
    case db_context().auth_lock_user(
           username,
           user_id,
           request_id,
           target_user_id,
           RequestContext.to_context_map(ctx),
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} ->
        Notifier.user_locked(target_user_id)
        {:ok, result}

      {:ok, []} ->
        {:error, :lock_failed}

      error ->
        error
    end
  end

  @doc """
  Unlocks a user.

  Calls `auth.unlock_user`.
  """
  @spec unlock(RequestContext.t(), integer()) :: {:ok, map()} | {:error, any()}
  def unlock(
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id} =
          ctx,
        target_user_id,
        tenant_id \\ 1
      ) do
    case db_context().auth_unlock_user(
           username,
           user_id,
           request_id,
           target_user_id,
           RequestContext.to_context_map(ctx),
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} ->
        Notifier.user_unlocked(target_user_id)
        {:ok, result}

      {:ok, []} ->
        {:error, :unlock_failed}

      error ->
        error
    end
  end

  # ============================================================================
  # User Data Operations
  # ============================================================================

  @doc """
  Updates user data.

  Calls `auth.update_user_data`.
  """
  @spec update_data(RequestContext.t(), integer(), String.t(), map()) ::
          {:ok, map()} | {:error, any()}
  def update_data(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        target_user_id,
        provider,
        user_data
      ) do
    case db_context().auth_update_user_data(
           username,
           user_id,
           request_id,
           target_user_id,
           provider,
           user_data
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :update_failed}
      error -> error
    end
  end

  @doc """
  Updates user password.

  Calls `auth.update_user_password`.
  """
  @spec update_password(RequestContext.t(), integer(), String.t(), String.t() | nil) ::
          {:ok, map()} | {:error, any()}
  def update_password(
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id} =
          ctx,
        target_user_id,
        password_hash,
        password_salt \\ nil,
        tenant_id \\ 1
      ) do
    case db_context().auth_update_user_password(
           username,
           user_id,
           request_id,
           target_user_id,
           password_hash,
           RequestContext.to_context_map(ctx),
           password_salt,
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :update_failed}
      error -> error
    end
  end

  @doc """
  Deletes user info.

  Calls `auth.delete_user_info`.
  """
  @spec delete_info(RequestContext.t(), integer(), integer(), boolean()) ::
          {:ok, map()} | {:error, any()}
  def delete_info(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        target_user_id,
        tenant_id,
        blacklist \\ false
      ) do
    case db_context().auth_delete_user_info(
           username,
           user_id,
           request_id,
           target_user_id,
           tenant_id,
           blacklist
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :delete_failed}
      error -> error
    end
  end

  # ============================================================================
  # User Identity Operations
  # ============================================================================

  @doc """
  Gets a user identity.

  Calls `auth.get_user_identity`.
  Returns a single identity or error.
  """
  @spec get_identity(integer(), integer(), String.t()) :: {:ok, map()} | {:error, any()}
  def get_identity(user_id, target_user_id, provider_code, tenant_id \\ 1) do
    case db_context().auth_get_user_identity(user_id, nil, target_user_id, provider_code, tenant_id) do
      {:ok, [identity | _]} -> {:ok, identity}
      {:ok, []} -> {:error, ErrorStruct.create(:identity_not_found, "Identity not found")}
      {:error, error} -> {:error, ErrorParsers.parse_error(error)}
    end
  end

  @doc """
  Gets a user identity by email.

  Calls `auth.get_user_identity_by_email`.
  Returns a single identity or error.
  """
  @spec get_identity_by_email(integer(), String.t(), String.t()) :: {:ok, map()} | {:error, any()}
  def get_identity_by_email(user_id, email, provider_code, tenant_id \\ 1) do
    case db_context().auth_get_user_identity_by_email(user_id, nil, email, provider_code, tenant_id) do
      {:ok, [identity | _]} -> {:ok, identity}
      {:ok, []} -> {:error, ErrorStruct.create(:identity_not_found, "Identity not found")}
      {:error, error} -> {:error, ErrorParsers.parse_error(error)}
    end
  end

  @doc """
  Enables a user identity.

  Calls `auth.enable_user_identity`.
  """
  @spec enable_identity(RequestContext.t(), integer(), String.t()) ::
          {:ok, map()} | {:error, any()}
  def enable_identity(
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id} =
          ctx,
        target_user_id,
        provider_code,
        tenant_id \\ 1
      ) do
    case db_context().auth_enable_user_identity(
           username,
           user_id,
           request_id,
           target_user_id,
           provider_code,
           RequestContext.to_context_map(ctx),
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :enable_failed}
      error -> error
    end
  end

  @doc """
  Disables a user identity.

  Calls `auth.disable_user_identity`.
  """
  @spec disable_identity(RequestContext.t(), integer(), String.t()) ::
          {:ok, map()} | {:error, any()}
  def disable_identity(
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id} =
          ctx,
        target_user_id,
        provider_code,
        tenant_id \\ 1
      ) do
    case db_context().auth_disable_user_identity(
           username,
           user_id,
           request_id,
           target_user_id,
           provider_code,
           RequestContext.to_context_map(ctx),
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :disable_failed}
      error -> error
    end
  end

  @doc """
  Verifies a user identity.

  Sets `is_verified = true` on the identity and logs an `identity_verified` event.

  Calls `auth.verify_user_identity`.
  """
  @spec verify_identity(RequestContext.t(), integer(), String.t()) :: :ok | {:error, any()}
  def verify_identity(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        } = ctx,
        target_user_id,
        provider_code,
        tenant_id \\ 1
      ) do
    db_context().auth_verify_user_identity(
      username,
      user_id,
      request_id,
      target_user_id,
      provider_code,
      RequestContext.to_context_map(ctx),
      tenant_id
    )
  end

  # ============================================================================
  # User Permission Operations
  # ============================================================================

  @doc """
  Gets a user's permissions.

  Calls `auth.get_user_permissions`.
  """
  @spec list_permissions(integer(), integer(), integer()) :: {:ok, list()} | {:error, any()}
  def list_permissions(user_id, target_user_id, tenant_id) do
    db_context().auth_get_user_permissions(user_id, nil, target_user_id, tenant_id)
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Gets a user's assigned permissions.

  Calls `auth.get_user_assigned_permissions`.
  """
  @spec list_assigned_permissions(RequestContext.t(), integer(), integer()) ::
          {:ok, list()} | {:error, any()}
  def list_assigned_permissions(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        target_user_id,
        tenant_id
      ) do
    db_context().auth_get_user_assigned_permissions(
      username,
      user_id,
      request_id,
      target_user_id,
      tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Gets a user's assigned groups.

  Calls `auth.get_user_assigned_groups`.
  """
  @spec list_assigned_groups(integer(), integer()) :: {:ok, list()} | {:error, any()}
  def list_assigned_groups(user_id, target_user_id, tenant_id \\ 1, target_tenant_id \\ nil) do
    db_context().auth_get_user_assigned_groups(user_id, nil, target_user_id, tenant_id, target_tenant_id)
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Gets a user's groups and permissions.

  Calls `auth.get_users_groups_and_permissions`.
  """
  @spec get_groups_and_permissions(RequestContext.t(), integer()) ::
          {:ok, list()} | {:error, any()}
  def get_groups_and_permissions(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        target_user_id,
        tenant_id \\ 1
      ) do
    db_context().auth_get_users_groups_and_permissions(
      username,
      user_id,
      request_id,
      target_user_id,
      tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Checks if a user has a specific permission.

  Calls `auth.has_permission`.
  """
  @spec has_permission?(integer(), String.t(), integer(), boolean()) ::
          {:ok, boolean()} | {:error, any()}
  def has_permission?(target_user_id, perm_code, tenant_id, throw_err \\ false) do
    case db_context().auth_has_permission(target_user_id, nil, perm_code, tenant_id, throw_err) do
      {:ok, [%{has_permission: result}]} -> {:ok, result}
      {:ok, []} -> {:ok, false}
      error -> error
    end
  end

  @doc """
  Checks if a user has multiple permissions.

  Calls `auth.has_permissions`.
  """
  @spec has_permissions?(integer(), list(String.t()), integer(), boolean()) ::
          {:ok, boolean()} | {:error, any()}
  def has_permissions?(target_user_id, perm_codes, tenant_id, throw_err \\ false) do
    case db_context().auth_has_permissions(target_user_id, nil, perm_codes, tenant_id, throw_err) do
      {:ok, [%{has_permissions: result}]} -> {:ok, result}
      {:ok, []} -> {:ok, false}
      error -> error
    end
  end

  # ============================================================================
  # User Tenant Operations
  # ============================================================================

  @doc """
  Gets available tenants for a user.

  Calls `auth.get_user_available_tenants`.
  """
  @spec list_available_tenants(integer(), integer()) :: {:ok, list()} | {:error, any()}
  def list_available_tenants(user_id, target_user_id, tenant_id \\ 1) do
    db_context().auth_get_user_available_tenants(user_id, nil, target_user_id, tenant_id)
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Gets the user's last selected tenant.

  Calls `auth.get_user_last_selected_tenant`.
  """
  @spec get_last_selected_tenant(integer(), integer()) :: {:ok, map()} | {:error, any()}
  def get_last_selected_tenant(user_id, target_user_id, tenant_id \\ 1) do
    case db_context().auth_get_user_last_selected_tenant(user_id, nil, target_user_id, tenant_id) do
      {:ok, [tenant | _]} -> {:ok, tenant}
      {:ok, []} -> {:error, ErrorStruct.create(:not_found, "No tenant selected")}
      {:error, error} -> {:error, ErrorParsers.parse_error(error)}
    end
  end

  @doc """
  Updates the user's last selected tenant.

  Calls `auth.update_user_last_selected_tenant`.
  """
  @spec update_last_selected_tenant(RequestContext.t(), integer(), String.t()) ::
          {:ok, map()} | {:error, any()}
  def update_last_selected_tenant(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        target_user_id,
        tenant_uuid,
        tenant_id \\ 1
      ) do
    case db_context().auth_update_user_last_selected_tenant(
           username,
           user_id,
           request_id,
           target_user_id,
           tenant_uuid,
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :update_failed}
      error -> error
    end
  end

  # ============================================================================
  # User Preferences Operations
  # ============================================================================

  @doc """
  Gets user preferences.

  Calls `auth.get_user_preferences`.
  """
  @spec get_preferences(integer(), integer()) :: {:ok, map()} | {:error, any()}
  def get_preferences(user_id, target_user_id, tenant_id \\ 1) do
    case db_context().auth_get_user_preferences(user_id, nil, target_user_id, tenant_id) do
      {:ok, [prefs | _]} -> {:ok, prefs}
      {:ok, []} -> {:error, ErrorStruct.create(:not_found, "Preferences not found")}
      {:error, error} -> {:error, ErrorParsers.parse_error(error)}
    end
  end

  @doc """
  Updates user preferences.

  Calls `auth.update_user_preferences`.
  """
  @spec update_preferences(RequestContext.t(), integer(), map()) :: {:ok, map()} | {:error, any()}
  def update_preferences(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        target_user_id,
        update_data,
        tenant_id \\ 1
      ) do
    case db_context().auth_update_user_preferences(
           username,
           user_id,
           request_id,
           target_user_id,
           update_data,
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :update_failed}
      error -> error
    end
  end

  @doc """
  Creates user tenant preferences.

  Calls `auth.create_user_tenant_preferences`.
  """
  @spec create_tenant_preferences(RequestContext.t(), integer(), map(), integer()) ::
          {:ok, map()} | {:error, any()}
  def create_tenant_preferences(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        target_user_id,
        update_data,
        tenant_id
      ) do
    case db_context().auth_create_user_tenant_preferences(
           username,
           user_id,
           request_id,
           target_user_id,
           update_data,
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :creation_failed}
      error -> error
    end
  end

  @doc """
  Updates user tenant preferences.

  Calls `auth.update_user_tenant_preferences`.
  """
  @spec update_tenant_preferences(RequestContext.t(), integer(), map(), boolean(), integer()) ::
          {:ok, map()} | {:error, any()}
  def update_tenant_preferences(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        target_user_id,
        update_data,
        should_overwrite_data,
        tenant_id
      ) do
    case db_context().auth_update_user_tenant_preferences(
           username,
           user_id,
           request_id,
           target_user_id,
           update_data,
           should_overwrite_data,
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :update_failed}
      error -> error
    end
  end

  # ============================================================================
  # User Registration/Ensure Operations
  # ============================================================================

  @doc """
  Registers a new user.

  Calls `auth.register_user`.
  """
  @spec register(RequestContext.t(), String.t(), String.t(), String.t(), map() | nil) ::
          {:ok, map()} | {:error, any()}
  def register(
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id} =
          ctx,
        email,
        password_hash,
        display_name,
        user_data \\ nil,
        tenant_id \\ 1
      ) do
    case db_context().auth_register_user(
           username,
           user_id,
           request_id,
           email,
           password_hash,
           display_name,
           user_data,
           RequestContext.to_context_map(ctx),
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :registration_failed}
      error -> error
    end
  end

  @doc """
  Ensures user info exists.

  Calls `auth.ensure_user_info`.
  """
  @spec ensure_info(
          RequestContext.t(),
          String.t(),
          String.t(),
          String.t(),
          String.t(),
          map() | nil
        ) ::
          {:ok, map()} | {:error, any()}
  def ensure_info(
        %RequestContext{
          user: %User{username: created_by, user_id: user_id},
          request_id: request_id
        },
        username,
        display_name,
        provider_code,
        email,
        user_data \\ nil
      ) do
    case db_context().auth_ensure_user_info(
           created_by,
           user_id,
           request_id,
           username,
           display_name,
           provider_code,
           email,
           user_data
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :ensure_failed}
      error -> error
    end
  end

  @doc """
  Ensures a user from a provider exists.

  Calls `auth.ensure_user_from_provider`.
  """
  @spec ensure_from_provider(
          RequestContext.t(),
          String.t(),
          String.t(),
          String.t(),
          String.t(),
          String.t(),
          String.t(),
          map() | nil
        ) :: {:ok, map()} | {:error, any()}
  def ensure_from_provider(
        %RequestContext{
          user: %User{username: created_by, user_id: user_id},
          request_id: request_id
        } = ctx,
        provider_code,
        provider_uid,
        provider_oid,
        username,
        display_name,
        email,
        user_data \\ nil
      ) do
    case db_context().auth_ensure_user_from_provider(
           created_by,
           user_id,
           request_id,
           provider_code,
           provider_uid,
           provider_oid,
           username,
           display_name,
           email,
           user_data,
           RequestContext.to_context_map(ctx)
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :ensure_failed}
      error -> error
    end
  end

  @doc """
  Creates a service user info.

  Calls `auth.create_service_user_info`.
  """
  @spec create_service_user(RequestContext.t(), String.t(), String.t(), String.t(), integer()) ::
          {:ok, map()} | {:error, any()}
  def create_service_user(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        svc_username,
        email,
        display_name,
        custom_service_user_id,
        tenant_id \\ 1
      ) do
    case db_context().auth_create_service_user_info(
           username,
           user_id,
           request_id,
           svc_username,
           email,
           display_name,
           custom_service_user_id,
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :creation_failed}
      error -> error
    end
  end

  @doc """
  Assigns a user to default groups in a tenant.

  Calls `auth.assign_user_default_groups`.
  """
  @spec assign_default_groups(RequestContext.t(), integer(), integer()) ::
          {:ok, list()} | {:error, any()}
  def assign_default_groups(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        target_user_id,
        tenant_id
      ) do
    db_context().auth_assign_user_default_groups(
      username,
      user_id,
      request_id,
      target_user_id,
      tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Ensures groups and permissions for a user.

  Calls `auth.ensure_groups_and_permissions`.
  """
  @spec ensure_groups_and_permissions(
          RequestContext.t(),
          integer(),
          String.t(),
          list(String.t()),
          list(String.t())
        ) :: {:ok, list()} | {:error, any()}
  def ensure_groups_and_permissions(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        target_user_id,
        provider_code,
        provider_groups,
        provider_roles,
        tenant_id \\ 1
      ) do
    db_context().auth_ensure_groups_and_permissions(
      username,
      user_id,
      request_id,
      target_user_id,
      provider_code,
      provider_groups,
      provider_roles,
      tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  # ============================================================================
  # Utility Operations
  # ============================================================================

  @doc """
  Gets a random code for a user.

  Calls `auth.get_user_random_code`.
  """
  @spec get_random_code() :: {:ok, String.t()} | {:error, any()}
  def get_random_code do
    case db_context().auth_get_user_random_code() do
      {:ok, [%{get_user_random_code: code}]} -> {:ok, code}
      {:ok, []} -> {:error, :generation_failed}
      error -> error
    end
  end
end
