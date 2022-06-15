defmodule KeenAuthPermissions.Plug.RequireAuthenticated do
  @behaviour Plug

  alias KeenAuth.Config
  alias Plug.Conn

  import Conn

  @type opts() :: [storage: atom(), handler: {atom(), atom()}]
  @type final_opts() :: %{
    storage: atom(),
    handler: {atom(), atom()}
  }

  @spec init(opts()) :: final_opts()
  def init(opts) do
    %{
      storage: Config.get_storage()
    }
    |> Map.merge(Enum.into(opts, %{}))
  end

  @spec call(Conn.t(), final_opts()) :: Conn.t()
  def call(conn, opts) do
    storage = opts.storage

    if storage.authenticated?(conn) do
      conn
    else
      handle_unauthenticated(conn, opts)
    end
  end

  def handle_unauthenticated(conn, opts) do
    case opts[:handler] do
      nil ->
        conn
        |> put_status(401)
        |> halt()

      {mod, fun} ->
        apply(mod, fun, [conn])
    end
  end
end
