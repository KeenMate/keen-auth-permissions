defmodule KeenAuthPermissions.Plug.RevalidateSession do
  @moduledoc """
  A plug that periodically revalidates the session user against the database.

  Session cookies store the full user object and `KeenAuth.Plug.FetchUser` deserializes
  it without checking the database. If a user is deleted, disabled, or locked in the DB,
  their cookie remains valid. This plug adds a TTL-based revalidation check.

  Place this plug **after** `KeenAuth.Plug.FetchUser` and **before**
  `KeenAuth.Plug.RequireAuthenticated` in the pipeline.

  ## Options

    * `:interval` - Seconds between revalidation checks. Default: `300` (5 minutes).
    * `:redirect` - Path to redirect to when the session is invalid. Default: `"/login"`.
    * `:on_invalid` - Custom `fn conn, reason -> conn` called when revalidation fails.
      Overrides the default redirect behavior. The function must return a `%Plug.Conn{}`.
    * `:validate_fn` - Custom `fn user_id -> :ok | {:error, reason}` for revalidation.
      Overrides the default `KeenAuthPermissions.Users.get_by_id/1` check.

  ## Examples

      # In a :require_auth pipeline (redirect on invalid)
      pipeline :require_auth do
        plug KeenAuth.Plug.FetchUser
        plug KeenAuthPermissions.Plug.RevalidateSession
        plug KeenAuth.Plug.RequireAuthenticated, redirect: "/login"
      end

      # In a :maybe_auth pipeline (silently clear stale user)
      pipeline :maybe_auth do
        plug KeenAuth.Plug.FetchUser
        plug KeenAuthPermissions.Plug.RevalidateSession,
          on_invalid: &KeenAuthPermissions.Plug.RevalidateSession.clear_user/2
      end

      # With custom interval and validation
      plug KeenAuthPermissions.Plug.RevalidateSession,
        interval: 60,
        validate_fn: fn user_id ->
          case MyApp.Users.get_active_user(user_id) do
            {:ok, _user} -> :ok
            _ -> {:error, :not_found}
          end
        end
  """

  @behaviour Plug

  import Plug.Conn
  require Logger

  @default_interval 300
  @default_redirect "/login"
  @session_key :session_validated_at

  @impl true
  def init(opts) do
    %{
      interval: Keyword.get(opts, :interval, @default_interval),
      redirect: Keyword.get(opts, :redirect, @default_redirect),
      on_invalid: Keyword.get(opts, :on_invalid),
      validate_fn: Keyword.get(opts, :validate_fn)
    }
  end

  @impl true
  def call(conn, opts) do
    case conn.assigns[:current_user] do
      nil ->
        conn

      current_user ->
        maybe_revalidate(conn, current_user, opts)
    end
  end

  @doc """
  Built-in `on_invalid` callback that silently clears the stale user from assigns.

  Useful for `:maybe_auth` pipelines where you don't want to redirect,
  just remove the invalid user so the page renders as if no one is logged in.

  ## Example

      plug KeenAuthPermissions.Plug.RevalidateSession,
        on_invalid: &KeenAuthPermissions.Plug.RevalidateSession.clear_user/2
  """
  @spec clear_user(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def clear_user(conn, _reason) do
    assign(conn, :current_user, nil)
  end

  defp maybe_revalidate(conn, current_user, opts) do
    now = System.system_time(:second)
    last_validated = get_session(conn, @session_key)

    if is_integer(last_validated) and now - last_validated < opts.interval do
      conn
    else
      revalidate(conn, current_user, opts, now)
    end
  end

  defp revalidate(conn, current_user, opts, now) do
    user_id = extract_user_id(current_user)

    if is_nil(user_id) do
      Logger.warning("RevalidateSession: could not extract user_id from current_user")
      handle_invalid(conn, opts, :no_user_id)
    else
      case validate_user(user_id, opts) do
        :ok ->
          put_session(conn, @session_key, now)

        {:error, reason} ->
          Logger.info(
            "RevalidateSession: user #{user_id} failed revalidation: #{inspect(reason)}"
          )

          handle_invalid(conn, opts, reason)
      end
    end
  end

  defp extract_user_id(%KeenAuthPermissions.User{user_id: id}), do: id
  defp extract_user_id(_), do: nil

  defp validate_user(user_id, %{validate_fn: validate_fn}) when is_function(validate_fn, 1) do
    validate_fn.(user_id)
  end

  defp validate_user(user_id, _opts) do
    case KeenAuthPermissions.Users.get_by_id(user_id) do
      {:ok, _user} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp handle_invalid(conn, %{on_invalid: on_invalid}, reason) when is_function(on_invalid, 2) do
    conn
    |> clear_session_data()
    |> on_invalid.(reason)
  end

  defp handle_invalid(conn, opts, _reason) do
    conn
    |> KeenAuth.Storage.delete()
    |> clear_session_data()
    |> assign(:current_user, nil)
    |> Phoenix.Controller.redirect(to: opts.redirect)
    |> halt()
  end

  defp clear_session_data(conn) do
    delete_session(conn, @session_key)
  end
end
