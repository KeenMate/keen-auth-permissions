defmodule KeenAuthPermissions.ServiceAccounts do
  @moduledoc """
  Defines service accounts used for automated operations.

  Each service account has a specific purpose and maps to a seeded user in the database.
  Using purpose-specific accounts instead of the generic "system" account provides
  meaningful audit trails and enforces least privilege.

  ## Accounts

    * `:system` - Root system account for seed/migration operations
    * `:registrator` - User registration operations
    * `:authenticator` - Authentication and login operations
    * `:token_manager` - Token lifecycle (creation, validation, consumption)
    * `:api_gateway` - API gateway operations
    * `:group_syncer` - Group synchronization operations
    * `:data_processor` - Data processing operations

  ## Configuration

  Defaults can be overridden per-account via application config:

      config :keen_auth_permissions, :service_accounts, %{
        registrator: %{user_id: 22}
      }

  ## Custom Accounts

  You can define fully custom service accounts via config. All four fields
  (`user_id`, `username`, `display_name`, `email`) are required:

      config :keen_auth_permissions, :service_accounts, %{
        my_importer: %{user_id: 900, username: "svc_importer", display_name: "Importer", email: "svc_importer@localhost"}
      }

  Then use it like any built-in account:

      RequestContext.service_ctx(:my_importer)
  """

  alias KeenAuthPermissions.User

  @type account_name :: atom()

  @defaults %{
    system: %{
      user_id: 1,
      username: "system",
      display_name: "System",
      email: "system@localhost"
    },
    registrator: %{
      user_id: 2,
      username: "svc_registrator",
      display_name: "Registrator",
      email: "svc_registrator@localhost"
    },
    authenticator: %{
      user_id: 3,
      username: "svc_authenticator",
      display_name: "Authenticator",
      email: "svc_authenticator@localhost"
    },
    token_manager: %{
      user_id: 4,
      username: "svc_token_manager",
      display_name: "Token Manager",
      email: "svc_token_manager@localhost"
    },
    api_gateway: %{
      user_id: 5,
      username: "svc_api_gateway",
      display_name: "API Gateway",
      email: "svc_api_gateway@localhost"
    },
    group_syncer: %{
      user_id: 6,
      username: "svc_group_syncer",
      display_name: "Group Syncer",
      email: "svc_group_syncer@localhost"
    },
    data_processor: %{
      user_id: 800,
      username: "svc_data_processor",
      display_name: "Data Processor",
      email: "svc_data_processor@localhost"
    }
  }

  @doc """
  Returns account info map for the given service account name.

  Merges any config overrides on top of the hardcoded defaults.

  ## Examples

      iex> ServiceAccounts.get(:registrator)
      %{user_id: 2, username: "svc_registrator", display_name: "Registrator", email: "svc_registrator@localhost"}
  """
  @required_fields [:user_id, :username, :display_name, :email]

  @spec get(account_name()) :: map()
  def get(name) when is_atom(name) do
    configured =
      Application.get_env(:keen_auth_permissions, :service_accounts, %{})
      |> Map.get(name, %{})

    case Map.get(@defaults, name) do
      nil ->
        missing = @required_fields -- Map.keys(configured)

        if missing != [] do
          raise ArgumentError,
                "Unknown service account #{inspect(name)}. " <>
                  "Custom accounts must be configured with all required fields: #{inspect(@required_fields)}. " <>
                  "Missing: #{inspect(missing)}"
        end

        configured

      defaults ->
        Map.merge(defaults, configured)
    end
  end

  @doc """
  Returns a `%User{}` struct for the given service account.

  ## Examples

      iex> ServiceAccounts.user(:authenticator)
      %User{user_id: 3, username: "svc_authenticator", ...}
  """
  @spec user(account_name()) :: User.t()
  def user(name) do
    info = get(name)

    %User{
      user_id: info.user_id,
      code: info.username,
      uuid: nil,
      username: info.username,
      email: info.email,
      display_name: info.display_name,
      groups: [],
      permissions: []
    }
  end

  @doc """
  Returns the list of all service account name atoms.

  ## Examples

      iex> ServiceAccounts.names()
      [:system, :registrator, :authenticator, :token_manager, :api_gateway, :group_syncer, :data_processor]
  """
  @spec names() :: [account_name()]
  def names do
    configured = Application.get_env(:keen_auth_permissions, :service_accounts, %{}) |> Map.keys()

    ((@defaults |> Map.keys()) ++ (configured -- Map.keys(@defaults)))
    |> Enum.uniq()
  end
end
