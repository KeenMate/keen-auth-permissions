defmodule KeenAuthPermissions.ResourceAccess do
  @moduledoc """
  Facade for resource-level authorization (ACL).

  While RBAC (via `KeenAuthPermissions.Permissions`) controls **what actions** a user can perform,
  this module controls **which specific resources** they can act on.

  Access flags (e.g., `read`, `write`, `delete`, `share`) can be granted to individual users
  or to groups. Explicit user-level denies override all group-level grants.

  ## Access check algorithm (priority order)

  1. System user (id=1) — always allowed
  2. Tenant owner — always allowed
  3. User-level deny — blocked, overrides everything
  4. User-level grant — allowed
  5. Group-level grant (via active group membership) — allowed
  6. No matching row — denied
  """

  alias KeenAuthPermissions.User
  alias KeenAuthPermissions.RequestContext
  alias KeenAuthPermissions.Error.ErrorParsers

  defp db_context(), do: KeenAuthPermissions.DbContext.get_global_db_context()

  # ============================================================================
  # Access Checks
  # ============================================================================

  @doc """
  Checks if a user has a specific access flag on a resource.

  When `throw_err` is `true`, raises a database exception on denial instead of returning `false`.

  Calls `auth.has_resource_access`.
  """
  @spec has_access?(RequestContext.t(), String.t(), integer(), String.t(), integer(), boolean()) ::
          {:ok, boolean()} | {:error, any()}
  def has_access?(
        %RequestContext{user: %User{user_id: user_id}, request_id: request_id},
        resource_type,
        resource_id,
        required_flag,
        tenant_id,
        throw_err \\ false
      ) do
    case db_context().auth_has_resource_access(
           user_id,
           request_id,
           resource_type,
           resource_id,
           required_flag,
           tenant_id,
           throw_err
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [%{has_resource_access: result}]} -> {:ok, result}
      {:ok, []} -> {:ok, false}
      error -> error
    end
  end

  @doc """
  Filters a list of resource IDs to only those the user can access with the required flag.

  Returns the subset of `resource_ids` that the user has access to.

  Calls `auth.filter_accessible_resources`.
  """
  @spec filter_accessible(RequestContext.t(), String.t(), list(integer()), String.t(), integer()) ::
          {:ok, list(integer())} | {:error, any()}
  def filter_accessible(
        %RequestContext{user: %User{user_id: user_id}, request_id: request_id},
        resource_type,
        resource_ids,
        required_flag,
        tenant_id
      ) do
    case db_context().auth_filter_accessible_resources(
           user_id,
           request_id,
           resource_type,
           resource_ids,
           required_flag,
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, results} -> {:ok, Enum.map(results, & &1.filter_accessible_resources)}
      error -> error
    end
  end

  # ============================================================================
  # Grant / Deny / Revoke
  # ============================================================================

  @doc """
  Grants access flags on a resource to a user or group.

  Pass `target_user_id` for user-level grants, `user_group_id` for group-level grants.
  Set the other to `nil`.

  Calls `auth.grant_resource_access`.
  """
  @spec grant(RequestContext.t(), String.t(), integer(), integer() | nil, integer() | nil, list(String.t()), integer()) ::
          {:ok, list(map())} | {:error, any()}
  def grant(
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id},
        resource_type,
        resource_id,
        target_user_id,
        user_group_id,
        access_flags,
        tenant_id
      ) do
    db_context().auth_grant_resource_access(
      username,
      user_id,
      request_id,
      resource_type,
      resource_id,
      target_user_id,
      user_group_id,
      access_flags,
      tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Explicitly denies access flags on a resource for a user.

  Deny is user-level only — cannot deny groups. A user-level deny overrides all group grants.

  Calls `auth.deny_resource_access`.
  """
  @spec deny(RequestContext.t(), String.t(), integer(), integer(), list(String.t()), integer()) ::
          {:ok, list(map())} | {:error, any()}
  def deny(
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id},
        resource_type,
        resource_id,
        target_user_id,
        access_flags,
        tenant_id
      ) do
    db_context().auth_deny_resource_access(
      username,
      user_id,
      request_id,
      resource_type,
      resource_id,
      target_user_id,
      access_flags,
      tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Revokes specific access flags from a user or group on a resource.

  Pass `target_user_id` for user-level revocation, `user_group_id` for group-level.
  Set the other to `nil`.

  Calls `auth.revoke_resource_access`.
  """
  @spec revoke(RequestContext.t(), String.t(), integer(), integer() | nil, integer() | nil, list(String.t()), integer()) ::
          {:ok, integer()} | {:error, any()}
  def revoke(
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id},
        resource_type,
        resource_id,
        target_user_id,
        user_group_id,
        access_flags,
        tenant_id
      ) do
    case db_context().auth_revoke_resource_access(
           username,
           user_id,
           request_id,
           resource_type,
           resource_id,
           target_user_id,
           user_group_id,
           access_flags,
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [%{revoke_resource_access: count}]} -> {:ok, count}
      {:ok, []} -> {:ok, 0}
      error -> error
    end
  end

  @doc """
  Revokes all access on a resource (cleanup on resource delete).

  Removes all grants and denies for the given resource.

  Calls `auth.revoke_all_resource_access`.
  """
  @spec revoke_all(RequestContext.t(), String.t(), integer(), integer()) ::
          {:ok, integer()} | {:error, any()}
  def revoke_all(
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id},
        resource_type,
        resource_id,
        tenant_id
      ) do
    case db_context().auth_revoke_all_resource_access(
           username,
           user_id,
           request_id,
           resource_type,
           resource_id,
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [%{revoke_all_resource_access: count}]} -> {:ok, count}
      {:ok, []} -> {:ok, 0}
      error -> error
    end
  end

  # ============================================================================
  # Querying
  # ============================================================================

  @doc """
  Returns all effective access flags a user has on a resource.

  Each result includes the `access_flag` and `source` (e.g., `"direct"` or group name).

  Calls `auth.get_resource_access_flags`.
  """
  @spec get_flags(RequestContext.t(), String.t(), integer(), integer()) ::
          {:ok, list(map())} | {:error, any()}
  def get_flags(
        %RequestContext{user: %User{user_id: user_id}, request_id: request_id},
        resource_type,
        resource_id,
        tenant_id
      ) do
    db_context().auth_get_resource_access_flags(
      user_id,
      request_id,
      resource_type,
      resource_id,
      tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Returns access flags across the resource hierarchy for a user.

  For hierarchical resource types (e.g., `project`, `project.documents`), returns flags
  for all matching sub-resources.

  Calls `auth.get_resource_access_matrix`.
  """
  @spec get_matrix(RequestContext.t(), String.t(), integer(), integer()) ::
          {:ok, list(map())} | {:error, any()}
  def get_matrix(
        %RequestContext{user: %User{user_id: user_id}, request_id: request_id},
        resource_type,
        resource_id,
        tenant_id
      ) do
    db_context().auth_get_resource_access_matrix(
      user_id,
      request_id,
      resource_type,
      resource_id,
      tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Lists all grants and denies on a resource.

  Returns detailed rows with user/group info, flag, deny status, who granted it, and when.

  Calls `auth.get_resource_grants`.
  """
  @spec get_grants(RequestContext.t(), String.t(), integer(), integer()) ::
          {:ok, list(map())} | {:error, any()}
  def get_grants(
        %RequestContext{user: %User{user_id: user_id}, request_id: request_id},
        resource_type,
        resource_id,
        tenant_id
      ) do
    db_context().auth_get_resource_grants(
      user_id,
      request_id,
      resource_type,
      resource_id,
      tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Lists resources a user can access, filtered by resource type and optional access flag.

  Calls `auth.get_user_accessible_resources`.
  """
  @spec get_user_resources(RequestContext.t(), integer(), String.t(), String.t() | nil, integer()) ::
          {:ok, list(map())} | {:error, any()}
  def get_user_resources(
        %RequestContext{user: %User{user_id: user_id}, request_id: request_id},
        target_user_id,
        resource_type,
        access_flag,
        tenant_id
      ) do
    db_context().auth_get_user_accessible_resources(
      user_id,
      request_id,
      target_user_id,
      resource_type,
      access_flag,
      tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  # ============================================================================
  # Resource Type Management
  # ============================================================================

  @doc """
  Registers a new resource type.

  Resource types support hierarchy (e.g., `project` -> `project.documents` -> `project.invoices`).
  A partition is automatically created in `auth.resource_access` for each type.

  Calls `auth.create_resource_type`.
  """
  @spec create_resource_type(RequestContext.t(), String.t(), String.t(), String.t() | nil, String.t() | nil, integer(), String.t() | nil) ::
          {:ok, map()} | {:error, any()}
  def create_resource_type(
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id},
        code,
        title,
        parent_code \\ nil,
        description \\ nil,
        tenant_id \\ 1,
        source \\ nil
      ) do
    case db_context().auth_create_resource_type(
           username,
           user_id,
           request_id,
           code,
           title,
           parent_code,
           description,
           tenant_id,
           source
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :creation_failed}
      error -> error
    end
  end
end
