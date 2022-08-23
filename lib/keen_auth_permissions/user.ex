defmodule KeenAuthPermissions.User do
  @keys [:id, :user_id, :code, :uuid, :username, :email, :display_name, :groups, :permissions]

  @enforce_keys @keys
  defstruct @keys
end
