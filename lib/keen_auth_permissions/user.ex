defmodule KeenAuthPermissions.User do
  @moduledoc """
  User struct for authentication and authorization.

  ## Extra fields

  Consuming applications can extend this struct with additional fields via config:

      # config/config.exs
      config :keen_auth_permissions,
        user_extra_fields: [:employee_number, :department, :phone]

  Extra fields are optional (default to `nil`) and support dot access,
  pattern matching, and compile-time validation like any other struct field.
  """

  @keys [:user_id, :code, :uuid, :username, :email, :display_name, :groups, :permissions]
  @extra_keys Application.compile_env(:keen_auth_permissions, :user_extra_fields, [])

  @enforce_keys @keys
  defstruct @keys ++ @extra_keys

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
