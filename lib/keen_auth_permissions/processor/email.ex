defmodule KeenAuthPermissions.Processor.Email do
  @behaviour KeenAuth.Processor

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

    correlation_id = "email-login"

    {groups, permissions} =
      case db_context.auth_ensure_groups_and_permissions(
             "system",
             1,
             correlation_id,
             mapped_user.user_id,
             "email",
             fetch_groups(mapped_user),
             fetch_roles(mapped_user),
             1
           ) do
        {:ok, [%{groups: groups, short_code_permissions: short_code_permissions}]} ->
          {groups, short_code_permissions}

        {:ok, []} ->
          {[], []}
      end

    {:ok, conn, %{mapped_user | groups: groups, permissions: permissions}, response}
  end

  def fetch_groups(%KeenAuthPermissions.User{groups: groups}), do: groups || []

  def fetch_groups(_), do: []

  def fetch_roles(%KeenAuth.User{roles: roles}), do: roles || []

  def fetch_roles(_), do: []

  @impl true
  def sign_out(conn, _provider, _params) do
    storage = KeenAuth.Storage.current_storage(conn)

    conn
    |> storage.delete()
    |> KeenAuth.Helpers.RequestHelpers.redirect_back(%{
      "redirect_to" => Application.get_env(:keen_auth, :redirect_after_sign_out)
    })
  end
end
