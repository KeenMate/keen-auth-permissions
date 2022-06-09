defmodule KeenAuthPermissions.Processor do
  @behaviour KeenAuth.Processor

  alias KeenAuthPermissions.Config

  @impl true
  def process(conn, provider, %{user: user} = oauth_response) do
    db_context = Config.get_db_context()

    with {:ok, db_user} <- db_context.ensure_user(user["preferred_username"], user["email"], provider),
         {:ok, %{roles: roles, permissions: permissions}} <- db_context.update_roles_and_permissions(db_user.user_id) do
      oauth_response =
        Map.update!(
          oauth_response,
          :user,
          &Map.merge(&1, %{user_id: db_user.user_id, roles: roles, permissions: permissions})
        )

      {:ok, conn, oauth_response}
    end
  end
end
