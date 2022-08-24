defmodule KeenAuthPermissions.Email do
  alias KeenAuthPermissions.DbContext

  @spec authenticate(
          conn :: Plug.Conn.t(),
          email :: binary(),
          password :: binary(),
          validation :: (password :: binary(), password_hash :: binary() -> boolean())
        ) :: {:ok, KeenAuthPermissions.Database.Models.AuthGetUserByEmailForAuthenticationItem.t()} | {:error, :unauthenticated}
  def authenticate(conn, email, password, validation) do
    db_context = DbContext.current_db_context!(conn)

    {:ok, [%{password_hash: password_hash} = user]} =
      db_context.auth_get_user_by_email_for_authentication(1, email)

    case validation.(password, password_hash) do
      true -> {:ok, user}
      false -> {:error, :unauthenticated}
    end
  end
end
