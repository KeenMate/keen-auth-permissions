defmodule KeenAuthPermissions.ResourceRoles do
  @moduledoc """
  Facade for resource roles — named bundles of access flags for a given resource type.

  A resource role (e.g. `project_admin`, `document_viewer`) groups multiple access flags
  under a single code. Assigning a role to a user/group is equivalent to granting all of
  its flags at once, but is easier to manage and audit than individual flag grants.

  Roles are defined per `resource_type` and may be activated/deactivated without being
  deleted. Flags attached to a role can be kept in sync via `ensure_flags/4`.
  """

  alias KeenAuthPermissions.User
  alias KeenAuthPermissions.RequestContext
  alias KeenAuthPermissions.Error.ErrorParsers

  defp db_context(), do: KeenAuthPermissions.DbContext.get_global_db_context()

  # ============================================================================
  # Role Definitions
  # ============================================================================

  @doc "Creates a resource role. Calls `auth.create_resource_role`."
  @spec create(
          RequestContext.t(),
          String.t(),
          String.t(),
          String.t(),
          String.t() | nil,
          list(String.t()),
          String.t() | nil,
          integer(),
          String.t() | nil
        ) :: {:ok, map()} | {:error, any()}
  def create(
        %RequestContext{user: %User{username: u, user_id: uid}, request_id: rid},
        code,
        resource_type,
        title,
        description,
        access_flags,
        source,
        tenant_id,
        language_code \\ nil
      ) do
    case db_context().auth_create_resource_role(
           u,
           uid,
           rid,
           code,
           resource_type,
           title,
           description,
           access_flags,
           source,
           tenant_id,
           language_code
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :creation_failed}
      error -> error
    end
  end

  @doc "Updates a resource role. Calls `auth.update_resource_role`."
  @spec update(
          RequestContext.t(),
          String.t(),
          String.t(),
          String.t() | nil,
          boolean(),
          String.t() | nil,
          integer(),
          String.t() | nil
        ) :: {:ok, map()} | {:error, any()}
  def update(
        %RequestContext{user: %User{username: u, user_id: uid}, request_id: rid},
        code,
        title,
        description,
        is_active,
        source,
        tenant_id,
        language_code \\ nil
      ) do
    case db_context().auth_update_resource_role(
           u,
           uid,
           rid,
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

  @doc "Deletes a resource role. Calls `auth.delete_resource_role`."
  @spec delete(RequestContext.t(), String.t(), integer()) ::
          {:ok, list()} | {:error, any()}
  def delete(
        %RequestContext{user: %User{username: u, user_id: uid}, request_id: rid},
        code,
        tenant_id
      ) do
    db_context().auth_delete_resource_role(u, uid, rid, code, tenant_id)
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Upserts a batch of resource roles from JSONB.

  When `is_final_state` is true, roles not present in the payload are deactivated.
  Calls `auth.ensure_resource_roles`.
  """
  @spec ensure(
          RequestContext.t(),
          list(map()) | map(),
          String.t() | nil,
          boolean(),
          integer(),
          String.t() | nil
        ) :: {:ok, list()} | {:error, any()}
  def ensure(
        %RequestContext{user: %User{username: u, user_id: uid}, request_id: rid},
        roles,
        source,
        is_final_state,
        tenant_id,
        language_code \\ nil
      ) do
    db_context().auth_ensure_resource_roles(
      u,
      uid,
      rid,
      roles,
      source,
      is_final_state,
      tenant_id,
      language_code
    )
    |> ErrorParsers.parse_if_error()
  end

  @doc "Syncs the access flags attached to a role. Calls `auth.ensure_resource_role_flags`."
  @spec ensure_flags(RequestContext.t(), String.t(), list(String.t()), integer()) ::
          {:ok, list()} | {:error, any()}
  def ensure_flags(
        %RequestContext{user: %User{username: u, user_id: uid}, request_id: rid},
        role_code,
        access_flags,
        tenant_id
      ) do
    db_context().auth_ensure_resource_role_flags(u, uid, rid, role_code, access_flags, tenant_id)
    |> ErrorParsers.parse_if_error()
  end

  # ============================================================================
  # Querying
  # ============================================================================

  @doc "Lists resource roles filtered by source, resource type, and active status."
  @spec list(String.t() | nil, String.t() | nil, boolean(), String.t() | nil) ::
          {:ok, list(map())} | {:error, any()}
  def list(source \\ nil, resource_type \\ nil, active_only \\ true, language_code \\ nil) do
    db_context().auth_get_resource_roles(source, resource_type, active_only, language_code)
    |> ErrorParsers.parse_if_error()
  end

  @doc "Returns the access flags attached to a role. Calls `auth.get_resource_role_flags`."
  @spec get_flags(String.t()) :: {:ok, list(map())} | {:error, any()}
  def get_flags(role_code) do
    db_context().auth_get_resource_role_flags(role_code)
    |> ErrorParsers.parse_if_error()
  end

  @doc "Lists role assignments on a resource. Calls `auth.get_resource_role_assignments`."
  @spec get_assignments(RequestContext.t(), String.t(), map(), integer(), String.t() | nil) ::
          {:ok, list(map())} | {:error, any()}
  def get_assignments(
        %RequestContext{user: %User{user_id: uid}, request_id: rid},
        resource_type,
        resource_id,
        tenant_id,
        language_code \\ nil
      ) do
    db_context().auth_get_resource_role_assignments(
      uid,
      rid,
      resource_type,
      resource_id,
      tenant_id,
      language_code
    )
    |> ErrorParsers.parse_if_error()
  end

  # ============================================================================
  # Role Assignment
  # ============================================================================

  @doc """
  Assigns one or more roles on a resource to a user or group.

  Identify the resource by either `resource_id` (JSONB map) or `resource_path` (ltree
  path string) — at least one must be provided. Pass `target_user_id` for a user
  assignment, `user_group_id` for a group assignment — set the other to `nil`.
  Calls `auth.assign_resource_role`.
  """
  @spec assign(
          RequestContext.t(),
          String.t(),
          map() | nil,
          integer() | nil,
          integer() | nil,
          list(String.t()),
          integer(),
          String.t() | nil
        ) :: {:ok, list(map())} | {:error, any()}
  def assign(
        %RequestContext{user: %User{username: u, user_id: uid}, request_id: rid},
        resource_type,
        resource_id,
        target_user_id,
        user_group_id,
        role_codes,
        tenant_id,
        resource_path \\ nil
      ) do
    db_context().auth_assign_resource_role(
      u,
      uid,
      rid,
      resource_type,
      resource_id,
      target_user_id,
      user_group_id,
      role_codes,
      tenant_id,
      resource_path
    )
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Revokes specific roles from a user or group on a resource.

  Identify the resource by either `resource_id` (JSONB map) or `resource_path` (ltree
  path string) — at least one must be provided. Calls `auth.revoke_resource_role`.
  """
  @spec revoke(
          RequestContext.t(),
          String.t(),
          map() | nil,
          integer() | nil,
          integer() | nil,
          list(String.t()),
          integer(),
          String.t() | nil
        ) :: {:ok, integer()} | {:error, any()}
  def revoke(
        %RequestContext{user: %User{username: u, user_id: uid}, request_id: rid},
        resource_type,
        resource_id,
        target_user_id,
        user_group_id,
        role_codes,
        tenant_id,
        resource_path \\ nil
      ) do
    case db_context().auth_revoke_resource_role(
           u,
           uid,
           rid,
           resource_type,
           resource_id,
           target_user_id,
           user_group_id,
           role_codes,
           tenant_id,
           resource_path
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [%{revoke_resource_role: count}]} -> {:ok, count}
      {:ok, []} -> {:ok, 0}
      error -> error
    end
  end

  @doc """
  Revokes every role assignment on a resource (cleanup on delete).

  Identify the resource by either `resource_id` (JSONB map) or `resource_path` (ltree
  path string) — at least one must be provided. Calls `auth.revoke_all_resource_roles`.
  """
  @spec revoke_all(
          RequestContext.t(),
          String.t(),
          map() | nil,
          integer(),
          String.t() | nil
        ) :: {:ok, integer()} | {:error, any()}
  def revoke_all(
        %RequestContext{user: %User{username: u, user_id: uid}, request_id: rid},
        resource_type,
        resource_id,
        tenant_id,
        resource_path \\ nil
      ) do
    case db_context().auth_revoke_all_resource_roles(
           u,
           uid,
           rid,
           resource_type,
           resource_id,
           tenant_id,
           resource_path
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [%{revoke_all_resource_roles: count}]} -> {:ok, count}
      {:ok, []} -> {:ok, 0}
      error -> error
    end
  end
end
