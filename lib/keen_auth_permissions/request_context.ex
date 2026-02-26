defmodule KeenAuthPermissions.RequestContext do
  @moduledoc """
  Request context containing user information and request metadata.

  This struct is passed to all facade functions to provide:
  - User authentication context (user_id, username, user_oid)
  - Request metadata (ip, user_agent, origin)
  - Localization (language_code)
  - Request tracing (request_id)

  ## Extra fields

  Consuming applications can extend this struct with additional context fields via config:

      # config/config.exs
      config :keen_auth_permissions,
        context_extra_fields: [:tenant_code, :session_id, :device_id]

  Extra fields default to `nil` and are included in `to_context_map/1` output,
  making them available to PostgreSQL stored procedures via the JSONB context parameter.

  ## Examples

      # Create context from a user
      context = RequestContext.new(user)

      # Create context with all options
      context = RequestContext.new(user,
        ip: "192.168.1.1",
        user_agent: "Mozilla/5.0...",
        origin: "https://example.com",
        language_code: "en",
        request_id: "req-123-abc"
      )

      # With extra fields (if configured)
      context = RequestContext.new(user,
        ip: "192.168.1.1",
        tenant_code: "acme",
        session_id: "sess-456"
      )

      # Serialize context metadata for JSONB parameter
      RequestContext.to_context_map(context)
      # => %{"ip" => "192.168.1.1", "request_id" => "req-123-abc", "tenant_code" => "acme", ...}

      # Set a field on an existing context
      context = RequestContext.with_field(context, :session_id, "sess-789")

      # Use in facade functions
      KeenAuthPermissions.UserGroups.list(context, tenant_id)

      # Access user fields directly from context
      context.user_id
      context.username
  """

  require Logger

  alias KeenAuthPermissions.User
  alias KeenAuthPermissions.ServiceAccounts

  @base_keys [:user_id, :user_oid, :username, :user]
  @context_keys [:ip, :user_agent, :origin, :language_code, :request_id]
  @extra_keys Application.compile_env(:keen_auth_permissions, :context_extra_fields, [])
  @context_fields @context_keys ++ @extra_keys

  @enforce_keys @base_keys
  defstruct @base_keys ++ @context_keys ++ @extra_keys

  @type t :: %__MODULE__{
          user_id: integer(),
          user_oid: String.t() | nil,
          username: String.t(),
          user: User.t(),
          ip: String.t() | nil,
          user_agent: String.t() | nil,
          origin: String.t() | nil,
          language_code: String.t() | nil,
          request_id: String.t() | nil
        }

  @doc """
  Creates a new request context from a user.

  ## Options

    * `:ip` - Client IP address
    * `:user_agent` - Client user agent string
    * `:origin` - Request origin URL
    * `:language_code` - User's preferred language code
    * `:request_id` - Request ID for tracing (defaults to Logger metadata)

  Any configured `context_extra_fields` can also be passed as options.

  ## Examples

      iex> user = %User{user_id: 1, username: "admin", ...}
      iex> RequestContext.new(user)
      %RequestContext{user_id: 1, username: "admin", user: user, ...}

      iex> RequestContext.new(user, ip: "10.0.0.1", language_code: "cs")
      %RequestContext{user_id: 1, ip: "10.0.0.1", language_code: "cs", ...}
  """
  @spec new(User.t(), keyword()) :: t()
  def new(%User{} = user, opts \\ []) do
    base = %__MODULE__{
      user_id: user.user_id,
      user_oid: user.uuid,
      username: user.username,
      user: user,
      ip: Keyword.get(opts, :ip),
      user_agent: Keyword.get(opts, :user_agent),
      origin: Keyword.get(opts, :origin),
      language_code: Keyword.get(opts, :language_code),
      request_id: Keyword.get(opts, :request_id) || get_request_id()
    }

    Enum.reduce(@extra_keys, base, fn key, acc ->
      case Keyword.fetch(opts, key) do
        {:ok, value} -> %{acc | key => value}
        :error -> acc
      end
    end)
  end

  @doc """
  Creates a context for a specific service account.

  Use this for runtime operations instead of `system_ctx/0`.
  Each service account has a specific purpose, providing meaningful audit trails.

  ## Examples

      iex> RequestContext.service_ctx(:authenticator)
      %RequestContext{user_id: 3, username: "svc_authenticator", ...}

      iex> RequestContext.service_ctx(:registrator)
      %RequestContext{user_id: 2, username: "svc_registrator", ...}
  """
  @spec service_ctx(ServiceAccounts.account_name()) :: t()
  def service_ctx(account_name) do
    user = ServiceAccounts.user(account_name)
    new(user)
  end

  @doc """
  Creates a system context for seed/migration and background tasks.

  For runtime operations, prefer `service_ctx/1` with a purpose-specific account
  (e.g., `:registrator`, `:authenticator`) to get meaningful audit trails.

  ## Examples

      iex> RequestContext.system_ctx()
      %RequestContext{user_id: 1, username: "system", ...}

      iex> RequestContext.system_ctx("scheduler")
      %RequestContext{user_id: 1, username: "scheduler", ...}
  """
  @spec system_ctx(String.t() | nil) :: t()
  def system_ctx(username \\ nil) do
    if username do
      info = ServiceAccounts.get(:system)

      user = %User{
        user_id: info.user_id,
        code: info.username,
        uuid: nil,
        username: username,
        email: info.email,
        display_name: info.display_name,
        groups: [],
        permissions: []
      }

      new(user)
    else
      service_ctx(:system)
    end
  end

  # ============================================================================
  # Context Serialization
  # ============================================================================

  @doc """
  Serializes context metadata fields into a string-keyed map for the JSONB parameter.

  Includes all context fields (ip, user_agent, origin, language_code, request_id)
  plus any configured `context_extra_fields`. Excludes user identity fields
  (user_id, user_oid, username, user) and nil values.

  ## Examples

      iex> ctx = RequestContext.new(user, ip: "10.0.0.1", request_id: "req-123")
      iex> RequestContext.to_context_map(ctx)
      %{"ip" => "10.0.0.1", "request_id" => "req-123"}

      # With extra fields configured as [:tenant_code]
      iex> ctx = RequestContext.new(user, request_id: "req-1", tenant_code: "acme")
      iex> RequestContext.to_context_map(ctx)
      %{"request_id" => "req-1", "tenant_code" => "acme"}
  """
  @spec to_context_map(t()) :: map()
  def to_context_map(%__MODULE__{} = context) do
    @context_fields
    |> Enum.map(fn key -> {Atom.to_string(key), Map.get(context, key)} end)
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end

  # ============================================================================
  # Field Setters
  # ============================================================================

  @doc """
  Sets a field on an existing request context.

  Works for both built-in context fields and configured extra fields.

  ## Examples

      iex> ctx = RequestContext.new(user)
      iex> RequestContext.with_field(ctx, :ip, "10.0.0.1")
      %RequestContext{ip: "10.0.0.1", ...}

      iex> RequestContext.with_field(ctx, :tenant_code, "acme")
      %RequestContext{tenant_code: "acme", ...}
  """
  @spec with_field(t(), atom(), any()) :: t()
  def with_field(%__MODULE__{} = context, field, value) when is_atom(field) do
    %{context | field => value}
  end

  @doc """
  Creates a new request context with the given request ID.

  Convenience function for setting request ID on an existing context.
  """
  @spec with_request_id(t(), String.t() | nil) :: t()
  def with_request_id(%__MODULE__{} = context, request_id) do
    %{context | request_id: request_id}
  end

  @doc """
  Creates a new request context with the given language code.
  """
  @spec with_language_code(t(), String.t() | nil) :: t()
  def with_language_code(%__MODULE__{} = context, language_code) do
    %{context | language_code: language_code}
  end

  # Backward compatibility alias
  @doc false
  @spec with_locale(t(), String.t() | nil) :: t()
  def with_locale(context, locale), do: with_language_code(context, locale)

  @doc """
  Gets the current request ID from Logger metadata.
  """
  @spec get_request_id() :: String.t() | nil
  def get_request_id do
    Logger.metadata()[:request_id]
  end

  # Backward compatibility alias
  @doc false
  @spec with_correlation_id(t(), String.t() | nil) :: t()
  def with_correlation_id(context, id), do: with_request_id(context, id)
end
