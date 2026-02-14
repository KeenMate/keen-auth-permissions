defmodule KeenAuthPermissions.RequestContext do
  @moduledoc """
  Request context containing user information and request metadata.

  This struct is passed to all facade functions to provide:
  - User authentication context (user_id, username, user_oid)
  - Request metadata (ip, user_agent, origin)
  - Localization (language_code)
  - Request tracing (request_id)

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

      # Use in facade functions
      KeenAuthPermissions.UserGroups.list(context, tenant_id)

      # Access user fields directly from context
      context.user_id
      context.username
  """

  require Logger

  alias KeenAuthPermissions.User

  @system_username "system"

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

  @enforce_keys [:user_id, :username, :user]
  defstruct [
    :user_id,
    :user_oid,
    :username,
    :user,
    :ip,
    :user_agent,
    :origin,
    :language_code,
    :request_id
  ]

  @doc """
  Creates a new request context from a user.

  ## Options

    * `:ip` - Client IP address
    * `:user_agent` - Client user agent string
    * `:origin` - Request origin URL
    * `:language_code` - User's preferred language code
    * `:request_id` - Request ID for tracing (defaults to Logger metadata)

  ## Examples

      iex> user = %User{user_id: 1, username: "admin", ...}
      iex> RequestContext.new(user)
      %RequestContext{user_id: 1, username: "admin", user: user, ...}

      iex> RequestContext.new(user, ip: "10.0.0.1", language_code: "cs")
      %RequestContext{user_id: 1, ip: "10.0.0.1", language_code: "cs", ...}
  """
  @spec new(User.t(), keyword()) :: t()
  def new(%User{} = user, opts \\ []) do
    %__MODULE__{
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
  end

  @doc """
  Creates a system context for background jobs and automated tasks.

  The system context uses user_id 1 and has no associated request metadata.

  ## Examples

      iex> RequestContext.system_ctx()
      %RequestContext{user_id: 1, username: "system", ...}

      iex> RequestContext.system_ctx("scheduler")
      %RequestContext{user_id: 1, username: "scheduler", ...}
  """
  @spec system_ctx(String.t() | nil) :: t()
  def system_ctx(username \\ @system_username) do
    user = %User{
      user_id: 1,
      code: "system",
      uuid: nil,
      username: username || @system_username,
      email: "system@localhost",
      display_name: "System",
      groups: [],
      permissions: []
    }

    %__MODULE__{
      user_id: 1,
      user_oid: nil,
      username: username || @system_username,
      user: user,
      ip: nil,
      user_agent: nil,
      origin: nil,
      language_code: nil,
      request_id: get_request_id()
    }
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
