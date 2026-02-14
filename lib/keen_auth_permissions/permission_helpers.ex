defmodule KeenAuthPermissions.PermissionHelpers do
  @moduledoc """
  Pure helper functions for in-memory permission checking.

  These functions check the `permissions` and `groups` fields on User struct directly,
  avoiding database calls when permissions are pre-loaded.

  ## Boolean Checks

  Use these for simple conditionals:

      if PermissionHelpers.has_any?(user, ["admin.read", "super.admin"]) do
        show_admin_panel()
      end

  ## Result-Based Checks

  Use these in `with` blocks:

      with {:ok, :authorized} <- PermissionHelpers.require_all(ctx, ["users.read", "users.write"]),
           {:ok, user} <- Users.get_by_id(user_id) do
        {:ok, user}
      end

  ## Execution Helpers

  Use these to wrap function calls:

      PermissionHelpers.with_permission(ctx, ["tenants.delete"], fn ->
        Tenants.delete(ctx, tenant_id)
      end)
  """

  alias KeenAuthPermissions.User
  alias KeenAuthPermissions.RequestContext
  alias KeenAuthPermissions.Error.ErrorStruct

  # ============================================================================
  # Boolean Checks (for conditionals)
  # ============================================================================

  @doc """
  Checks if user has ANY of the specified permissions.

  ## Examples

      iex> user = %User{permissions: ["admin.read", "users.list"], ...}
      iex> PermissionHelpers.has_any?(user, ["admin.read", "admin.write"])
      true

      iex> PermissionHelpers.has_any?(user, "admin.read")
      true

      iex> PermissionHelpers.has_any?(user, ["admin.write", "admin.delete"])
      false
  """
  @spec has_any?(User.t() | RequestContext.t(), list(String.t()) | String.t()) :: boolean()
  def has_any?(%RequestContext{user: user}, required), do: has_any?(user, required)

  def has_any?(%User{permissions: perms}, required) when is_list(required) do
    Enum.any?(required, &(&1 in perms))
  end

  def has_any?(%User{permissions: perms}, required) when is_binary(required) do
    required in perms
  end

  @doc """
  Checks if user has ALL of the specified permissions.

  ## Examples

      iex> user = %User{permissions: ["admin.read", "users.list"], ...}
      iex> PermissionHelpers.has_all?(user, ["admin.read", "users.list"])
      true

      iex> PermissionHelpers.has_all?(user, ["admin.read", "admin.write"])
      false
  """
  @spec has_all?(User.t() | RequestContext.t(), list(String.t())) :: boolean()
  def has_all?(%RequestContext{user: user}, required), do: has_all?(user, required)

  def has_all?(%User{permissions: perms}, required) when is_list(required) do
    Enum.all?(required, &(&1 in perms))
  end

  @doc """
  Checks if user is in ANY of the specified groups.

  ## Examples

      iex> user = %User{groups: ["admins", "users"], ...}
      iex> PermissionHelpers.in_any_group?(user, ["admins", "moderators"])
      true

      iex> PermissionHelpers.in_any_group?(user, ["moderators", "guests"])
      false
  """
  @spec in_any_group?(User.t() | RequestContext.t(), list(String.t())) :: boolean()
  def in_any_group?(%RequestContext{user: user}, groups), do: in_any_group?(user, groups)

  def in_any_group?(%User{groups: user_groups}, required) when is_list(required) do
    Enum.any?(required, &(&1 in user_groups))
  end

  @doc """
  Checks if user is in ALL of the specified groups.

  ## Examples

      iex> user = %User{groups: ["admins", "users"], ...}
      iex> PermissionHelpers.in_all_groups?(user, ["admins", "users"])
      true

      iex> PermissionHelpers.in_all_groups?(user, ["admins", "moderators"])
      false
  """
  @spec in_all_groups?(User.t() | RequestContext.t(), list(String.t())) :: boolean()
  def in_all_groups?(%RequestContext{user: user}, groups), do: in_all_groups?(user, groups)

  def in_all_groups?(%User{groups: user_groups}, required) when is_list(required) do
    Enum.all?(required, &(&1 in user_groups))
  end

  # ============================================================================
  # Result-Based Checks (for with blocks)
  # ============================================================================

  @doc """
  Returns `{:ok, :authorized}` if user has ANY of the required permissions,
  otherwise `{:error, ErrorStruct}`.

  Use in `with` blocks:

      with {:ok, :authorized} <- require_any(ctx, ["admin.read"]),
           {:ok, data} <- fetch_data(ctx) do
        {:ok, data}
      end

  ## Examples

      iex> user = %User{permissions: ["admin.read"], ...}
      iex> PermissionHelpers.require_any(user, ["admin.read", "admin.write"])
      {:ok, :authorized}

      iex> PermissionHelpers.require_any(user, ["admin.write"])
      {:error, %ErrorStruct{reason: :no_permission, ...}}
  """
  @spec require_any(User.t() | RequestContext.t(), list(String.t()) | String.t()) ::
          {:ok, :authorized} | {:error, ErrorStruct.t()}
  def require_any(user_or_ctx, required) do
    if has_any?(user_or_ctx, required) do
      {:ok, :authorized}
    else
      {:error,
       %ErrorStruct{
         reason: :no_permission,
         message: "Missing required permission",
         metadata: %{required: List.wrap(required), mode: :any}
       }}
    end
  end

  @doc """
  Returns `{:ok, :authorized}` if user has ALL of the required permissions,
  otherwise `{:error, ErrorStruct}`.

  The error includes a `missing` field listing which permissions are missing.

  ## Examples

      iex> user = %User{permissions: ["admin.read", "users.list"], ...}
      iex> PermissionHelpers.require_all(user, ["admin.read", "users.list"])
      {:ok, :authorized}

      iex> PermissionHelpers.require_all(user, ["admin.read", "admin.write"])
      {:error, %ErrorStruct{reason: :no_permission, metadata: %{missing: ["admin.write"], ...}}}
  """
  @spec require_all(User.t() | RequestContext.t(), list(String.t())) ::
          {:ok, :authorized} | {:error, ErrorStruct.t()}
  def require_all(user_or_ctx, required) do
    if has_all?(user_or_ctx, required) do
      {:ok, :authorized}
    else
      {:error,
       %ErrorStruct{
         reason: :no_permission,
         message: "Missing required permissions",
         metadata: %{required: required, missing: find_missing(user_or_ctx, required), mode: :all}
       }}
    end
  end

  @doc """
  Returns `{:ok, :authorized}` if user is in ANY of the required groups,
  otherwise `{:error, ErrorStruct}`.

  ## Examples

      iex> user = %User{groups: ["admins"], ...}
      iex> PermissionHelpers.require_any_group(user, ["admins", "moderators"])
      {:ok, :authorized}

      iex> PermissionHelpers.require_any_group(user, ["moderators", "guests"])
      {:error, %ErrorStruct{reason: :no_permission, ...}}
  """
  @spec require_any_group(User.t() | RequestContext.t(), list(String.t())) ::
          {:ok, :authorized} | {:error, ErrorStruct.t()}
  def require_any_group(user_or_ctx, required) do
    if in_any_group?(user_or_ctx, required) do
      {:ok, :authorized}
    else
      {:error,
       %ErrorStruct{
         reason: :no_permission,
         message: "Not in any required group",
         metadata: %{required_groups: required, mode: :any}
       }}
    end
  end

  @doc """
  Returns `{:ok, :authorized}` if user is in ALL of the required groups,
  otherwise `{:error, ErrorStruct}`.

  ## Examples

      iex> user = %User{groups: ["admins", "users"], ...}
      iex> PermissionHelpers.require_all_groups(user, ["admins", "users"])
      {:ok, :authorized}

      iex> PermissionHelpers.require_all_groups(user, ["admins", "moderators"])
      {:error, %ErrorStruct{reason: :no_permission, ...}}
  """
  @spec require_all_groups(User.t() | RequestContext.t(), list(String.t())) ::
          {:ok, :authorized} | {:error, ErrorStruct.t()}
  def require_all_groups(user_or_ctx, required) do
    if in_all_groups?(user_or_ctx, required) do
      {:ok, :authorized}
    else
      {:error,
       %ErrorStruct{
         reason: :no_permission,
         message: "Not in all required groups",
         metadata: %{
           required_groups: required,
           missing_groups: find_missing_groups(user_or_ctx, required),
           mode: :all
         }
       }}
    end
  end

  # ============================================================================
  # Execution Helpers (for wrapping function calls)
  # ============================================================================

  @doc """
  Executes function only if user has ANY of the required permissions.

  ## Examples

      PermissionHelpers.with_permission(ctx, ["admin.read"], fn ->
        fetch_admin_data(ctx)
      end)

      # With single permission
      PermissionHelpers.with_permission(ctx, "admin.read", fn ->
        fetch_admin_data(ctx)
      end)
  """
  @spec with_permission(User.t() | RequestContext.t(), list(String.t()) | String.t(), (-> any())) ::
          any() | {:error, ErrorStruct.t()}
  def with_permission(user_or_ctx, required, fun) when is_function(fun, 0) do
    case require_any(user_or_ctx, required) do
      {:ok, :authorized} -> fun.()
      error -> error
    end
  end

  @doc """
  Executes function only if user has ALL of the required permissions.

  ## Examples

      PermissionHelpers.with_all_permissions(ctx, ["users.read", "users.write"], fn ->
        update_user(ctx, user_id, changes)
      end)
  """
  @spec with_all_permissions(User.t() | RequestContext.t(), list(String.t()), (-> any())) ::
          any() | {:error, ErrorStruct.t()}
  def with_all_permissions(user_or_ctx, required, fun) when is_function(fun, 0) do
    case require_all(user_or_ctx, required) do
      {:ok, :authorized} -> fun.()
      error -> error
    end
  end

  @doc """
  Executes function only if user is in ANY of the required groups.

  ## Examples

      PermissionHelpers.with_group(ctx, ["admins", "moderators"], fn ->
        show_moderation_tools(ctx)
      end)
  """
  @spec with_group(User.t() | RequestContext.t(), list(String.t()), (-> any())) ::
          any() | {:error, ErrorStruct.t()}
  def with_group(user_or_ctx, required, fun) when is_function(fun, 0) do
    case require_any_group(user_or_ctx, required) do
      {:ok, :authorized} -> fun.()
      error -> error
    end
  end

  # ============================================================================
  # Utility Functions
  # ============================================================================

  @doc """
  Returns list of missing permissions.

  ## Examples

      iex> user = %User{permissions: ["admin.read"], ...}
      iex> PermissionHelpers.find_missing(user, ["admin.read", "admin.write", "admin.delete"])
      ["admin.write", "admin.delete"]
  """
  @spec find_missing(User.t() | RequestContext.t(), list(String.t())) :: list(String.t())
  def find_missing(%RequestContext{user: user}, required), do: find_missing(user, required)

  def find_missing(%User{permissions: perms}, required) when is_list(required) do
    Enum.reject(required, &(&1 in perms))
  end

  @doc """
  Returns list of missing groups.

  ## Examples

      iex> user = %User{groups: ["admins"], ...}
      iex> PermissionHelpers.find_missing_groups(user, ["admins", "moderators"])
      ["moderators"]
  """
  @spec find_missing_groups(User.t() | RequestContext.t(), list(String.t())) :: list(String.t())
  def find_missing_groups(%RequestContext{user: user}, required),
    do: find_missing_groups(user, required)

  def find_missing_groups(%User{groups: user_groups}, required) when is_list(required) do
    Enum.reject(required, &(&1 in user_groups))
  end
end
