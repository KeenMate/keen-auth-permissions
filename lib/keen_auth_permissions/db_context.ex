defmodule KeenAuthPermissions.DbContext do
  alias KeenAuth.Config
  alias KeenAuth.Plug

  def current_db_context!(conn) do
    Plug.fetch_config(conn)
    |> get_db_context!()
  end

  def get_db_context!(config) do
    Config.get(config, :db_context) || Config.raise_error("DbContext not configured")
  end
end
