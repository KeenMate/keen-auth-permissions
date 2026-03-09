# This module provides a clean API for permission set operations.
# It wraps the auto-generated database context functions with a cleaner interface.

defmodule KeenAuthPermissions.PermSets do
  @moduledoc """
  Clean facade API for permission set management operations.

  All functions take a `%RequestContext{}` struct as the first parameter for authentication context,
  and return single items instead of lists where appropriate.

  ## Examples

      # List all permission sets
      KeenAuthPermissions.PermSets.list(request_context, tenant_id)

      # Create a permission set
      KeenAuthPermissions.PermSets.create(request_context, "Admin", false, true, ["manage_users"], tenant_id)

      # Add permissions to a set
      KeenAuthPermissions.PermSets.create_permissions(request_context, perm_set_id, ["perm1", "perm2"], tenant_id)
  """

  alias KeenAuthPermissions.User
  alias KeenAuthPermissions.RequestContext
  alias KeenAuthPermissions.Error.ErrorParsers

  defp db_context(), do: KeenAuthPermissions.DbContext.get_global_db_context()

  # ============================================================================
  # Permission Set Query Operations
  # ============================================================================

  @doc """
  Lists all permission sets.

  Calls `auth.get_perm_sets`.
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
    db_context().auth_get_perm_sets(
      username,
      user_id,
      request_id,
      tenant_id,
      target_tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Searches permission sets with filters.

  Calls `auth.search_perm_sets`.
  """
  @spec search(
          RequestContext.t(),
          String.t() | nil,
          boolean() | nil,
          boolean() | nil,
          integer(),
          integer(),
          integer(),
          String.t() | nil
        ) :: {:ok, list()} | {:error, any()}
  def search(
        %RequestContext{user: %User{user_id: user_id}, request_id: request_id},
        search_text,
        is_assignable,
        is_system,
        page,
        page_size,
        tenant_id,
        source \\ nil,
        target_tenant_id \\ nil
      ) do
    db_context().auth_search_perm_sets(
      user_id,
      request_id,
      search_text,
      is_assignable,
      is_system,
      page,
      page_size,
      tenant_id,
      source,
      target_tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  # ============================================================================
  # Permission Set Ensure Operations
  # ============================================================================

  @doc """
  Ensures permission sets exist (upsert from JSON).

  Calls `auth.ensure_perm_sets`.
  """
  @spec ensure(RequestContext.t(), String.t(), String.t() | nil, integer(), boolean()) ::
          {:ok, list()} | {:error, any()}
  def ensure(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        perm_sets_json,
        source,
        tenant_id,
        is_final_state \\ false
      ) do
    db_context().auth_ensure_perm_sets(
      username,
      user_id,
      request_id,
      perm_sets_json,
      source,
      tenant_id,
      is_final_state
    )
    |> ErrorParsers.parse_if_error()
  end

  # ============================================================================
  # Permission Set CRUD Operations
  # ============================================================================

  @doc """
  Creates a new permission set.

  Calls `auth.create_perm_set`.
  """
  @spec create(
          RequestContext.t(),
          String.t(),
          boolean(),
          boolean(),
          list(String.t()),
          integer(),
          String.t() | nil
        ) ::
          {:ok, map()} | {:error, any()}
  def create(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        title,
        is_system,
        is_assignable,
        permissions,
        tenant_id,
        source \\ nil
      ) do
    case db_context().auth_create_perm_set(
           username,
           user_id,
           request_id,
           title,
           is_system,
           is_assignable,
           permissions,
           tenant_id,
           source
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :creation_failed}
      error -> error
    end
  end

  @doc """
  Updates a permission set.

  Calls `auth.update_perm_set`.
  """
  @spec update(RequestContext.t(), integer(), String.t(), boolean(), integer()) ::
          {:ok, map()} | {:error, any()}
  def update(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        perm_set_id,
        title,
        is_assignable,
        tenant_id
      ) do
    case db_context().auth_update_perm_set(
           username,
           user_id,
           request_id,
           perm_set_id,
           title,
           is_assignable,
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :update_failed}
      error -> error
    end
  end

  # ============================================================================
  # Permission Set Permissions Operations
  # ============================================================================

  @doc """
  Creates permissions in a permission set.

  Calls `auth.create_perm_set_permissions`.
  """
  @spec create_permissions(RequestContext.t(), integer(), list(String.t()), integer()) ::
          {:ok, list()} | {:error, any()}
  def create_permissions(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        perm_set_id,
        permissions,
        tenant_id
      ) do
    db_context().auth_create_perm_set_permissions(
      username,
      user_id,
      request_id,
      perm_set_id,
      permissions,
      tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Removes permissions from a permission set.

  Calls `auth.delete_perm_set_permissions`.
  """
  @spec delete_permissions(RequestContext.t(), integer(), list(String.t()), integer()) ::
          {:ok, list()} | {:error, any()}
  def delete_permissions(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        perm_set_id,
        permissions,
        tenant_id
      ) do
    db_context().auth_delete_perm_set_permissions(
      username,
      user_id,
      request_id,
      perm_set_id,
      permissions,
      tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end
end
