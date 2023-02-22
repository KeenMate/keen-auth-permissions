defmodule KeenAuthPermissions.Processor.Email do
  @behaviour KeenAuth.Processor

  alias KeenAuthPermissions.TenantResolver
  alias KeenAuthPermissions.DbContext

  @impl true
  @spec process(
          conn :: Plug.Conn.t(),
          provider :: atom(),
          user :: KeenAuth.User.t() | map(),
          response :: map()
        ) :: {:ok, Plug.Conn.t(), KeenAuth.User.t() | map(), map() | nil} | Plug.Conn.t()
  def process(conn, :email, mapped_user, response) do
    db_context = DbContext.current_db_context!(conn)

    {:ok, [%{groups: groups, permissions: permissions}]} =
      db_context.auth_ensure_groups_and_permissions(
        "system",
        1,
        mapped_user.user_id,
        "email",
        fetch_groups(mapped_user),
        fetch_roles(mapped_user),
        TenantResolver.resolve_tenant(conn)
      )

    {:ok, conn, %{mapped_user | groups: groups, permissions: permissions}, response}
  end

  def fetch_groups(%KeenAuthPermissions.User{groups: groups}), do: groups || []

  def fetch_groups(_), do: []

  def fetch_roles(%KeenAuth.User{roles: roles}), do: roles || []

  def fetch_roles(_), do: []
end
