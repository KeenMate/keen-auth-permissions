defmodule KeenAuthPermissions.TenantResolver do
  alias KeenAuth.Config
  alias KeenAuth.Plug

  def resolve_tenant(conn) do
    tenant_resolver = current_tenant_resolver!(conn)

    case tenant_resolver do
      fun when is_function(fun) -> fun.(conn)
      tenant_id when is_binary(tenant_id) or is_integer(tenant_id) -> tenant_id
      nil -> nil
    end
  end

  def current_tenant_resolver!(conn) do
    Plug.fetch_config(conn)
    |> get_tenant_resolver!()
  end

  def get_tenant_resolver!(config) do
    Config.get(config, :tenant) ||
      Config.raise_error("Tenant resolver not configured, please configure :tenant key")
  end
end
