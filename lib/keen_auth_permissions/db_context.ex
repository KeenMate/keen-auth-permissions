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

	# this is for use in
  @db_context_key :db_context
  def get_global_db_context() do
    get_from_config!(@db_context_key)
  end

  defp get_from_config!(key) do
    Application.fetch_env!(:pluto_common_modules, key)
  end
end
