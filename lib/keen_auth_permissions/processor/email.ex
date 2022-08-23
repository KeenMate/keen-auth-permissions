defmodule KeenAuthPermissions.Processor.Email do
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

    {:ok, %{groups: groups, permissions: permissions}} =
      db_context.auth_ensure_groups_and_permissions(
        1,
        mapped_user.user_id,
        TenantResolver.resolve_tenant(conn),
        "email",
        mapped_user[:groups],
        mapped_user[:roles]
      )

    {:ok, conn, %{mapped_user | groups: groups, permissions: permissions}, response}
  end
end
