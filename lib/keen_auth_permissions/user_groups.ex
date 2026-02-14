# This module provides a clean API for user group operations.
# It wraps the auto-generated database context functions with a cleaner interface.

defmodule KeenAuthPermissions.UserGroups do
  @moduledoc """
  Clean facade API for user group management operations.

  All functions take a `%RequestContext{}` struct as the first parameter for authentication
  and tracing context, and return single items instead of lists where appropriate.

  ## Examples

      # Create a context
      context = RequestContext.new(user, request_id: "req-123")

      # List all groups in a tenant
      KeenAuthPermissions.UserGroups.list(context, tenant_id)

      # Get a specific group
      KeenAuthPermissions.UserGroups.get_by_id(context, group_id, tenant_id)

      # Create a new group
      KeenAuthPermissions.UserGroups.create(context, "Admins", true, true, false, false, tenant_id)

      # Add a member to a group
      KeenAuthPermissions.UserGroups.add_member(context, group_id, target_user_id, tenant_id)
  """

  alias KeenAuthPermissions.RequestContext
  alias KeenAuthPermissions.User
  alias KeenAuthPermissions.Error.ErrorParsers

  defp db_context(), do: KeenAuthPermissions.DbContext.get_global_db_context()

  # ============================================================================
  # Group CRUD Operations
  # ============================================================================

  @doc """
  Lists all user groups in a tenant.

  Calls `auth.get_tenant_groups`.
  """
  @spec list(RequestContext.t(), integer()) :: {:ok, list()} | {:error, any()}
  def list(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        tenant_id
      ) do
    db_context().auth_get_tenant_groups(username, user_id, request_id, tenant_id)
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Gets a user group by ID.

  Calls `auth.get_user_group_by_id`.
  Returns a single group or error.
  """
  @spec get_by_id(RequestContext.t(), integer(), integer()) :: {:ok, map()} | {:error, any()}
  def get_by_id(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        group_id,
        tenant_id
      ) do
    case db_context().auth_get_user_group_by_id(
           username,
           user_id,
           request_id,
           group_id,
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :not_found}
      error -> error
    end
  end

  @doc """
  Creates a new user group.

  Calls `auth.create_user_group`.
  Returns the created group.
  """
  @spec create(
          RequestContext.t(),
          String.t(),
          boolean(),
          boolean(),
          boolean(),
          boolean(),
          integer()
        ) ::
          {:ok, map()} | {:error, any()}
  def create(
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id} =
          ctx,
        title,
        is_assignable,
        is_active,
        is_external,
        is_default,
        tenant_id
      ) do
    case db_context().auth_create_user_group(
           username,
           user_id,
           request_id,
           title,
           is_assignable,
           is_active,
           is_external,
           is_default,
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [%{create_user_group: user_group_id}]} ->
        # Fetch the full group record after creation
        get_by_id(ctx, user_group_id, tenant_id)

      {:ok, []} ->
        {:error, :creation_failed}

      error ->
        error
    end
  end

  @doc """
  Creates an external user group with provider mapping.

  Calls `auth.create_external_user_group`.
  Returns the created group.
  """
  @spec create_external(
          RequestContext.t(),
          String.t(),
          String.t(),
          boolean(),
          boolean(),
          String.t(),
          String.t(),
          String.t(),
          integer()
        ) :: {:ok, map()} | {:error, any()}
  def create_external(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        title,
        provider,
        is_assignable,
        is_active,
        mapped_object_id,
        mapped_object_name,
        mapped_role,
        tenant_id
      ) do
    case db_context().auth_create_external_user_group(
           username,
           user_id,
           request_id,
           title,
           provider,
           is_assignable,
           is_active,
           mapped_object_id,
           mapped_object_name,
           mapped_role,
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :creation_failed}
      error -> error
    end
  end

  @doc """
  Updates a user group.

  Calls `auth.update_user_group`.
  """
  @spec update(
          RequestContext.t(),
          integer(),
          String.t(),
          boolean(),
          boolean(),
          boolean(),
          boolean(),
          integer()
        ) :: {:ok, map()} | {:error, any()}
  def update(
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id} =
          ctx,
        group_id,
        title,
        is_assignable,
        is_active,
        is_external,
        is_default,
        tenant_id
      ) do
    case db_context().auth_update_user_group(
           username,
           user_id,
           request_id,
           group_id,
           title,
           is_assignable,
           is_active,
           is_external,
           is_default,
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [%{update_user_group: _}]} ->
        # Fetch the full group record after update
        get_by_id(ctx, group_id, tenant_id)

      {:ok, []} ->
        {:error, :update_failed}

      error ->
        error
    end
  end

  @doc """
  Deletes a user group.

  Calls `auth.delete_user_group`.
  """
  @spec delete(RequestContext.t(), integer(), integer()) :: {:ok, map()} | {:error, any()}
  def delete(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        group_id,
        tenant_id
      ) do
    case db_context().auth_delete_user_group(username, user_id, request_id, group_id, tenant_id)
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :delete_failed}
      error -> error
    end
  end

  @doc """
  Searches user groups with filters.

  Calls `auth.search_user_groups`.
  """
  @spec search(
          RequestContext.t(),
          String.t() | nil,
          boolean() | nil,
          boolean() | nil,
          boolean() | nil,
          integer(),
          integer(),
          integer()
        ) :: {:ok, list()} | {:error, any()}
  def search(
        %RequestContext{user: %User{user_id: user_id}, request_id: request_id},
        search_text,
        is_active,
        is_external,
        is_system,
        page,
        page_size,
        tenant_id
      ) do
    db_context().auth_search_user_groups(
      user_id,
      request_id,
      search_text,
      is_active,
      is_external,
      is_system,
      page,
      page_size,
      tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  # ============================================================================
  # Group State Operations
  # ============================================================================

  @doc """
  Enables a user group.

  Calls `auth.enable_user_group`.
  """
  @spec enable(RequestContext.t(), integer(), integer()) :: {:ok, map()} | {:error, any()}
  def enable(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        group_id,
        tenant_id
      ) do
    case db_context().auth_enable_user_group(username, user_id, request_id, group_id, tenant_id)
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :enable_failed}
      error -> error
    end
  end

  @doc """
  Disables a user group.

  Calls `auth.disable_user_group`.
  """
  @spec disable(RequestContext.t(), integer(), integer()) :: {:ok, map()} | {:error, any()}
  def disable(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        group_id,
        tenant_id
      ) do
    case db_context().auth_disable_user_group(username, user_id, request_id, group_id, tenant_id)
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :disable_failed}
      error -> error
    end
  end

  @doc """
  Locks a user group.

  Calls `auth.lock_user_group`.
  """
  @spec lock(RequestContext.t(), integer(), integer()) :: {:ok, map()} | {:error, any()}
  def lock(
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id} =
          ctx,
        group_id,
        tenant_id
      ) do
    case db_context().auth_lock_user_group(username, user_id, request_id, group_id, tenant_id)
         |> ErrorParsers.parse_if_error() do
      {:ok, [%{user_group_id: _}]} ->
        # Fetch the full group record to get all fields including is_locked
        get_by_id(ctx, group_id, tenant_id)

      {:ok, []} ->
        {:error, :lock_failed}

      error ->
        error
    end
  end

  @doc """
  Unlocks a user group.

  Calls `auth.unlock_user_group`.
  """
  @spec unlock(RequestContext.t(), integer(), integer()) :: {:ok, map()} | {:error, any()}
  def unlock(
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id} =
          ctx,
        group_id,
        tenant_id
      ) do
    case db_context().auth_unlock_user_group(username, user_id, request_id, group_id, tenant_id)
         |> ErrorParsers.parse_if_error() do
      {:ok, [%{user_group_id: _}]} ->
        # Fetch the full group record to get all fields including is_locked
        get_by_id(ctx, group_id, tenant_id)

      {:ok, []} ->
        {:error, :unlock_failed}

      error ->
        error
    end
  end

  @doc """
  Sets a user group as external.

  Calls `auth.set_user_group_as_external`.
  """
  @spec set_as_external(RequestContext.t(), integer(), integer()) :: :ok | {:error, any()}
  def set_as_external(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        group_id,
        tenant_id
      ) do
    db_context().auth_set_user_group_as_external(
      username,
      user_id,
      request_id,
      group_id,
      tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Sets a user group as hybrid (both internal and external).

  Calls `auth.set_user_group_as_hybrid`.
  """
  @spec set_as_hybrid(RequestContext.t(), integer(), integer()) :: :ok | {:error, any()}
  def set_as_hybrid(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        group_id,
        tenant_id
      ) do
    db_context().auth_set_user_group_as_hybrid(username, user_id, request_id, group_id, tenant_id)
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Sets a user group as internal.

  Calls `auth.set_user_group_as_internal`.
  """
  @spec set_as_internal(RequestContext.t(), integer(), integer()) :: :ok | {:error, any()}
  def set_as_internal(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        group_id,
        tenant_id
      ) do
    db_context().auth_set_user_group_as_internal(
      username,
      user_id,
      request_id,
      group_id,
      tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  # ============================================================================
  # Group Member Operations
  # ============================================================================

  @doc """
  Lists members of a user group.

  Calls `auth.get_user_group_members`.
  """
  @spec list_members(RequestContext.t(), integer(), integer()) :: {:ok, list()} | {:error, any()}
  def list_members(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        group_id,
        tenant_id
      ) do
    db_context().auth_get_user_group_members(username, user_id, request_id, group_id, tenant_id)
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Adds a member to a user group.

  Calls `auth.create_user_group_member`.
  """
  @spec add_member(RequestContext.t(), integer(), integer(), integer()) ::
          {:ok, map()} | {:error, any()}
  def add_member(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        group_id,
        target_user_id,
        tenant_id
      ) do
    case db_context().auth_create_user_group_member(
           username,
           user_id,
           request_id,
           group_id,
           target_user_id,
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [%{create_user_group_member: member_id}]} ->
        # Return a map with the expected fields
        {:ok,
         %{user_group_member_id: member_id, user_group_id: group_id, user_id: target_user_id}}

      {:ok, []} ->
        {:error, :add_member_failed}

      error ->
        error
    end
  end

  @doc """
  Removes a member from a user group.

  Calls `auth.delete_user_group_member`.
  """
  @spec remove_member(RequestContext.t(), integer(), integer(), integer()) ::
          :ok | {:error, any()}
  def remove_member(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        group_id,
        target_user_id,
        tenant_id
      ) do
    db_context().auth_delete_user_group_member(
      username,
      user_id,
      request_id,
      group_id,
      target_user_id,
      tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Checks if a user is a member of a group.

  Calls `auth.is_group_member`.
  """
  @spec is_member?(integer(), integer(), integer()) :: {:ok, boolean()} | {:error, any()}
  def is_member?(user_id, group_id, tenant_id) do
    case db_context().auth_is_group_member(user_id, nil, group_id, tenant_id) do
      {:ok, [%{is_group_member: result}]} -> {:ok, result}
      {:ok, []} -> {:ok, false}
      error -> error
    end
  end

  @doc """
  Checks if a user can manage a user group.

  Calls `auth.can_manage_user_group`.
  """
  @spec can_manage?(integer(), integer(), String.t(), integer()) ::
          {:ok, boolean()} | {:error, any()}
  def can_manage?(user_id, group_id, permission, tenant_id) do
    case db_context().auth_can_manage_user_group(user_id, nil, group_id, permission, tenant_id) do
      {:ok, [%{can_manage_user_group: result}]} -> {:ok, result}
      {:ok, []} -> {:ok, false}
      error -> error
    end
  end

  # ============================================================================
  # Group Mapping Operations
  # ============================================================================

  @doc """
  Lists mappings for a user group.

  Calls `auth.get_user_group_mappings`.
  """
  @spec list_mappings(RequestContext.t(), integer(), integer()) :: {:ok, list()} | {:error, any()}
  def list_mappings(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        group_id,
        tenant_id
      ) do
    db_context().auth_get_user_group_mappings(username, user_id, request_id, group_id, tenant_id)
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Creates a user group mapping.

  Calls `auth.create_user_group_mapping`.
  """
  @spec create_mapping(
          RequestContext.t(),
          integer(),
          String.t(),
          String.t(),
          String.t(),
          String.t(),
          integer()
        ) :: {:ok, map()} | {:error, any()}
  def create_mapping(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        group_id,
        provider_code,
        mapped_object_id,
        mapped_object_name,
        mapped_role,
        tenant_id
      ) do
    case db_context().auth_create_user_group_mapping(
           username,
           user_id,
           request_id,
           group_id,
           provider_code,
           mapped_object_id,
           mapped_object_name,
           mapped_role,
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :create_mapping_failed}
      error -> error
    end
  end

  @doc """
  Deletes a user group mapping.

  Calls `auth.delete_user_group_mapping`.
  """
  @spec delete_mapping(RequestContext.t(), integer(), integer()) :: :ok | {:error, any()}
  def delete_mapping(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        mapping_id,
        tenant_id
      ) do
    db_context().auth_delete_user_group_mapping(
      username,
      user_id,
      request_id,
      mapping_id,
      tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  # ============================================================================
  # Group Owner Operations
  # ============================================================================

  @doc """
  Creates an owner for a user group.

  Calls `auth.create_owner`.
  """
  @spec create_owner(RequestContext.t(), integer(), integer(), integer()) ::
          {:ok, map()} | {:error, any()}
  def create_owner(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        target_user_id,
        group_id,
        tenant_id
      ) do
    case db_context().auth_create_owner(
           username,
           user_id,
           request_id,
           target_user_id,
           group_id,
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :create_owner_failed}
      error -> error
    end
  end

  @doc """
  Deletes an owner from a user group.

  Calls `auth.delete_owner`.
  """
  @spec delete_owner(RequestContext.t(), integer(), integer(), integer()) :: :ok | {:error, any()}
  def delete_owner(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        target_user_id,
        group_id,
        tenant_id
      ) do
    db_context().auth_delete_owner(
      username,
      user_id,
      request_id,
      target_user_id,
      group_id,
      tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Checks if a user is an owner of a group.

  Calls `auth.is_owner`.
  """
  @spec is_owner?(integer(), integer(), integer()) :: {:ok, boolean()} | {:error, any()}
  def is_owner?(user_id, group_id, tenant_id) do
    case db_context().auth_is_owner(user_id, nil, group_id, tenant_id) do
      {:ok, [%{is_owner: result}]} -> {:ok, result}
      {:ok, []} -> {:ok, false}
      error -> error
    end
  end

  @doc """
  Checks if a group has any owners.

  Calls `auth.has_owner`.
  """
  @spec has_owner?(integer(), integer()) :: {:ok, boolean()} | {:error, any()}
  def has_owner?(group_id, tenant_id) do
    case db_context().auth_has_owner(group_id, tenant_id) do
      {:ok, [%{has_owner: result}]} -> {:ok, result}
      {:ok, []} -> {:ok, false}
      error -> error
    end
  end

  # ============================================================================
  # Group Permission Operations
  # ============================================================================

  @doc """
  Gets assigned permissions for a user group.

  Calls `auth.get_assigned_group_permissions`.
  """
  @spec list_assigned_permissions(RequestContext.t(), integer(), integer()) ::
          {:ok, list()} | {:error, any()}
  def list_assigned_permissions(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        group_id,
        tenant_id
      ) do
    db_context().auth_get_assigned_group_permissions(
      username,
      user_id,
      request_id,
      group_id,
      tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Gets effective permissions for a user group.

  Calls `auth.get_effective_group_permissions`.
  """
  @spec list_effective_permissions(RequestContext.t(), integer(), integer()) ::
          {:ok, list()} | {:error, any()}
  def list_effective_permissions(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        group_id,
        tenant_id
      ) do
    db_context().auth_get_effective_group_permissions(
      username,
      user_id,
      request_id,
      group_id,
      tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  # ============================================================================
  # Sync Operations
  # ============================================================================

  @doc """
  Gets user groups that need to be synced.

  Calls `auth.get_user_groups_to_sync`.
  """
  @spec list_groups_to_sync(integer()) :: {:ok, list()} | {:error, any()}
  def list_groups_to_sync(user_id) do
    db_context().auth_get_user_groups_to_sync(user_id)
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Processes external group member sync.

  Calls `auth.process_external_group_member_sync`.
  """
  @spec process_external_sync(RequestContext.t(), integer()) :: {:ok, list()} | {:error, any()}
  def process_external_sync(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        group_id
      ) do
    db_context().auth_process_external_group_member_sync(username, user_id, request_id, group_id)
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Processes external group member sync by mapping.

  Calls `auth.process_external_group_member_sync_by_mapping`.
  """
  @spec process_external_sync_by_mapping(RequestContext.t(), integer()) ::
          {:ok, list()} | {:error, any()}
  def process_external_sync_by_mapping(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        mapping_id
      ) do
    db_context().auth_process_external_group_member_sync_by_mapping(
      username,
      user_id,
      request_id,
      mapping_id
    )
    |> ErrorParsers.parse_if_error()
  end
end
