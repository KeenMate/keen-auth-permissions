defmodule KeenAuthPermissions.Processor.AzureAD do
  @behaviour KeenAuth.Processor

  alias KeenAuthPermissions.DbContext
  alias KeenAuthPermissions.User

  @impl true
  @spec process(
          conn :: Plug.Conn.t(),
          provider :: atom(),
          user :: KeenAuth.User.t() | map(),
          response :: map()
        ) :: {:ok, Plug.Conn.t(), KeenAuth.User.t() | map(), map() | nil} | Plug.Conn.t()
  @azure_ad_providers [:aad, :entra, :azure_ad]

  def process(conn, provider, mapped_user, response) when provider in @azure_ad_providers do
    db_context = DbContext.current_db_context!(conn)
    provider_code = to_string(provider)

    correlation_id = "#{provider_code}-login"

    # Build context map for the JSONB parameter (ip, user_agent, origin)
    context = build_context_map(conn, correlation_id)

    {:ok, [user]} =
      db_context.auth_ensure_user_from_provider(
        "system",
        1,
        correlation_id,
        provider_code,
        mapped_user.user_id,
        mapped_user.user_id,
        mapped_user.username,
        mapped_user.display_name,
        mapped_user.email,
        nil,
        context
      )

    permissions_user = struct(User, Map.from_struct(user))

    {groups, permissions} =
      case db_context.auth_ensure_groups_and_permissions(
             "system",
             1,
             correlation_id,
             permissions_user.user_id,
             provider_code,
             [],
             mapped_user.roles
           ) do
        {:ok, [%{groups: groups, short_code_permissions: short_code_permissions}]} ->
          {groups, short_code_permissions}

        {:ok, []} ->
          {[], []}
      end

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

  # Builds a context map from conn for the JSONB parameter
  defp build_context_map(conn, correlation_id) do
    %{
      "request_id" => correlation_id,
      "ip" => get_client_ip(conn),
      "user_agent" => get_user_agent(conn),
      "origin" => get_origin(conn)
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end

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
