# This module provides a clean API for audit and security operations.
# It wraps the auto-generated database context functions with a cleaner interface.

defmodule KeenAuthPermissions.Audit do
  @moduledoc """
  Clean facade API for audit trail and security event operations.

  Provides functions for querying user audit trails, security events,
  and purging old audit data.

  ## Examples

      # Get audit trail for a user
      KeenAuthPermissions.Audit.get_user_audit_trail(ctx, target_user_id, from, to, 1, 50)

      # Get security events
      KeenAuthPermissions.Audit.get_security_events(ctx, from, to, 1, 50)

      # Purge old audit data
      KeenAuthPermissions.Audit.purge(ctx, 365)
  """

  alias KeenAuthPermissions.User
  alias KeenAuthPermissions.RequestContext
  alias KeenAuthPermissions.Error.ErrorParsers

  defp db_context(), do: KeenAuthPermissions.DbContext.get_global_db_context()

  # ============================================================================
  # Audit Trail Queries
  # ============================================================================

  @doc """
  Gets a unified paginated audit trail for a target user.

  Combines journal entries and user events into a single timeline.

  Calls `auth.get_user_audit_trail`.
  """
  @spec get_user_audit_trail(
          RequestContext.t(),
          integer(),
          DateTime.t() | nil,
          DateTime.t() | nil,
          integer(),
          integer()
        ) :: {:ok, list()} | {:error, any()}
  def get_user_audit_trail(
        %RequestContext{user: %User{user_id: user_id}, request_id: request_id},
        target_user_id,
        from \\ nil,
        to \\ nil,
        page \\ 1,
        page_size \\ 50,
        tenant_id \\ 1,
        target_tenant_id \\ nil
      ) do
    db_context().auth_get_user_audit_trail(
      user_id,
      request_id,
      target_user_id,
      from,
      to,
      page,
      page_size,
      tenant_id,
      target_tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Gets paginated security-relevant events.

  Returns events such as failed logins, lockouts, disables, and permission denials.

  Calls `auth.get_security_events`.
  """
  @spec get_security_events(
          RequestContext.t(),
          DateTime.t() | nil,
          DateTime.t() | nil,
          integer(),
          integer()
        ) :: {:ok, list()} | {:error, any()}
  def get_security_events(
        %RequestContext{user: %User{user_id: user_id}, request_id: request_id},
        from \\ nil,
        to \\ nil,
        page \\ 1,
        page_size \\ 50,
        tenant_id \\ 1,
        target_tenant_id \\ nil
      ) do
    db_context().auth_get_security_events(
      user_id,
      request_id,
      from,
      to,
      page,
      page_size,
      tenant_id,
      target_tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  # ============================================================================
  # Search Operations
  # ============================================================================

  @doc """
  Searches user events with filters.

  Supports filtering by event type, target user, request context criteria (e.g. IP, user agent),
  and date range.

  The `request_context_criteria` parameter is a map/list used to filter events by their
  stored request context fields (ip, user_agent, origin, etc.).

  Calls `auth.search_user_events`.
  """
  @spec search_user_events(
          RequestContext.t(),
          String.t() | nil,
          integer() | nil,
          map() | nil,
          DateTime.t() | nil,
          DateTime.t() | nil,
          integer(),
          integer()
        ) :: {:ok, list()} | {:error, any()}
  def search_user_events(
        %RequestContext{user: %User{user_id: user_id}, request_id: request_id},
        event_type_code \\ nil,
        target_user_id \\ nil,
        request_context_criteria \\ nil,
        from \\ nil,
        to \\ nil,
        page \\ 1,
        page_size \\ 50,
        tenant_id \\ 1,
        target_tenant_id \\ nil
      ) do
    db_context().auth_search_user_events(
      user_id,
      request_id,
      event_type_code,
      target_user_id,
      request_context_criteria,
      from,
      to,
      page,
      page_size,
      tenant_id,
      target_tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Searches journal entries with filters.

  Supports filtering by text, target user, event, category, key/payload/request context criteria,
  and date range.

  The `request_context_criteria` parameter is a map/list used to filter journal entries by their
  stored request context fields (ip, user_agent, origin, etc.).

  Calls `public.search_journal`.
  """
  @spec search_journal(
          RequestContext.t(),
          String.t() | nil,
          DateTime.t() | nil,
          DateTime.t() | nil,
          integer() | nil,
          integer() | nil,
          String.t() | nil,
          map() | nil,
          map() | nil,
          map() | nil,
          integer(),
          integer(),
          integer()
        ) :: {:ok, list()} | {:error, any()}
  def search_journal(
        %RequestContext{user: %User{user_id: user_id}, request_id: request_id},
        search_text \\ nil,
        from \\ nil,
        to \\ nil,
        target_user_id \\ nil,
        event_id \\ nil,
        event_category \\ nil,
        keys_criteria \\ nil,
        payload_criteria \\ nil,
        request_context_criteria \\ nil,
        page \\ 1,
        page_size \\ 50,
        tenant_id
      ) do
    db_context().search_journal(
      user_id,
      request_id,
      search_text,
      from,
      to,
      target_user_id,
      event_id,
      event_category,
      keys_criteria,
      payload_criteria,
      request_context_criteria,
      page,
      page_size,
      tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  # ============================================================================
  # Audit Data Maintenance
  # ============================================================================

  @doc """
  Purges journal entries and user events older than the specified number of days.

  Calls `public.purge_audit_data`.

  Returns the count of deleted journal entries and user events.
  """
  @spec purge(RequestContext.t(), integer()) :: {:ok, map()} | {:error, any()}
  def purge(
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id},
        older_than_days
      ) do
    case db_context().purge_audit_data(
           username,
           user_id,
           request_id,
           older_than_days
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :purge_failed}
      error -> error
    end
  end
end
