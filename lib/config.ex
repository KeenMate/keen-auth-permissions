defmodule KeenAuthPermissions.Config do
  @moduledoc """
  ## Configuration
  This package requires `db_context` to be provided with module name pointing to the generated ecto_gen `DbContext`
  which contains following introspected stored procedures:

  - ensure_user(username, email, display_name, provider)
  - update_roles_and_permissions()
  """

  def get_db_context() do
    Application.fetch_env!(:keen_auth_permissions, :db_context)
  end
end
