defmodule KeenAuthPermissions.Notifier do
  @moduledoc """
  Broadcasts SSE events to connected users via PubSub.

  Provides two usage paths:

  1. **Application-level** — called from facade functions after successful DB operations
  2. **PgListener** — called after resolving affected users from pg_notify payloads

  ## Configuration

      config :keen_auth_permissions,
        notifier: [
          enabled: true,
          pubsub: MyApp.PubSub
        ]

  When `enabled: false` or no PubSub is configured, all calls are no-ops.

  ## Event Categories

  ### Permission Assignment
  - `permission_assigned` / `permission_unassigned`

  ### Permission Set Content
  - `perm_set_permissions_added` / `perm_set_permissions_removed` / `perm_set_updated`

  ### Group Membership
  - `group_member_added` / `group_member_removed`

  ### Group Status
  - `group_enabled` / `group_disabled` / `group_deleted` / `group_type_changed`

  ### Group Mappings
  - `group_mapping_created` / `group_mapping_deleted`

  ### User Status
  - `user_disabled` / `user_enabled` / `user_locked` / `user_unlocked` / `user_deleted`

  ### Ownership
  - `owner_created` / `owner_deleted`

  ### Permission Tree
  - `permission_assignability_changed`

  ### Provider
  - `provider_disabled` / `provider_enabled` / `provider_deleted`

  ### Tenant
  - `tenant_deleted`

  ## Payload Format

  All events use a standardized payload:

      %{
        event: "permission_assigned",
        tenant_id: 1,
        target_type: "user",
        target_id: 42,
        detail: %{perm_set_id: 5, permission_id: 12},
        at: "2026-02-21T10:30:00Z"
      }
  """

  require Logger

  # ============================================================================
  # Generic Broadcast
  # ============================================================================

  @doc """
  Broadcasts an event to a single user.
  """
  @spec notify(integer(), String.t(), map()) :: :ok
  def notify(user_id, event, payload \\ %{}) do
    case get_pubsub() do
      nil ->
        :ok

      pubsub ->
        payload = Map.put_new(payload, :at, DateTime.utc_now() |> DateTime.to_iso8601())
        KeenAuth.SSE.Broadcaster.broadcast(pubsub, user_id, event, payload)
    end
  end

  @doc """
  Broadcasts an event to multiple users.
  """
  @spec notify_many([integer()], String.t(), map()) :: :ok
  def notify_many(user_ids, event, payload \\ %{}) do
    case get_pubsub() do
      nil ->
        :ok

      pubsub ->
        payload = Map.put_new(payload, :at, DateTime.utc_now() |> DateTime.to_iso8601())
        KeenAuth.SSE.Broadcaster.broadcast_many(pubsub, user_ids, event, payload)
    end
  end

  # ============================================================================
  # Permission Assignment Events
  # ============================================================================

  @doc "Permission assigned to a user."
  def permission_assigned(user_id, tenant_id, detail \\ %{}) do
    notify(user_id, "permission_assigned", %{
      tenant_id: tenant_id,
      target_type: "user",
      target_id: user_id,
      detail: detail
    })
  end

  @doc "Permission unassigned from a user."
  def permission_unassigned(user_id, tenant_id, detail \\ %{}) do
    notify(user_id, "permission_unassigned", %{
      tenant_id: tenant_id,
      target_type: "user",
      target_id: user_id,
      detail: detail
    })
  end

  # ============================================================================
  # Permission Set Events
  # ============================================================================

  @doc "Permissions added to a permission set — notify all affected users."
  def perm_set_permissions_added(user_ids, tenant_id, perm_set_id, detail \\ %{}) do
    notify_many(user_ids, "perm_set_permissions_added", %{
      tenant_id: tenant_id,
      target_type: "perm_set",
      target_id: perm_set_id,
      detail: detail
    })
  end

  @doc "Permissions removed from a permission set — notify all affected users."
  def perm_set_permissions_removed(user_ids, tenant_id, perm_set_id, detail \\ %{}) do
    notify_many(user_ids, "perm_set_permissions_removed", %{
      tenant_id: tenant_id,
      target_type: "perm_set",
      target_id: perm_set_id,
      detail: detail
    })
  end

  @doc "Permission set updated — notify all affected users."
  def perm_set_updated(user_ids, tenant_id, perm_set_id, detail \\ %{}) do
    notify_many(user_ids, "perm_set_updated", %{
      tenant_id: tenant_id,
      target_type: "perm_set",
      target_id: perm_set_id,
      detail: detail
    })
  end

  # ============================================================================
  # Group Membership Events
  # ============================================================================

  @doc "User added to a group."
  def group_member_added(user_id, tenant_id, group_id) do
    notify(user_id, "group_member_added", %{
      tenant_id: tenant_id,
      target_type: "user",
      target_id: user_id,
      detail: %{group_id: group_id}
    })
  end

  @doc "User removed from a group."
  def group_member_removed(user_id, tenant_id, group_id) do
    notify(user_id, "group_member_removed", %{
      tenant_id: tenant_id,
      target_type: "user",
      target_id: user_id,
      detail: %{group_id: group_id}
    })
  end

  # ============================================================================
  # Group Status Events
  # ============================================================================

  @doc "Group enabled — notify all group members."
  def group_enabled(user_ids, tenant_id, group_id) do
    notify_many(user_ids, "group_enabled", %{
      tenant_id: tenant_id,
      target_type: "group",
      target_id: group_id
    })
  end

  @doc "Group disabled — notify all group members."
  def group_disabled(user_ids, tenant_id, group_id) do
    notify_many(user_ids, "group_disabled", %{
      tenant_id: tenant_id,
      target_type: "group",
      target_id: group_id
    })
  end

  @doc "Group deleted — notify all group members."
  def group_deleted(user_ids, tenant_id, group_id) do
    notify_many(user_ids, "group_deleted", %{
      tenant_id: tenant_id,
      target_type: "group",
      target_id: group_id
    })
  end

  @doc "Group type changed (external/internal) — notify all group members."
  def group_type_changed(user_ids, tenant_id, group_id, detail \\ %{}) do
    notify_many(user_ids, "group_type_changed", %{
      tenant_id: tenant_id,
      target_type: "group",
      target_id: group_id,
      detail: detail
    })
  end

  # ============================================================================
  # Group Mapping Events
  # ============================================================================

  @doc "Group mapping created — notify all group members."
  def group_mapping_created(user_ids, tenant_id, group_id, detail \\ %{}) do
    notify_many(user_ids, "group_mapping_created", %{
      tenant_id: tenant_id,
      target_type: "group",
      target_id: group_id,
      detail: detail
    })
  end

  @doc "Group mapping deleted — notify all group members."
  def group_mapping_deleted(user_ids, tenant_id, group_id, detail \\ %{}) do
    notify_many(user_ids, "group_mapping_deleted", %{
      tenant_id: tenant_id,
      target_type: "group",
      target_id: group_id,
      detail: detail
    })
  end

  # ============================================================================
  # User Status Events
  # ============================================================================

  @doc "User account disabled."
  def user_disabled(user_id) do
    notify(user_id, "user_disabled", %{
      tenant_id: nil,
      target_type: "user",
      target_id: user_id
    })
  end

  @doc "User account enabled."
  def user_enabled(user_id) do
    notify(user_id, "user_enabled", %{
      tenant_id: nil,
      target_type: "user",
      target_id: user_id
    })
  end

  @doc "User account locked."
  def user_locked(user_id) do
    notify(user_id, "user_locked", %{
      tenant_id: nil,
      target_type: "user",
      target_id: user_id
    })
  end

  @doc "User account unlocked."
  def user_unlocked(user_id) do
    notify(user_id, "user_unlocked", %{
      tenant_id: nil,
      target_type: "user",
      target_id: user_id
    })
  end

  @doc "User account deleted."
  def user_deleted(user_id) do
    notify(user_id, "user_deleted", %{
      tenant_id: nil,
      target_type: "user",
      target_id: user_id
    })
  end

  # ============================================================================
  # Ownership Events
  # ============================================================================

  @doc "Owner created (tenant or group scope)."
  def owner_created(user_id, tenant_id, detail \\ %{}) do
    notify(user_id, "owner_created", %{
      tenant_id: tenant_id,
      target_type: "user",
      target_id: user_id,
      detail: detail
    })
  end

  @doc "Owner deleted (tenant or group scope)."
  def owner_deleted(user_id, tenant_id, detail \\ %{}) do
    notify(user_id, "owner_deleted", %{
      tenant_id: tenant_id,
      target_type: "user",
      target_id: user_id,
      detail: detail
    })
  end

  # ============================================================================
  # Permission Tree Events
  # ============================================================================

  @doc "Permission assignability changed — notify all users who have this permission."
  def permission_assignability_changed(user_ids, permission_id, detail \\ %{}) do
    notify_many(user_ids, "permission_assignability_changed", %{
      tenant_id: nil,
      target_type: "system",
      target_id: permission_id,
      detail: detail
    })
  end

  # ============================================================================
  # Provider Events
  # ============================================================================

  @doc "Provider disabled — notify all users using this provider."
  def provider_disabled(user_ids, detail \\ %{}) do
    notify_many(user_ids, "provider_disabled", %{
      tenant_id: nil,
      target_type: "provider",
      target_id: nil,
      detail: detail
    })
  end

  @doc "Provider enabled — notify all users using this provider."
  def provider_enabled(user_ids, detail \\ %{}) do
    notify_many(user_ids, "provider_enabled", %{
      tenant_id: nil,
      target_type: "provider",
      target_id: nil,
      detail: detail
    })
  end

  @doc "Provider deleted — notify all users using this provider."
  def provider_deleted(user_ids, detail \\ %{}) do
    notify_many(user_ids, "provider_deleted", %{
      tenant_id: nil,
      target_type: "provider",
      target_id: nil,
      detail: detail
    })
  end

  # ============================================================================
  # Tenant Events
  # ============================================================================

  @doc "Tenant deleted — notify all users in the tenant."
  def tenant_deleted(user_ids, tenant_id) do
    notify_many(user_ids, "tenant_deleted", %{
      tenant_id: tenant_id,
      target_type: "tenant",
      target_id: tenant_id
    })
  end

  # ============================================================================
  # Private
  # ============================================================================

  defp get_pubsub do
    config = Application.get_env(:keen_auth_permissions, :notifier, [])

    if Keyword.get(config, :enabled, true) do
      Keyword.get(config, :pubsub)
    else
      nil
    end
  end
end
