defmodule KeenAuthPermissions.PermissionsMap do
  @moduledoc """
  GenServer that caches a bidirectional mapping between permission full codes and short codes.

  Loaded at startup from `get_permissions_map()` and refreshable via `reload/0`.

  ## Usage

      # Translate between codes
      PermissionsMap.full_to_short("groups.create_group")  # => "10.03"
      PermissionsMap.short_to_full("10.03")                # => "groups.create_group"

      # Check permissions on a user (whose permissions are stored as short codes)
      PermissionsMap.has?(user, "groups.create_group")
      PermissionsMap.has_any?(user, ["groups.create_group", "users.manage"])
      PermissionsMap.has_all?(user, ["groups.create_group", "users.manage"])

      # Bulk translate
      PermissionsMap.resolve_permissions(["10.03", "10.04"])  # => ["groups.create_group", "groups.delete_group"]
  """

  use GenServer

  require Logger

  @name __MODULE__

  # ============================================================================
  # Public API
  # ============================================================================

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, @name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc "Translate a full permission code to its short code."
  @spec full_to_short(String.t()) :: String.t() | nil
  def full_to_short(full_code) do
    GenServer.call(@name, {:full_to_short, full_code})
  end

  @doc "Translate a short code to its full permission code."
  @spec short_to_full(String.t()) :: String.t() | nil
  def short_to_full(short_code) do
    GenServer.call(@name, {:short_to_full, short_code})
  end

  @doc """
  Check if a user has a permission (specified by full code).

  The user's `permissions` field is expected to contain short codes.
  """
  @spec has?(KeenAuthPermissions.User.t(), String.t()) :: boolean()
  def has?(%{permissions: permissions}, full_code) when is_list(permissions) do
    case full_to_short(full_code) do
      nil -> false
      short -> short in permissions
    end
  end

  def has?(_, _), do: false

  @doc "Check if a user has any of the listed permissions (specified by full codes)."
  @spec has_any?(KeenAuthPermissions.User.t(), list(String.t())) :: boolean()
  def has_any?(%{permissions: permissions} = _user, full_codes)
      when is_list(permissions) and is_list(full_codes) do
    short_codes = GenServer.call(@name, {:full_to_short_many, full_codes})
    Enum.any?(short_codes, fn short -> short != nil and short in permissions end)
  end

  def has_any?(_, _), do: false

  @doc "Check if a user has all of the listed permissions (specified by full codes)."
  @spec has_all?(KeenAuthPermissions.User.t(), list(String.t())) :: boolean()
  def has_all?(%{permissions: permissions} = _user, full_codes)
      when is_list(permissions) and is_list(full_codes) do
    short_codes = GenServer.call(@name, {:full_to_short_many, full_codes})

    Enum.all?(short_codes, fn short -> short != nil and short in permissions end)
  end

  def has_all?(_, _), do: false

  @doc "Translate a list of short codes to full codes. Unknown short codes are omitted."
  @spec resolve_permissions(list(String.t())) :: list(String.t())
  def resolve_permissions(short_codes) when is_list(short_codes) do
    GenServer.call(@name, {:resolve_permissions, short_codes})
  end

  @doc "Reload the permissions map from the database."
  @spec reload() :: :ok
  def reload do
    GenServer.call(@name, :reload)
  end

  # ============================================================================
  # GenServer callbacks
  # ============================================================================

  @impl true
  def init(_opts) do
    state = load_map()
    {:ok, state}
  end

  @impl true
  def handle_call({:full_to_short, full_code}, _from, state) do
    {:reply, Map.get(state.full_to_short, full_code), state}
  end

  def handle_call({:short_to_full, short_code}, _from, state) do
    {:reply, Map.get(state.short_to_full, short_code), state}
  end

  def handle_call({:full_to_short_many, full_codes}, _from, state) do
    result = Enum.map(full_codes, &Map.get(state.full_to_short, &1))
    {:reply, result, state}
  end

  def handle_call({:resolve_permissions, short_codes}, _from, state) do
    result =
      short_codes
      |> Enum.map(&Map.get(state.short_to_full, &1))
      |> Enum.reject(&is_nil/1)

    {:reply, result, state}
  end

  def handle_call(:reload, _from, _state) do
    state = load_map()
    {:reply, :ok, state}
  end

  # ============================================================================
  # Private
  # ============================================================================

  defp load_map do
    db_context = KeenAuthPermissions.DbContext.get_global_db_context()

    case db_context.get_permissions_map() do
      {:ok, rows} ->
        full_to_short =
          Map.new(rows, fn %{full_code: full, short_code: short} -> {full, short} end)

        short_to_full =
          Map.new(rows, fn %{full_code: full, short_code: short} -> {short, full} end)

        Logger.info("PermissionsMap loaded #{map_size(full_to_short)} permissions")
        %{full_to_short: full_to_short, short_to_full: short_to_full}

      {:error, reason} ->
        Logger.error("Failed to load permissions map: #{inspect(reason)}")
        %{full_to_short: %{}, short_to_full: %{}}
    end
  end
end
