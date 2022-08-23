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
  def process(conn, :aad, mapped_user, %{user: _user} = response) do
    db_context = DbContext.current_db_context!(conn)

    {:ok, [user]} =
      db_context.auth_ensure_user_from_provider(
        "system",
        "aad",
        mapped_user.id,
        mapped_user.username,
        mapped_user.email,
        mapped_user.display_name,
        nil
      )

    permissions_user = struct(User, user)

    {:ok, %{groups: groups, permissions: permissions}} =
      db_context.auth_ensure_groups_and_permissions(
        1,
        permissions_user.user_id,
        TenantResolver.resolve_tenant(conn),
        "aad",
        [],
        user["roles"]
      )

    {:ok, conn, %{permissions_user | groups: groups, permissions: permissions}, response}
  end
end
