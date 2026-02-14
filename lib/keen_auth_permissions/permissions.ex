# This module provides a clean API for permission operations.
# It wraps the auto-generated database context functions with a cleaner interface.

defmodule KeenAuthPermissions.Permissions do
  @moduledoc """
  Clean facade API for permission management operations.

  All functions take a `%RequestContext{}` struct as the first parameter for authentication context,
  and return single items instead of lists where appropriate.

  ## Examples

      # List all permissions
      KeenAuthPermissions.Permissions.list(request_context, tenant_id)

      # Assign a permission
      KeenAuthPermissions.Permissions.assign(request_context, group_id, nil, "admin", "manage_users", tenant_id)

      # Check if assignable
      KeenAuthPermissions.Permissions.set_assignable(request_context, permission_id, nil, true)
  """

  alias KeenAuthPermissions.User
  alias KeenAuthPermissions.RequestContext
  alias KeenAuthPermissions.Error.ErrorParsers

  defp db_context(), do: KeenAuthPermissions.DbContext.get_global_db_context()

  # ============================================================================
  # Permission Query Operations
  # ============================================================================

  @doc """
  Lists all permissions.

  Calls `auth.get_all_permissions`.

  Returns permissions with fields: `permission_id`, `is_assignable`, `title`, `code`, `full_code`, `has_children`, `short_code`.
  """
  @spec list(RequestContext.t(), integer()) :: {:ok, list()} | {:error, any()}
  def list(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        tenant_id
      ) do
    db_context().auth_get_all_permissions(username, user_id, request_id, tenant_id)
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Gets a map of all permissions with their codes.

  Calls `public.get_permissions_map`.

  This is useful for mapping between `full_code` and `short_code`.
  Returns a list of maps with: `permission_id`, `full_code`, `short_code`, `title`.
  """
  @spec get_permissions_map() :: {:ok, list()} | {:error, any()}
  def get_permissions_map do
    db_context().get_permissions_map()
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Searches permissions with filters.

  Calls `auth.search_permissions`.
  """
  @spec search(
          RequestContext.t(),
          String.t() | nil,
          boolean() | nil,
          String.t() | nil,
          integer(),
          integer(),
          integer()
        ) :: {:ok, list()} | {:error, any()}
  def search(
        %RequestContext{user: %User{user_id: user_id}, request_id: request_id},
        search_text,
        is_assignable,
        parent_code,
        page,
        page_size,
        tenant_id
      ) do
    db_context().auth_search_permissions(
      user_id,
      request_id,
      search_text,
      is_assignable,
      parent_code,
      page,
      page_size,
      tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  # ============================================================================
  # Permission Assignment Operations
  # ============================================================================

  @doc """
  Assigns a permission to a user or group.

  Calls `auth.assign_permission`.
  Either `user_group_id` or `target_user_id` should be provided.
  """
  @spec assign(
          RequestContext.t(),
          integer() | nil,
          integer() | nil,
          String.t(),
          String.t(),
          integer()
        ) :: {:ok, map()} | {:error, any()}
  def assign(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        user_group_id,
        target_user_id,
        perm_set_code,
        perm_code,
        tenant_id
      ) do
    case db_context().auth_assign_permission(
           username,
           user_id,
           request_id,
           user_group_id,
           target_user_id,
           perm_set_code,
           perm_code,
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :assign_failed}
      error -> error
    end
  end

  @doc """
  Unassigns a permission.

  Calls `auth.unassign_permission`.
  """
  @spec unassign(RequestContext.t(), integer(), integer()) :: {:ok, map()} | {:error, any()}
  def unassign(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        assignment_id,
        tenant_id
      ) do
    case db_context().auth_unassign_permission(
           username,
           user_id,
           request_id,
           assignment_id,
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :unassign_failed}
      error -> error
    end
  end

  # ============================================================================
  # Permission Creation/Update Operations
  # ============================================================================

  @doc """
  Creates a new permission.

  Calls `auth.create_permission`.

  ## Parameters
    - `ctx` - Request context with user authentication
    - `title` - The permission title
    - `parent_full_code` - Full code of the parent permission (for hierarchical permissions)
    - `is_assignable` - Whether this permission can be assigned to users/groups
    - `short_code` - Optional short code for easier reference (alternative to full_code)
  """
  @spec create(RequestContext.t(), String.t(), String.t(), boolean(), String.t() | nil) ::
          {:ok, map()} | {:error, any()}
  def create(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        title,
        parent_full_code,
        is_assignable,
        short_code \\ nil
      ) do
    case db_context().auth_create_permission(
           username,
           user_id,
           request_id,
           title,
           parent_full_code,
           is_assignable,
           short_code
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :creation_failed}
      error -> error
    end
  end

  @doc """
  Sets a permission as assignable or not.

  Calls `auth.set_permission_as_assignable`.
  Either `permission_id` or `permission_full_code` should be provided.
  """
  @spec set_assignable(
          RequestContext.t(),
          integer() | nil,
          String.t() | nil,
          boolean()
        ) :: {:ok, map()} | {:error, any()}
  def set_assignable(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        permission_id,
        permission_full_code,
        is_assignable
      ) do
    case db_context().auth_set_permission_as_assignable(
           username,
           user_id,
           request_id,
           permission_id,
           permission_full_code,
           is_assignable
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :update_failed}
      error -> error
    end
  end

  # ============================================================================
  # Permission Checking Operations
  # ============================================================================

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
  # Error Throwing Operations
  # ============================================================================

  @doc """
  Throws a no access error.

  Calls `auth.throw_no_access`.
  """
  @spec throw_no_access(String.t(), integer()) :: {:error, any()}
  def throw_no_access(username, tenant_id) do
    db_context().auth_throw_no_access(username, tenant_id)
    |> ErrorParsers.parse_if_error()
  end

end
