defmodule KeenAuthPermissions.Storage do
  @roles_path [:assigns, :user, :roles]

  # def put_roles(conn, roles) do
  #   put_in(conn, @roles_path, roles)
  # end

  def get_roles(conn) do
    get_in(conn, @roles_path)
  end
end
