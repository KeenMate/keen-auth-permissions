# This module provides a clean API for tenant operations.
# It wraps the auto-generated database context functions with a cleaner interface.

defmodule KeenAuthPermissions.Tenants do
  @moduledoc """
  Clean facade API for tenant management operations.

  All functions take a `%RequestContext{}` struct as the first parameter for authentication context,
  and return single items instead of lists where appropriate.

  ## Examples

      # List all tenants for a user
      KeenAuthPermissions.Tenants.list(user_id)

      # Get a tenant by ID
      KeenAuthPermissions.Tenants.get_by_id(tenant_id)

      # Create a new tenant
      KeenAuthPermissions.Tenants.create(request_context, "My Org", "my-org", true, true, owner_id)
  """

  alias KeenAuthPermissions.User
  alias KeenAuthPermissions.RequestContext
  alias KeenAuthPermissions.Error.{ErrorParsers, ErrorStruct}

  defp db_context(), do: KeenAuthPermissions.DbContext.get_global_db_context()

  # ============================================================================
  # Tenant Query Operations
  # ============================================================================

  @doc """
  Lists all tenants.

  Calls `auth.get_all_tenants`.
  """
  @spec list_all() :: {:ok, list()} | {:error, any()}
  def list_all do
    db_context().auth_get_all_tenants()
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Lists tenants for a user.

  Calls `auth.get_tenants`.
  """
  @spec list(integer()) :: {:ok, list()} | {:error, any()}
  def list(user_id, tenant_id \\ 1, target_tenant_id \\ nil) do
    db_context().auth_get_tenants(user_id, nil, tenant_id, target_tenant_id)
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Gets a tenant by ID.

  Calls `auth.get_tenant_by_id`.
  Returns a single tenant or error.
  """
  @spec get_by_id(integer()) :: {:ok, map()} | {:error, any()}
  def get_by_id(tenant_id) do
    case db_context().auth_get_tenant_by_id(tenant_id) do
      {:ok, [tenant | _]} -> {:ok, tenant}
      {:ok, []} -> {:error, ErrorStruct.create(:tenant_not_found, "Tenant not found")}
      {:error, error} -> {:error, ErrorParsers.parse_error(error)}
    end
  end

  @doc """
  Searches tenants.

  Calls `auth.search_tenants`.
  """
  @spec search(RequestContext.t(), String.t() | nil, integer(), integer()) ::
          {:ok, list()} | {:error, any()}
  def search(
        %RequestContext{user: %User{user_id: user_id}, request_id: request_id},
        search_text,
        page,
        page_size,
        tenant_id \\ 1,
        target_tenant_id \\ nil
      ) do
    db_context().auth_search_tenants(
      user_id,
      request_id,
      search_text,
      page,
      page_size,
      tenant_id,
      target_tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  # ============================================================================
  # Tenant CRUD Operations
  # ============================================================================

  @doc """
  Creates a new tenant.

  Calls `auth.create_tenant`.
  """
  @spec create(RequestContext.t(), String.t(), String.t(), boolean(), boolean(), integer()) ::
          {:ok, map()} | {:error, any()}
  def create(
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id},
        title,
        code,
        is_removable,
        is_assignable,
        tenant_owner_id,
        tenant_id \\ 1
      ) do
    case db_context().auth_create_tenant(
           username,
           user_id,
           request_id,
           title,
           code,
           is_removable,
           is_assignable,
           tenant_owner_id,
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :creation_failed}
      error -> error
    end
  end

  @doc """
  Updates a tenant.

  Calls `auth.update_tenant`.
  """
  @spec update(
          RequestContext.t(),
          integer(),
          String.t(),
          String.t(),
          boolean(),
          boolean(),
          integer()
        ) :: {:ok, map()} | {:error, any()}
  def update(
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id},
        tenant_id,
        title,
        code,
        is_removable,
        is_assignable,
        tenant_owner_id
      ) do
    case db_context().auth_update_tenant(
           username,
           user_id,
           request_id,
           tenant_id,
           title,
           code,
           is_removable,
           is_assignable,
           tenant_owner_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :update_failed}
      error -> error
    end
  end

  @doc """
  Deletes a tenant by UUID.

  Calls `auth.delete_tenant`.
  """
  @spec delete(RequestContext.t(), String.t()) :: {:ok, map()} | {:error, any()}
  def delete(
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id},
        tenant_uuid,
        tenant_id \\ 1
      ) do
    case db_context().auth_delete_tenant(
           username,
           user_id,
           request_id,
           tenant_uuid,
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :delete_failed}
      error -> error
    end
  end

  @doc """
  Deletes a tenant by UUID (alternative).

  Calls `auth.delete_tenant_by_uuid`.
  """
  @spec delete_by_uuid(RequestContext.t(), String.t()) :: {:ok, map()} | {:error, any()}
  def delete_by_uuid(
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id},
        tenant_uuid,
        tenant_id \\ 1
      ) do
    case db_context().auth_delete_tenant_by_uuid(
           username,
           user_id,
           request_id,
           tenant_uuid,
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :delete_failed}
      error -> error
    end
  end

  # ============================================================================
  # Tenant User/Member Operations
  # ============================================================================

  @doc """
  Lists users in a tenant.

  Calls `auth.get_tenant_users`.
  """
  @spec list_users(RequestContext.t(), integer()) :: {:ok, list()} | {:error, any()}
  def list_users(
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id},
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
  Lists members in a tenant.

  Calls `auth.get_tenant_members`.
  """
  @spec list_members(RequestContext.t(), integer()) :: {:ok, list()} | {:error, any()}
  def list_members(
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id},
        tenant_id,
        target_tenant_id \\ nil
      ) do
    db_context().auth_get_tenant_members(
      username,
      user_id,
      request_id,
      tenant_id,
      target_tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Lists groups in a tenant.

  Calls `auth.get_tenant_groups`.
  """
  @spec list_groups(RequestContext.t(), integer()) :: {:ok, list()} | {:error, any()}
  def list_groups(
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id},
        tenant_id,
        target_tenant_id \\ nil
      ) do
    db_context().auth_get_tenant_groups(
      username,
      user_id,
      request_id,
      tenant_id,
      target_tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  # ============================================================================
  # User Tenant Operations
  # ============================================================================

  @doc """
  Gets tenants available to a user.

  Calls `auth.get_user_available_tenants`.
  """
  @spec get_user_available_tenants(RequestContext.t(), integer()) ::
          {:ok, list()} | {:error, any()}
  def get_user_available_tenants(
        %RequestContext{user: %User{user_id: user_id}, request_id: request_id},
        target_user_id,
        tenant_id \\ 1
      ) do
    db_context().auth_get_user_available_tenants(
      user_id,
      request_id,
      target_user_id,
      tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Gets the last selected tenant for a user.

  Calls `auth.get_user_last_selected_tenant`.
  Returns a single tenant or error.
  """
  @spec get_user_last_selected_tenant(RequestContext.t(), integer()) ::
          {:ok, map()} | {:error, any()}
  def get_user_last_selected_tenant(
        %RequestContext{user: %User{user_id: user_id}, request_id: request_id},
        target_user_id,
        tenant_id \\ 1
      ) do
    case db_context().auth_get_user_last_selected_tenant(
           user_id,
           request_id,
           target_user_id,
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result | _]} -> {:ok, result}
      {:ok, []} -> {:error, ErrorStruct.create(:not_found, "No last selected tenant found")}
      error -> error
    end
  end

  @doc """
  Updates the last selected tenant for a user.

  Calls `auth.update_user_last_selected_tenant`.
  """
  @spec update_user_last_selected_tenant(RequestContext.t(), integer(), String.t()) ::
          {:ok, map()} | {:error, any()}
  def update_user_last_selected_tenant(
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id},
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
      {:ok, [result | _]} -> {:ok, result}
      {:ok, []} -> {:error, :update_failed}
      error -> error
    end
  end

  @doc """
  Creates user tenant preferences.

  Calls `auth.create_user_tenant_preferences`.
  """
  @spec create_user_tenant_preferences(RequestContext.t(), integer(), String.t(), integer()) ::
          {:ok, map()} | {:error, any()}
  def create_user_tenant_preferences(
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id},
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
      {:ok, [result | _]} -> {:ok, result}
      {:ok, []} -> {:error, :creation_failed}
      error -> error
    end
  end

  @doc """
  Updates user tenant preferences.

  Calls `auth.update_user_tenant_preferences`.
  """
  @spec update_user_tenant_preferences(
          RequestContext.t(),
          integer(),
          String.t(),
          boolean(),
          integer()
        ) :: {:ok, map()} | {:error, any()}
  def update_user_tenant_preferences(
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id},
        target_user_id,
        update_data,
        should_overwrite,
        tenant_id
      ) do
    case db_context().auth_update_user_tenant_preferences(
           username,
           user_id,
           request_id,
           target_user_id,
           update_data,
           should_overwrite,
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result | _]} -> {:ok, result}
      {:ok, []} -> {:error, :update_failed}
      error -> error
    end
  end
end
