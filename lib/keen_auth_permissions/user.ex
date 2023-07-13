defmodule KeenAuthPermissions.User do
  @keys [:user_id, :code, :uuid, :username, :email, :display_name, :groups, :permissions]

  @enforce_keys @keys
  defstruct @keys
end
