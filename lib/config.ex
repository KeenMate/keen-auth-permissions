defmodule KeenAuthPermissions.Config do
  def get_db_context() do
    Application.get_env(:keen_auth_permissions, :db_context)
  end
end
