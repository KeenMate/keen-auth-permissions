defmodule KeenAuthPermissions.Email do
  alias KeenAuthPermissions.DbContext
  import KeenAuthPermissions.Error.ErrorParsers

  @spec authenticate(
          conn :: Plug.Conn.t(),
          email :: binary(),
          password :: binary(),
          validation :: (password :: binary(), password_hash :: binary() -> boolean())
        ) ::
          {:ok, KeenAuthPermissions.Database.Models.AuthGetUserByEmailForAuthenticationItem.t()}
          | {:error, :unauthenticated}
          | {:error, KeenAuthPermissions.Error.ErrorStruct.t()}
  def authenticate(conn, email, password, validation) do
    db_context = DbContext.current_db_context!(conn)
    get_user_result = db_context.auth_get_user_by_email_for_authentication(1, email)

    with {:ok, [%{password_hash: password_hash} = user]} <- get_user_result do
      case validation.(password, password_hash) do
        true -> {:ok, user}
        false -> {:error, :unauthenticated}
      end
    else
      {:error, %Postgrex.Error{postgres: %{pg_code: "52103"}}} ->
        # User not found
        {:error, :unauthenticated}

      err ->
        parse_if_error(err)
    end
  end
end
