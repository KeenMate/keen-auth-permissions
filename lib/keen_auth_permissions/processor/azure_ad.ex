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

    # Extract request info from conn for event logging
    ip = get_client_ip(conn)
    user_agent = get_user_agent(conn)
    origin = get_origin(conn)

    {:ok, [user]} =
      db_context.auth_ensure_user_from_provider(
        "system",
        1,
        "aad-login",
        "aad",
        mapped_user.user_id,
        mapped_user.user_id,
        mapped_user.username,
        mapped_user.display_name,
        mapped_user.email,
        nil,
        ip,
        user_agent,
        origin
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

  @impl true
  def sign_out(conn, _provider, _params) do
    storage = KeenAuth.Storage.current_storage(conn)

    conn
    |> storage.delete()
    |> KeenAuth.Helpers.RequestHelpers.redirect_back(%{
      "redirect_to" => Application.get_env(:keen_auth, :redirect_after_sign_out)
    })
  end

  # Helper functions to extract request info from conn

  defp get_client_ip(conn) do
    # Check x-forwarded-for header first (for proxied requests)
    case Plug.Conn.get_req_header(conn, "x-forwarded-for") do
      [forwarded | _] ->
        forwarded
        |> String.split(",")
        |> List.first()
        |> String.trim()

      [] ->
        # Fall back to remote_ip
        case conn.remote_ip do
          {a, b, c, d} -> "#{a}.#{b}.#{c}.#{d}"
          {a, b, c, d, e, f, g, h} -> "#{a}:#{b}:#{c}:#{d}:#{e}:#{f}:#{g}:#{h}"
          nil -> nil
        end
    end
  end

  defp get_user_agent(conn) do
    Plug.Conn.get_req_header(conn, "user-agent") |> List.first()
  end

  defp get_origin(conn) do
    Plug.Conn.get_req_header(conn, "origin") |> List.first()
  end
end
