defmodule KeenAuthPermissions.Processor do
  @behaviour KeenAuth.Processor

  alias KeenAuthPermissions.Config

  @impl true
  def process(conn, provider, %{user: user} = oauth_response) do
    db_context = Config.get_db_context()

    with {:ok, db_user} <- ensure_user(db_context, user, provider),
         {:ok, roles_and_permissions} <- update_user_roles(db_context, user, db_user, provider),
         user <- enrich_user(user, db_user, roles_and_permissions) do
      oauth_response = Map.put(oauth_response, :user, user)

      {:ok, conn, oauth_response}
    end
  end

  def enrich_user(user, db_user, roles_and_permissions) do
    user
    |> Map.put(:user_id, db_user.user_id)
    |> Map.merge(roles_and_permissions)
  end

  def update_user_roles(db_context, _user, db_user, _provider) do
    case db_context.update_roles_and_permissions(db_user.user_id) do
      {:ok, [roles_and_permissions]} ->
        {:ok, roles_and_permissions}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def ensure_user(db_context, user, provider) do
    case db_context.ensure_user(user["preferred_username"], user["email"], user["display_name"], provider) do
      {:ok, [user]} ->
        {:ok, user}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
