defmodule KeenAuthPermissions.Config do
  @moduledoc """
  This package requires `db_context` to be provided with module name pointing to the generated ecto_gen `DbContext`
  which contains following introspected stored procedures:
  - auth_ensure_user_from_provider(created_by, provider, provider_uid, username, display_name, email, user_data)

  ### Tenant ID
  If provided (may be function (`{mod, fun}`) accepting conn and returning tenant id) or straight tenant id
  """

  def get_db_context() do
    Application.fetch_env!(:keen_auth_permissions, :db_context)
  end

  def get_tenant_code_resolver() do
    tenant_id = Application.get_env(:keen_auth_permissions, :tenant_code)

    case tenant_id do
      {mod, fun} when is_atom(mod) and is_atom(fun) ->
        fn conn -> apply(mod, fun, [conn]) end

      tenant_id when is_binary(tenant_id) or is_integer(tenant_id) ->
        fn _conn -> tenant_id end

      nil ->
        fn _conn -> nil end
    end
  end
end
