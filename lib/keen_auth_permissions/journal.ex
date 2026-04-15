defmodule KeenAuthPermissions.Journal do
  @moduledoc """
  Facade for the journal — a structured audit log of domain events.

  The journal is the right place for **backend-only events** that the database
  itself doesn't raise (e.g. a batch import finished, an outbound email was sent,
  a third-party webhook was received). DB-originating events are already written
  by the stored procedures; this facade is for everything else.

  ## When to use which `create_*`

  | Function | Use when | Notes |
  |---|---|---|
  | `create/6` | Application knows the numeric `event_id` | Fastest path, no code→id lookup |
  | `create_by_code/6` | Application knows only the `event_code` text | Convenient, one lookup step |
  | `create_for_entity/7` | Event concerns a specific entity (user, tenant, group, ...) | Builds keys from entity_type+entity_id |
  | `create_for_entity_by_code/7` | Same, but by event code | |

  ## Searching

  Use `search/12` for paged lookups, `get/3` for a single entry, and `get_payload/3`
  for the heavier payload blob (kept on a separate call so list views stay lean).

  For the unified user-centric audit trail (journal + user_events combined), prefer
  `KeenAuthPermissions.Audit` — this module exposes the raw journal only.
  """

  alias KeenAuthPermissions.User
  alias KeenAuthPermissions.RequestContext
  alias KeenAuthPermissions.Error.ErrorParsers

  defp db_context(), do: KeenAuthPermissions.DbContext.get_global_db_context()

  # ============================================================================
  # Create
  # ============================================================================

  @doc """
  Creates a journal entry using a numeric event_id.

  `keys` is a JSONB map tagging the entry with arbitrary identifiers (e.g.
  `%{"user" => 42, "order" => 1001}`). `payload` is the structured event data.

  Calls `public.create_journal_message`.
  """
  @spec create(RequestContext.t(), integer(), map(), map(), integer()) ::
          {:ok, map()} | {:error, any()}
  def create(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        } = ctx,
        event_id,
        keys,
        payload,
        tenant_id
      ) do
    case db_context().create_journal_message(
           username,
           user_id,
           request_id,
           event_id,
           keys,
           payload,
           tenant_id,
           RequestContext.to_context_map(ctx)
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :creation_failed}
      error -> error
    end
  end

  @doc """
  Creates a journal entry using an event `code` (string) instead of a numeric id.

  Calls `public.create_journal_message_by_code`.
  """
  @spec create_by_code(RequestContext.t(), String.t(), map(), map(), integer()) ::
          {:ok, map()} | {:error, any()}
  def create_by_code(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        } = ctx,
        event_code,
        keys,
        payload,
        tenant_id
      ) do
    case db_context().create_journal_message_by_code(
           username,
           user_id,
           request_id,
           event_code,
           keys,
           payload,
           tenant_id,
           RequestContext.to_context_map(ctx)
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :creation_failed}
      error -> error
    end
  end

  @doc """
  Creates a journal entry tied to a specific entity (e.g. `"user"` + `user_id`).

  The `entity_type` + `entity_id` pair is stored as a journal key automatically;
  no need to build the keys map by hand.

  Calls `public.create_journal_message_for_entity`.
  """
  @spec create_for_entity(
          RequestContext.t(),
          integer(),
          String.t(),
          integer(),
          map(),
          integer()
        ) :: {:ok, map()} | {:error, any()}
  def create_for_entity(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        } = ctx,
        event_id,
        entity_type,
        entity_id,
        payload,
        tenant_id
      ) do
    case db_context().create_journal_message_for_entity(
           username,
           user_id,
           request_id,
           event_id,
           entity_type,
           entity_id,
           payload,
           tenant_id,
           RequestContext.to_context_map(ctx)
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :creation_failed}
      error -> error
    end
  end

  @doc """
  Creates a journal entry tied to a specific entity, using an event code.

  Calls `public.create_journal_message_for_entity_by_code`.
  """
  @spec create_for_entity_by_code(
          RequestContext.t(),
          String.t(),
          String.t(),
          integer(),
          map(),
          integer()
        ) :: {:ok, map()} | {:error, any()}
  def create_for_entity_by_code(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        } = ctx,
        event_code,
        entity_type,
        entity_id,
        payload,
        tenant_id
      ) do
    case db_context().create_journal_message_for_entity_by_code(
           username,
           user_id,
           request_id,
           event_code,
           entity_type,
           entity_id,
           payload,
           tenant_id,
           RequestContext.to_context_map(ctx)
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :creation_failed}
      error -> error
    end
  end

  # ============================================================================
  # Query
  # ============================================================================

  @doc """
  Searches journal entries with optional filters.

  All filter parameters are optional — pass `nil` to skip. `payload_criteria`
  is a JSONB map of key/value matches applied to the payload column.

  Calls `public.search_journal_msgs`.
  """
  @spec search(
          RequestContext.t(),
          String.t() | nil,
          DateTime.t() | nil,
          DateTime.t() | nil,
          integer() | nil,
          integer() | nil,
          String.t() | nil,
          integer() | nil,
          String.t() | nil,
          map() | nil,
          integer(),
          integer(),
          integer()
        ) :: {:ok, list(map())} | {:error, any()}
  def search(
        %RequestContext{user: %User{user_id: user_id}, request_id: request_id},
        search_text \\ nil,
        from \\ nil,
        to \\ nil,
        target_user_id \\ nil,
        event_id \\ nil,
        data_group \\ nil,
        data_object_id \\ nil,
        data_object_code \\ nil,
        payload_criteria \\ nil,
        page \\ 1,
        page_size \\ 50,
        tenant_id
      ) do
    db_context().search_journal_msgs(
      user_id,
      request_id,
      search_text,
      from,
      to,
      target_user_id,
      event_id,
      data_group,
      data_object_id,
      data_object_code,
      payload_criteria,
      page,
      page_size,
      tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Returns a single journal entry by id.

  Calls `public.get_journal_entry`.
  """
  @spec get(RequestContext.t(), integer(), integer()) :: {:ok, map()} | {:error, any()}
  def get(
        %RequestContext{user: %User{user_id: user_id}, request_id: request_id},
        journal_id,
        tenant_id
      ) do
    case db_context().get_journal_entry(user_id, request_id, tenant_id, journal_id)
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :not_found}
      error -> error
    end
  end

  @doc """
  Returns the payload blob of a single journal entry.

  Kept on its own call so list views can stay lean and only load payloads on demand.

  Calls `public.get_journal_payload`.
  """
  @spec get_payload(RequestContext.t(), integer(), integer()) :: {:ok, any()} | {:error, any()}
  def get_payload(
        %RequestContext{user: %User{user_id: user_id}, request_id: request_id},
        journal_id,
        tenant_id
      ) do
    case db_context().get_journal_payload(user_id, request_id, tenant_id, journal_id)
         |> ErrorParsers.parse_if_error() do
      {:ok, [%{get_journal_payload: payload}]} -> {:ok, payload}
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :not_found}
      error -> error
    end
  end

  # ============================================================================
  # Helpers
  # ============================================================================

  @doc """
  Renders a message template against a payload, server-side.

  Useful when the application wants the same formatted string the journal viewer
  would show (variable substitution, formatting rules live in the DB).

  Calls `public.format_journal_message`.
  """
  @spec format_message(String.t(), map(), String.t()) :: {:ok, String.t()} | {:error, any()}
  def format_message(template, payload, created_by \\ "system") do
    case db_context().format_journal_message(template, payload, created_by)
         |> ErrorParsers.parse_if_error() do
      {:ok, [%{format_journal_message: text}]} -> {:ok, text}
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :format_failed}
      error -> error
    end
  end

end
# Note: `public.journal_keys` takes a VARIADIC text[] and isn't callable through
# the generated db_context (Postgrex can't spread a variadic without an explicit
# cast). In practice the same JSONB can be built directly in Elixir:
#
#     ["user", "42", "order", "1001"]
#     |> Enum.chunk_every(2)
#     |> Map.new(fn [k, v] -> {k, v} end)
#
# so no facade wrapper is provided for it.
