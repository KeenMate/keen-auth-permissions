defmodule KeenAuthPermissions.PgListener do
  @moduledoc """
  GenServer that listens for PostgreSQL NOTIFY events and broadcasts
  them as SSE events to connected clients via PubSub.

  Uses `Postgrex.Notifications` for a dedicated LISTEN connection
  and implements debounce logic to consolidate burst notifications
  from database triggers.

  ## Architecture

      PostgreSQL trigger → pg_notify(channel, payload)
        → PgListener receives {:notification, ...}
        → debounce (200ms window, dedup by event + target)
        → Resolver determines affected user_ids
        → broadcast via PubSub → SSE connections

  ## Configuration

      config :keen_auth_permissions,
        pg_listener: [
          enabled: true,
          repo: MyApp.Repo,
          pubsub: MyApp.PubSub,
          channels: ["auth_events"],
          debounce_interval: 200  # ms, default 200
        ]

  ## Supervision

  Add to your application's supervision tree (after `KeenAuth.SSE.Supervisor`):

      children = [
        KeenAuth.SSE.Supervisor,
        KeenAuthPermissions.PgListener,
        # ...
      ]

  ## Standardized Notification Payload

  All pg_notify payloads follow a unified format:

      {
        "event": "permission_assigned",
        "tenant_id": 1,
        "target_type": "user",
        "target_id": 42,
        "detail": { "perm_set_id": 5, "permission_id": 12 },
        "at": "2026-02-21T10:30:00Z"
      }

  The `target_type` determines how affected users are resolved:

  | target_type  | Resolution                         | Delete fallback |
  |:-------------|:-----------------------------------|:----------------|
  | `"user"`     | Direct from target_id              | same            |
  | `"group"`    | Query `auth.notify_group_users`    | MembershipCache |
  | `"perm_set"` | Query `auth.notify_perm_set_users` | N/A             |
  | `"system"`   | Query `auth.notify_permission_users` | N/A           |
  | `"provider"` | Query `auth.notify_provider_users` | MembershipCache |
  | `"tenant"`   | Query `auth.notify_tenant_users`   | MembershipCache |
  | `"api_key"`  | Service-level (no user routing)    | same            |
  """

  use GenServer

  require Logger

  alias KeenAuthPermissions.PgListener.Resolver

  @default_channels ["auth_events"]
  @default_debounce_interval 200

  # ============================================================================
  # Public API
  # ============================================================================

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Returns the current listener state (for debugging/monitoring).
  """
  def status do
    GenServer.call(__MODULE__, :status)
  end

  # ============================================================================
  # GenServer Callbacks
  # ============================================================================

  @impl true
  def init(_opts) do
    config = Application.get_env(:keen_auth_permissions, :pg_listener, [])

    if Keyword.get(config, :enabled, false) do
      state = %{
        config: config,
        notifications_pid: nil,
        listen_refs: [],
        buffer: %{},
        debounce_timer: nil,
        debounce_interval: Keyword.get(config, :debounce_interval, @default_debounce_interval),
        channels: Keyword.get(config, :channels, @default_channels),
        pubsub: Keyword.get(config, :pubsub),
        connected: false
      }

      # Connect asynchronously to avoid blocking supervision tree
      send(self(), :connect)

      {:ok, state}
    else
      :ignore
    end
  end

  @impl true
  def handle_info(:connect, state) do
    case connect_to_postgres(state.config) do
      {:ok, pid} ->
        Process.monitor(pid)
        refs = listen_to_channels(pid, state.channels)

        Logger.info("PgListener connected, listening on channels: #{inspect(state.channels)}")

        {:noreply, %{state | notifications_pid: pid, listen_refs: refs, connected: true}}

      {:error, reason} ->
        Logger.error("PgListener failed to connect: #{inspect(reason)}, retrying in 5s")
        Process.send_after(self(), :connect, 5_000)
        {:noreply, state}
    end
  end

  @impl true
  def handle_info({:notification, _pid, _ref, channel, payload}, state) do
    case Jason.decode(payload) do
      {:ok, data} ->
        Logger.debug("PgListener notification on #{channel}: #{inspect(data)}")
        state = buffer_notification(state, data)
        {:noreply, state}

      {:error, _reason} ->
        Logger.warning("PgListener non-JSON payload on #{channel}: #{payload}")
        {:noreply, state}
    end
  end

  @impl true
  def handle_info(:flush_buffer, state) do
    process_buffer(state.buffer, state.pubsub)
    {:noreply, %{state | buffer: %{}, debounce_timer: nil}}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, reason}, %{notifications_pid: pid} = state) do
    Logger.warning("PgListener connection lost: #{inspect(reason)}, reconnecting in 1s")
    Process.send_after(self(), :connect, 1_000)
    {:noreply, %{state | notifications_pid: nil, listen_refs: [], connected: false}}
  end

  @impl true
  def handle_info(_msg, state), do: {:noreply, state}

  @impl true
  def handle_call(:status, _from, state) do
    status = %{
      connected: state.connected,
      channels: state.channels,
      buffer_size: map_size(state.buffer),
      pubsub: state.pubsub
    }

    {:reply, status, state}
  end

  # ============================================================================
  # Connection
  # ============================================================================

  defp connect_to_postgres(config) do
    conn_opts = connection_opts(config)
    Postgrex.Notifications.start_link(conn_opts)
  end

  defp connection_opts(config) do
    case Keyword.get(config, :repo) do
      nil ->
        Keyword.take(config, [:hostname, :port, :database, :username, :password, :socket_dir])

      repo ->
        repo_config = repo.config()

        [
          hostname: repo_config[:hostname],
          port: repo_config[:port] || 5432,
          database: repo_config[:database],
          username: repo_config[:username],
          password: repo_config[:password]
        ]
        |> Enum.reject(fn {_k, v} -> is_nil(v) end)
        |> then(fn opts ->
          case repo_config[:socket_dir] do
            nil -> opts
            socket_dir -> Keyword.put(opts, :socket_dir, socket_dir)
          end
        end)
    end
  end

  defp listen_to_channels(pid, channels) do
    Enum.map(channels, fn channel ->
      case Postgrex.Notifications.listen(pid, channel) do
        {:ok, ref} ->
          ref

        {:error, reason} ->
          Logger.error("PgListener failed to LISTEN on #{channel}: #{inspect(reason)}")
          nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  # ============================================================================
  # Debounce Buffer
  # ============================================================================

  defp buffer_notification(state, data) do
    # Deduplicate by {event, target_type, target_id, tenant_id}
    key = buffer_key(data)
    buffer = Map.put(state.buffer, key, data)

    # Reset debounce timer
    if state.debounce_timer, do: Process.cancel_timer(state.debounce_timer)
    timer = Process.send_after(self(), :flush_buffer, state.debounce_interval)

    %{state | buffer: buffer, debounce_timer: timer}
  end

  defp buffer_key(data) do
    {data["event"], data["target_type"], data["target_id"], data["tenant_id"]}
  end

  # ============================================================================
  # Notification Processing
  # ============================================================================

  defp process_buffer(buffer, _pubsub) when map_size(buffer) == 0, do: :ok

  defp process_buffer(buffer, pubsub) do
    count = map_size(buffer)
    Logger.debug("PgListener processing #{count} buffered notification(s)")

    buffer
    |> Map.values()
    |> Enum.each(fn data -> process_notification(data, pubsub) end)
  end

  defp process_notification(%{"event" => _event} = data, pubsub) when is_binary(pubsub) do
    process_notification(data, String.to_existing_atom(pubsub))
  end

  defp process_notification(%{"event" => event} = data, pubsub) do
    case Resolver.resolve(data) do
      {:ok, []} ->
        Logger.debug("PgListener: no users to notify for event=#{event}")

      {:ok, user_ids} ->
        Logger.debug("PgListener: broadcasting #{event} to #{length(user_ids)} user(s)")

        payload = %{
          event: event,
          tenant_id: data["tenant_id"],
          target_type: data["target_type"],
          target_id: data["target_id"],
          detail: data["detail"] || %{},
          at: data["at"]
        }

        KeenAuth.SSE.Broadcaster.broadcast_many(pubsub, user_ids, event, payload)

      {:error, reason} ->
        Logger.error("PgListener: resolver failed for #{event}: #{inspect(reason)}")
    end
  rescue
    e ->
      Logger.error("PgListener error processing #{event}: #{Exception.message(e)}")
  end

  defp process_notification(data, _pubsub) do
    Logger.warning("PgListener: payload missing 'event' field: #{inspect(data)}")
  end
end
