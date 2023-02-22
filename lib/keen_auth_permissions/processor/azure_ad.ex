defmodule KeenAuthPermissions.Processor.AzureAD do
  @behaviour KeenAuth.Processor

  alias KeenAuthPermissions.TenantResolver
  alias KeenAuthPermissions.DbContext
  alias KeenAuthPermissions.User

  @impl true
  @spec process(
          conn :: Plug.Conn.t(),
          provider :: atom(),
          user :: KeenAuth.User.t() | map(),
          response :: map()
        ) :: {:ok, Plug.Conn.t(), KeenAuth.User.t() | map(), map() | nil} | Plug.Conn.t()
  def process(conn, :aad, mapped_user, response) do
    db_context = DbContext.current_db_context!(conn)

    {:ok, [user]} =
      db_context.auth_ensure_user_from_provider(
        "system",
        1,
        "aad",
        mapped_user.user_id,
        mapped_user.username,
        mapped_user.display_name,
        mapped_user.email,
        nil
      )

    permissions_user = struct(User, Map.from_struct(user))

    {:ok, [%{groups: groups, permissions: permissions}]} =
      db_context.auth_ensure_groups_and_permissions(
        "system",
        1,
        permissions_user.user_id,
        "aad",
        [],
        mapped_user.roles,
        TenantResolver.resolve_tenant(conn)
      )

    {:ok, conn, %{permissions_user | groups: groups, permissions: permissions}, response}
  end
end
