defmodule KeenAuthPermissions.PgListener.Resolver do
  @moduledoc """
  Resolves affected user IDs from notification payloads based on `target_type`.

  ## Resolution strategies

  | target_type  | Resolution                              | Delete fallback          |
  |:-------------|:----------------------------------------|:-------------------------|
  | `"user"`     | Direct from `target_id`                 | same                     |
  | `"group"`    | Query `notify_group_users` view         | MembershipCache          |
  | `"perm_set"` | Query `notify_perm_set_users` view      | N/A                      |
  | `"system"`   | Query `notify_permission_users` view    | N/A                      |
  | `"provider"` | Query `notify_provider_users` view      | MembershipCache          |
  | `"tenant"`   | Query `notify_tenant_users` view        | MembershipCache          |
  | `"api_key"`  | Service-level (returns `[]`)            | same                     |

  For DELETE events on groups/providers/tenants, the database rows have already
  been cascaded away by the time pg_notify fires (after COMMIT). In those cases,
  we fall back to the in-memory `MembershipCache`.
  """

  require Logger

  alias KeenAuth.SSE.MembershipCache

  @doc """
  Resolves the list of user IDs that should receive a notification.

  Returns `{:ok, [user_id]}` or `{:error, reason}`.
  """
  @spec resolve(map()) :: {:ok, [integer()]} | {:error, term()}
  def resolve(%{"target_type" => target_type, "event" => event} = payload) do
    is_delete = String.ends_with?(event, "_deleted")
    target_id = payload["target_id"]
    tenant_id = payload["tenant_id"]
    detail = payload["detail"] || %{}

    resolve_by_type(target_type, target_id, tenant_id, detail, is_delete)
  end

  def resolve(payload) do
    Logger.warning("Resolver: invalid payload format: #{inspect(payload)}")
    {:ok, []}
  end

  # ---- Direct user targeting ----

  defp resolve_by_type("user", target_id, _tenant_id, _detail, _is_delete)
       when is_integer(target_id) do
    {:ok, [target_id]}
  end

  # ---- Group targeting ----

  defp resolve_by_type("group", group_id, _tenant_id, _detail, true = _is_delete) do
    # DELETE — data gone from DB, use in-memory cache
    {:ok, MembershipCache.users_in_group(group_id)}
  end

  defp resolve_by_type("group", group_id, tenant_id, _detail, _is_delete)
       when is_integer(group_id) and is_integer(tenant_id) do
    query_group_users(group_id, tenant_id)
  end

  # ---- Permission set targeting ----

  defp resolve_by_type("perm_set", perm_set_id, tenant_id, _detail, _is_delete)
       when is_integer(perm_set_id) and is_integer(tenant_id) do
    query_perm_set_users(perm_set_id, tenant_id)
  end

  # ---- System-level (permission tree changes) ----

  defp resolve_by_type("system", permission_id, _tenant_id, _detail, _is_delete)
       when is_integer(permission_id) do
    query_permission_users(permission_id)
  end

  # ---- Provider targeting ----

  defp resolve_by_type("provider", _target_id, _tenant_id, %{"provider_code" => code}, true) do
    # DELETE — data gone from DB, use in-memory cache
    {:ok, MembershipCache.users_with_provider(code)}
  end

  defp resolve_by_type("provider", _target_id, _tenant_id, %{"provider_code" => code}, _is_delete) do
    query_provider_users(code)
  end

  # ---- Tenant targeting ----

  defp resolve_by_type("tenant", tenant_id, _payload_tenant_id, _detail, true) do
    # DELETE — data gone from DB, use in-memory cache
    {:ok, MembershipCache.users_in_tenant(tenant_id)}
  end

  defp resolve_by_type("tenant", tenant_id, _payload_tenant_id, _detail, _is_delete)
       when is_integer(tenant_id) do
    query_tenant_users(tenant_id)
  end

  # ---- API key (service-level, no user routing) ----

  defp resolve_by_type("api_key", _target_id, _tenant_id, _detail, _is_delete) do
    {:ok, []}
  end

  # ---- Catch-all ----

  defp resolve_by_type(target_type, target_id, tenant_id, _detail, _is_delete) do
    Logger.warning(
      "Resolver: unknown target_type=#{inspect(target_type)} target_id=#{inspect(target_id)} tenant_id=#{inspect(tenant_id)}"
    )

    {:ok, []}
  end

  # ============================================================================
  # Database Queries
  # ============================================================================

  defp repo do
    config = Application.get_env(:keen_auth_permissions, :pg_listener, [])
    Keyword.get(config, :repo)
  end

  defp query_group_users(group_id, tenant_id) do
    run_query(
      "SELECT user_id FROM auth.notify_group_users WHERE user_group_id = $1 AND tenant_id = $2",
      [group_id, tenant_id]
    )
  end

  defp query_perm_set_users(perm_set_id, tenant_id) do
    run_query(
      "SELECT user_id FROM auth.notify_perm_set_users WHERE perm_set_id = $1 AND tenant_id = $2",
      [perm_set_id, tenant_id]
    )
  end

  defp query_permission_users(permission_id) do
    run_query(
      "SELECT user_id FROM auth.notify_permission_users WHERE permission_id = $1",
      [permission_id]
    )
  end

  defp query_provider_users(provider_code) do
    run_query(
      "SELECT user_id FROM auth.notify_provider_users WHERE provider_code = $1",
      [provider_code]
    )
  end

  defp query_tenant_users(tenant_id) do
    run_query(
      "SELECT user_id FROM auth.notify_tenant_users WHERE tenant_id = $1",
      [tenant_id]
    )
  end

  defp run_query(sql, params) do
    case repo() do
      nil ->
        Logger.warning("Resolver: no repo configured for pg_listener")
        {:ok, []}

      repo ->
        case repo.query(sql, params) do
          {:ok, %{rows: rows}} ->
            {:ok, Enum.map(rows, fn [user_id] -> user_id end)}

          {:error, %Postgrex.Error{postgres: %{code: :undefined_table}} = _err} ->
            Logger.warning("Resolver: view not found for query: #{sql}")
            {:ok, []}

          {:error, reason} ->
            Logger.error("Resolver: query failed: #{inspect(reason)}")
            {:error, reason}
        end
    end
  end
end
