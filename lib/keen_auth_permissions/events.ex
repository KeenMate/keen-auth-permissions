defmodule KeenAuthPermissions.Events do
  @moduledoc """
  Facade for application-defined audit event types.

  The permissions model seeds core events in the id range **10000–39999**.
  Application modules own the range **50000+** and register their own event
  categories, codes, and message templates here. Once registered, journal
  entries with those event ids render with the same machinery as core events.

  ## Why three concepts?

  - **Category** — a named range of event ids a module owns (e.g. `"order_event"`
    for ids 50001–50999). Categories prevent id collisions between modules.
  - **Code** — the individual event type (e.g. `50001 / "order_placed"`).
    Must fall inside a registered category's range.
  - **Message** — a per-language template rendered at display time using values
    from the journal payload (e.g. `"Order {order_id} placed by {actor}"`).

  ## End-to-end example

      # 1. Register the category your module owns
      Events.create_category(ctx, "order_event", "Order Events", 50001, 50999)

      # 2. Register event codes inside that range
      Events.create_code(ctx, 50001, "order_placed", "order_event", "Order Placed",
        description: "A new order was placed")

      Events.create_code(ctx, 50002, "order_cancelled", "order_event", "Order Cancelled")

      # 3. Register message templates
      Events.create_message(ctx, 50001, "Order {order_id} placed by {actor} for {amount}")
      Events.create_message(ctx, 50002, "Order {order_id} cancelled by {actor}: {reason}",
        language_code: "en")

      # Now `Journal.create_by_code(ctx, "order_placed", keys, payload, tenant_id)`
      # produces audit entries that render with the template above.

  ## Deletion

  Core system events (is_system = true) are protected and cannot be deleted.
  Use the `delete_*` functions for cleanup on uninstall or migration of your own
  event definitions.
  """

  alias KeenAuthPermissions.User
  alias KeenAuthPermissions.RequestContext
  alias KeenAuthPermissions.Error.ErrorParsers

  defp db_context(), do: KeenAuthPermissions.DbContext.get_global_db_context()

  # ============================================================================
  # Categories
  # ============================================================================

  @doc """
  Registers an event category owning a numeric id range.

  Options:
    * `:is_error` — defaults to `false`; marks the category as carrying errors
    * `:source` — free-form string identifying the module that owns the category

  Calls `public.create_event_category`.
  """
  @spec create_category(
          RequestContext.t(),
          String.t(),
          String.t(),
          integer(),
          integer(),
          keyword()
        ) :: {:ok, map()} | {:error, any()}
  def create_category(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        category_code,
        title,
        range_start,
        range_end,
        opts \\ []
      ) do
    is_error = Keyword.get(opts, :is_error, false)
    source = Keyword.get(opts, :source)

    case db_context().create_event_category(
           username,
           user_id,
           request_id,
           category_code,
           title,
           range_start,
           range_end,
           is_error,
           source
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :creation_failed}
      error -> error
    end
  end

  @doc """
  Deletes an event category. Fails on core/system categories.

  Calls `public.delete_event_category`.
  """
  @spec delete_category(RequestContext.t(), String.t()) :: :ok | {:error, any()}
  def delete_category(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        category_code
      ) do
    db_context().delete_event_category(username, user_id, request_id, category_code)
  end

  # ============================================================================
  # Codes
  # ============================================================================

  @doc """
  Registers an individual event code. `event_id` must fall inside the range of
  the named `category_code`.

  Options:
    * `:description`
    * `:is_read_only` — defaults to `false`
    * `:source` — module tag used for later bulk cleanup

  Calls `public.create_event_code`.
  """
  @spec create_code(
          RequestContext.t(),
          integer(),
          String.t(),
          String.t(),
          String.t(),
          keyword()
        ) :: {:ok, map()} | {:error, any()}
  def create_code(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        event_id,
        code,
        category_code,
        title,
        opts \\ []
      ) do
    description = Keyword.get(opts, :description)
    is_read_only = Keyword.get(opts, :is_read_only, false)
    source = Keyword.get(opts, :source)

    case db_context().create_event_code(
           username,
           user_id,
           request_id,
           event_id,
           code,
           category_code,
           title,
           description,
           is_read_only,
           source
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :creation_failed}
      error -> error
    end
  end

  @doc """
  Deletes an event code. Fails on system codes.

  Calls `public.delete_event_code`.
  """
  @spec delete_code(RequestContext.t(), integer()) :: :ok | {:error, any()}
  def delete_code(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        event_id
      ) do
    db_context().delete_event_code(username, user_id, request_id, event_id)
  end

  # ============================================================================
  # Messages (templates)
  # ============================================================================

  @doc """
  Registers a message template for an event in a given language.

  Templates use `{var}` placeholders that get resolved against the journal
  entry's payload at render time.

  Options:
    * `:language_code` — defaults to `"en"`

  Calls `public.create_event_message`.
  """
  @spec create_message(RequestContext.t(), integer(), String.t(), keyword()) ::
          {:ok, map()} | {:error, any()}
  def create_message(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        event_id,
        message_template,
        opts \\ []
      ) do
    language_code = Keyword.get(opts, :language_code, "en")

    case db_context().create_event_message(
           username,
           user_id,
           request_id,
           event_id,
           message_template,
           language_code
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :creation_failed}
      error -> error
    end
  end

  @doc """
  Deletes a message template by its id.

  Calls `public.delete_event_message`.
  """
  @spec delete_message(RequestContext.t(), integer()) :: :ok | {:error, any()}
  def delete_message(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        event_message_id
      ) do
    db_context().delete_event_message(username, user_id, request_id, event_message_id)
  end

  @doc """
  Returns the message template registered for `event_id` in `language_code`.

  Calls `public.get_event_message_template`.
  """
  @spec get_message_template(integer(), String.t()) ::
          {:ok, String.t()} | {:error, any()}
  def get_message_template(event_id, language_code \\ "en") do
    case db_context().get_event_message_template(event_id, language_code)
         |> ErrorParsers.parse_if_error() do
      # SP returns a single row with a nil scalar when no template exists.
      {:ok, [%{get_event_message_template: nil}]} -> {:error, :not_found}
      {:ok, [%{get_event_message_template: tpl}]} -> {:ok, tpl}
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :not_found}
      error -> error
    end
  end
end
