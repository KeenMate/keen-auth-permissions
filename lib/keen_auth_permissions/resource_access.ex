defmodule KeenAuthPermissions.ResourceAccess do
  @moduledoc """
  Facade for resource-level authorization (ACL).

  While RBAC (via `KeenAuthPermissions.Permissions`) controls **what actions** a user can perform,
  this module controls **which specific resources** they can act on.

  Resource IDs are JSONB maps that match the resource type's `key_schema`.
  For simple types, use `%{"id" => 42}`. For hierarchical types, use composite keys
  like `%{"project_id" => 1, "folder_id" => 5}`.

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

  `resource_id` is a JSONB map matching the resource type's key_schema (e.g., `%{"id" => 42}`).
  When `throw_err` is `true`, raises a database exception on denial instead of returning `false`.

  Calls `auth.has_resource_access`.
  """
  @spec has_access?(RequestContext.t(), String.t(), map(), String.t(), integer(), boolean()) ::
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

  `resource_ids` is a list of JSONB maps (e.g., `[%{"id" => 1}, %{"id" => 2}]`).
  Returns the subset the user has access to.

  Calls `auth.filter_accessible_resources`.
  """
  @spec filter_accessible(RequestContext.t(), String.t(), list(map()), String.t(), integer()) ::
          {:ok, list(map())} | {:error, any()}
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

  `resource_id` is a JSONB map matching the resource type's key_schema.
  Pass `target_user_id` for user-level grants, `user_group_id` for group-level grants.
  Set the other to `nil`.

  Calls `auth.assign_resource_access`.
  """
  @spec grant(
          RequestContext.t(),
          String.t(),
          map(),
          integer() | nil,
          integer() | nil,
          list(String.t()),
          integer()
        ) ::
          {:ok, list(map())} | {:error, any()}
  def grant(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        resource_type,
        resource_id,
        target_user_id,
        user_group_id,
        access_flags,
        tenant_id
      ) do
    db_context().auth_assign_resource_access(
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
  @spec deny(RequestContext.t(), String.t(), map(), integer(), list(String.t()), integer()) ::
          {:ok, list(map())} | {:error, any()}
  def deny(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
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
  @spec revoke(
          RequestContext.t(),
          String.t(),
          map(),
          integer() | nil,
          integer() | nil,
          list(String.t()),
          integer()
        ) ::
          {:ok, integer()} | {:error, any()}
  def revoke(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
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
  @spec revoke_all(RequestContext.t(), String.t(), map(), integer()) ::
          {:ok, integer()} | {:error, any()}
  def revoke_all(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
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
  @spec get_flags(RequestContext.t(), String.t(), map(), integer()) ::
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
  @spec get_matrix(RequestContext.t(), String.t(), map(), integer()) ::
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
  @spec get_grants(RequestContext.t(), String.t(), map(), integer()) ::
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

  Returns resource IDs as JSONB maps with their access flags.

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
  Lists resource types, optionally filtered by source and active status.

  Returns types with `key_schema` describing the JSONB structure expected for resource IDs.

  Calls `auth.get_resource_types`.
  """
  @spec list_resource_types(String.t() | nil, boolean(), String.t() | nil) ::
          {:ok, list(map())} | {:error, any()}
  def list_resource_types(source \\ nil, active_only \\ true, language_code \\ nil) do
    db_context().auth_get_resource_types(source, active_only, language_code)
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Ensures resource types exist (upsert from JSONB).

  `resource_types` is a list of maps with keys: `code`, `title`, `parent_code`, `description`,
  and `key_schema`. It is passed as JSONB to the stored procedure.

  Calls `auth.ensure_resource_types`.
  """
  @spec ensure_resource_types(
          RequestContext.t(),
          list(map()),
          String.t() | nil,
          integer(),
          String.t() | nil
        ) ::
          {:ok, list()} | {:error, any()}
  def ensure_resource_types(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        resource_types,
        source,
        tenant_id,
        language_code \\ nil
      ) do
    db_context().auth_ensure_resource_types(
      username,
      user_id,
      request_id,
      resource_types,
      source,
      tenant_id,
      language_code
    )
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Updates an existing resource type.

  Calls `auth.update_resource_type`.
  """
  @spec update_resource_type(
          RequestContext.t(),
          String.t(),
          String.t(),
          String.t() | nil,
          boolean(),
          String.t() | nil,
          integer(),
          String.t() | nil
        ) ::
          {:ok, map()} | {:error, any()}
  def update_resource_type(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        code,
        title,
        description,
        is_active,
        source,
        tenant_id,
        language_code \\ nil
      ) do
    case db_context().auth_update_resource_type(
           username,
           user_id,
           request_id,
           code,
           title,
           description,
           is_active,
           source,
           tenant_id,
           language_code
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :update_failed}
      error -> error
    end
  end

  # ============================================================================
  # Access Flag Management
  # ============================================================================

  @doc """
  Lists all registered access flags, optionally filtered by source, in a given language.

  Access flags (`"read"`, `"write"`, `"share"`, ...) are the atomic permissions that
  roles bundle together. This returns the canonical set with translated titles.

  Calls `auth.get_access_flags`.
  """
  @spec list_access_flags(String.t() | nil, String.t() | nil) ::
          {:ok, list(map())} | {:error, any()}
  def list_access_flags(source \\ nil, language_code \\ "en") do
    db_context().auth_get_access_flags(source, language_code)
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Upserts a batch of access-flag definitions (code + title + description).

  `flags` is a JSONB list: `[%{"code" => "read", "title" => "Read", "description" => "..."}, ...]`.
  Idempotent — safe to run on every bootstrap.

  Calls `auth.ensure_access_flags`.
  """
  @spec ensure_access_flags(
          RequestContext.t(),
          list(map()) | map(),
          String.t() | nil,
          integer(),
          String.t() | nil
        ) :: {:ok, list()} | {:error, any()}
  def ensure_access_flags(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        flags,
        source,
        tenant_id,
        language_code \\ "en"
      ) do
    db_context().auth_ensure_access_flags(
      username,
      user_id,
      request_id,
      flags,
      source,
      tenant_id,
      language_code
    )
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Syncs the set of access flags attached to a given resource type.

  Any flag in `access_flags` not already attached is linked; any attached flag
  not in the list is detached. Useful when a resource-type's permission surface
  evolves between releases.

  Calls `auth.ensure_resource_type_flags`.
  """
  @spec ensure_resource_type_flags(
          RequestContext.t(),
          String.t(),
          list(String.t()),
          integer()
        ) :: {:ok, list()} | {:error, any()}
  def ensure_resource_type_flags(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        resource_type,
        access_flags,
        tenant_id
      ) do
    db_context().auth_ensure_resource_type_flags(
      username,
      user_id,
      request_id,
      resource_type,
      access_flags,
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

  `key_schema` defines the JSONB structure for resource IDs of this type.
  For simple types: `%{"id" => "bigint"}`.
  For composite keys: `%{"project_id" => "bigint", "folder_id" => "bigint"}`.

  Calls `auth.create_resource_type`.
  """
  @spec create_resource_type(
          RequestContext.t(),
          String.t(),
          String.t(),
          String.t() | nil,
          integer(),
          String.t() | nil,
          map() | nil,
          list(String.t()) | nil,
          String.t() | nil
        ) ::
          {:ok, map()} | {:error, any()}
  def create_resource_type(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        code,
        title,
        description \\ nil,
        tenant_id \\ 1,
        source \\ nil,
        key_schema \\ nil,
        access_flags \\ nil,
        language_code \\ nil
      ) do
    case db_context().auth_create_resource_type(
           username,
           user_id,
           request_id,
           code,
           title,
           description,
           tenant_id,
           source,
           key_schema,
           access_flags,
           language_code
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :creation_failed}
      error -> error
    end
  end
end
