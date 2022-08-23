# defmodule KeenAuthPermissions.Plug.FetchTenantPermissions do
#   @behaviour Plug

#   alias KeenAuthPermissions.Config
#   alias KeenAuthPermissions.Storage

#   @impl true
#   def init(_opts) do
#     %{
#       db_context: Config.get_db_context(),
#       storage: KeenAuth.Config.get_storage()
#     }
#   end

#   @impl true
#   def call(conn, opts) do
#     %{
#       db_context: db_context,
#       storage: keen_storage
#     } = opts

#     user = keen_storage.current_user(conn)

#     load_permissions(db_context, conn, user)
#   end

#   def load_permissions(db_context, conn, user) do
#     case db_context.auth_get_tenant_permissions(Config.get_tenant_code_resolver().(conn), user.user_id) do
# 			{:ok, [permissions]} ->
# 				store_permissions(permissions.groups, permissions.permissions)

# 			{:ok, []} ->
# 				store_permissions(conn)

# 			error ->
# 				error
# 		end
#   end

# 	def	store_permissions(conn, groups \\ "", permissions \\ "") do
# 		conn
# 		|> Storage.put_permissions(String.split(permissions, ";"))
# 		|> Storage.put_groups(String.split(groups, ";"))
# 	end
# end
