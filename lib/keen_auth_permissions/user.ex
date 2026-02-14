defmodule KeenAuthPermissions.User do
  @keys [:user_id, :code, :uuid, :username, :email, :display_name, :groups, :permissions]

  @enforce_keys @keys
  defstruct @keys

  @type t() :: %__MODULE__{
          user_id: integer(),
          code: String.t() | nil,
          uuid: String.t() | nil,
          username: String.t(),
          email: String.t(),
          display_name: String.t(),
          groups: list(String.t()),
          permissions: list(String.t())
        }
end
