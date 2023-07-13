defmodule KeenAuthPermissions.Storage do
  @groups_path [:assigns, :user_groups]
  @permissions_path [:assigns, :user_permissions]

  def put_permissions(conn, items) do
    put_in(conn, @permissions_path, items)
  end

  def put_groups(conn, items) do
    put_in(conn, @groups_path, items)
  end


  def get_groups(conn) do
    get_in(conn, @groups_path)
  end

  def get_permissions(conn) do
    get_in(conn, @permissions_path)
  end
end
