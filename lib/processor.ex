defmodule KeenAuthPermissions.Processor do
  @behaviour KeenAuth.Processor

  alias KeenAuthPermissions.Config

  @impl true
  def process(conn, provider, %{user: user} = oauth_response) do
    db_context = Config.get_db_context()
    # tenant_id = Config.get_tenant_id_resolver().(conn)

    with {:ok, db_user} <- ensure_user(user, provider, db_context),
        #  :ok <- update_user_data(db_context, user, db_user, provider),
        #  {:ok, roles_and_permissions} <- update_user_roles(db_context, user, db_user, provider),
         user <- enrich_user(user, db_user, %{}) do
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

  def update_user_data(db_context, user, db_user, provider) do
    case db_context.update_user_data("system", db_user.user_id, provider, user) do
      {:ok, _} ->
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  def ensure_user(user, user_data \\ nil, provider, db_context) do
    with {:ok, [user]} <- db_context.auth_ensure_user_from_provider("system",
      Atom.to_string(provider),
      user.id,
      user.username,
      user.display_name,
      user.email,
      Jason.encode!(user_data)
    ) do
      {:ok, user}
    end
  end
end
