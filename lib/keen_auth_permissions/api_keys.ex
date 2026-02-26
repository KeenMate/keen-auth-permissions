# This module provides a clean API for API key operations.
# It wraps the auto-generated database context functions with a cleaner interface.

defmodule KeenAuthPermissions.ApiKeys do
  @moduledoc """
  Clean facade API for API key management operations.

  All functions take a `%RequestContext{}` struct as the first parameter for authentication context,
  and return single items instead of lists where appropriate.

  ## Examples

      # Search API keys
      KeenAuthPermissions.ApiKeys.search(context, "my-key", 1, 20, tenant_id)

      # Create an API key
      KeenAuthPermissions.ApiKeys.create(context, "My Key", "Description", ...)

      # Validate an API key
      KeenAuthPermissions.ApiKeys.validate(context, api_key, api_secret, tenant_id)
  """

  alias KeenAuthPermissions.User
  alias KeenAuthPermissions.RequestContext
  alias KeenAuthPermissions.Error.{ErrorParsers, ErrorStruct}

  defp db_context(), do: KeenAuthPermissions.DbContext.get_global_db_context()

  # ============================================================================
  # API Key Generation
  # ============================================================================

  @doc """
  Generates a new API key.

  Calls `auth.generate_api_key`.
  """
  @spec generate_key() :: {:ok, String.t()} | {:error, any()}
  def generate_key do
    case db_context().auth_generate_api_key() do
      {:ok, [%{generate_api_key: key}]} -> {:ok, key}
      {:ok, []} -> {:error, :generation_failed}
      error -> error
    end
  end

  @doc """
  Generates a username for an API key.

  Calls `auth.generate_api_key_username`.
  """
  @spec generate_username(String.t()) :: {:ok, String.t()} | {:error, any()}
  def generate_username(api_key) do
    case db_context().auth_generate_api_key_username(api_key) do
      {:ok, [%{generate_api_key_username: username}]} -> {:ok, username}
      {:ok, []} -> {:error, :generation_failed}
      error -> error
    end
  end

  @doc """
  Generates a new API secret.

  Calls `auth.generate_api_secret`.
  """
  @spec generate_secret() :: {:ok, String.t()} | {:error, any()}
  def generate_secret do
    case db_context().auth_generate_api_secret() do
      {:ok, [%{generate_api_secret: secret}]} -> {:ok, secret}
      {:ok, []} -> {:error, :generation_failed}
      error -> error
    end
  end

  @doc """
  Generates a hash for an API secret.

  Calls `auth.generate_api_secret_hash`.
  """
  @spec generate_secret_hash(String.t()) :: {:ok, String.t()} | {:error, any()}
  def generate_secret_hash(secret) do
    case db_context().auth_generate_api_secret_hash(secret) do
      {:ok, [%{generate_api_secret_hash: hash}]} -> {:ok, hash}
      {:ok, []} -> {:error, :generation_failed}
      error -> error
    end
  end

  # ============================================================================
  # API Key CRUD Operations
  # ============================================================================

  @doc """
  Searches API keys.

  Calls `auth.search_api_keys`.
  """
  @spec search(RequestContext.t(), String.t() | nil, integer(), integer(), integer()) ::
          {:ok, list()} | {:error, any()}
  def search(
        %RequestContext{user: %User{user_id: user_id}, request_id: request_id},
        search_text,
        page,
        page_size,
        tenant_id
      ) do
    db_context().auth_search_api_keys(
      user_id,
      request_id,
      search_text,
      page,
      page_size,
      tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Creates a new API key.

  Calls `auth.create_api_key`.
  """
  @spec create(
          RequestContext.t(),
          String.t(),
          String.t(),
          String.t(),
          list(String.t()),
          String.t(),
          String.t(),
          DateTime.t() | nil,
          String.t() | nil,
          integer()
        ) :: {:ok, map()} | {:error, any()}
  def create(
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id},
        title,
        description,
        perm_set_code,
        permission_codes,
        api_key,
        api_secret,
        expire_at,
        notification_email,
        tenant_id
      ) do
    case db_context().auth_create_api_key(
           username,
           user_id,
           request_id,
           title,
           description,
           perm_set_code,
           permission_codes,
           api_key,
           api_secret,
           expire_at,
           notification_email,
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :creation_failed}
      error -> error
    end
  end

  @doc """
  Updates an API key.

  Calls `auth.update_api_key`.
  """
  @spec update(
          RequestContext.t(),
          integer(),
          String.t(),
          String.t(),
          DateTime.t() | nil,
          String.t() | nil,
          integer()
        ) :: {:ok, map()} | {:error, any()}
  def update(
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id},
        api_key_id,
        title,
        description,
        expire_at,
        notification_email,
        tenant_id
      ) do
    case db_context().auth_update_api_key(
           username,
           user_id,
           request_id,
           api_key_id,
           title,
           description,
           expire_at,
           notification_email,
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :update_failed}
      error -> error
    end
  end

  @doc """
  Updates an API key's secret.

  Calls `auth.update_api_key_secret`.
  """
  @spec update_secret(RequestContext.t(), integer(), String.t(), integer()) ::
          {:ok, map()} | {:error, any()}
  def update_secret(
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id},
        api_key_id,
        api_secret,
        tenant_id
      ) do
    case db_context().auth_update_api_key_secret(
           username,
           user_id,
           request_id,
           api_key_id,
           api_secret,
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :update_failed}
      error -> error
    end
  end

  @doc """
  Deletes an API key.

  Calls `auth.delete_api_key`.
  """
  @spec delete(RequestContext.t(), integer(), integer()) :: {:ok, map()} | {:error, any()}
  def delete(
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id},
        api_key_id,
        tenant_id
      ) do
    case db_context().auth_delete_api_key(
           username,
           user_id,
           request_id,
           api_key_id,
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :delete_failed}
      error -> error
    end
  end

  # ============================================================================
  # API Key Permission Operations
  # ============================================================================

  @doc """
  Gets permissions for an API key.

  Calls `auth.get_api_key_permissions`.
  """
  @spec list_permissions(RequestContext.t(), integer(), integer()) ::
          {:ok, list()} | {:error, any()}
  def list_permissions(
        %RequestContext{user: %User{user_id: user_id}, request_id: request_id},
        api_key_id,
        tenant_id
      ) do
    db_context().auth_get_api_key_permissions(
      user_id,
      request_id,
      api_key_id,
      tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Assigns permissions to an API key.

  Calls `auth.assign_api_key_permissions`.
  """
  @spec assign_permissions(
          RequestContext.t(),
          integer(),
          String.t(),
          list(String.t()),
          integer()
        ) :: {:ok, list()} | {:error, any()}
  def assign_permissions(
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id},
        api_key_id,
        perm_set_code,
        permission_codes,
        tenant_id
      ) do
    db_context().auth_assign_api_key_permissions(
      username,
      user_id,
      request_id,
      api_key_id,
      perm_set_code,
      permission_codes,
      tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Unassigns permissions from an API key.

  Calls `auth.unassign_api_key_permissions`.
  """
  @spec unassign_permissions(
          RequestContext.t(),
          integer(),
          String.t(),
          list(String.t()),
          integer()
        ) :: {:ok, list()} | {:error, any()}
  def unassign_permissions(
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id},
        api_key_id,
        perm_set_code,
        permission_codes,
        tenant_id
      ) do
    db_context().auth_unassign_api_key_permissions(
      username,
      user_id,
      request_id,
      api_key_id,
      perm_set_code,
      permission_codes,
      tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  # ============================================================================
  # API Key Validation
  # ============================================================================

  @doc """
  Validates an API key.

  Calls `auth.validate_api_key`. The context map (including ip, user_agent, origin)
  is passed as a single JSONB parameter.
  """
  @spec validate(RequestContext.t(), String.t(), String.t(), integer()) ::
          {:ok, map()} | {:error, any()}
  def validate(
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id} = ctx,
        api_key,
        api_secret,
        tenant_id
      ) do
    case db_context().auth_validate_api_key(
           username,
           user_id,
           request_id,
           api_key,
           api_secret,
           RequestContext.to_context_map(ctx),
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, ErrorStruct.create(:invalid_api_key, "Invalid API key or secret")}
      error -> error
    end
  end

  # ============================================================================
  # Outbound API Key Operations
  # ============================================================================

  @doc """
  Searches outbound API keys.

  Calls `auth.search_outbound_api_keys`.
  """
  @spec search_outbound(
          RequestContext.t(),
          String.t() | nil,
          String.t() | nil,
          integer(),
          integer(),
          integer()
        ) :: {:ok, list()} | {:error, any()}
  def search_outbound(
        %RequestContext{user: %User{user_id: user_id}, request_id: request_id},
        search_text,
        service_code,
        page,
        page_size,
        tenant_id
      ) do
    db_context().auth_search_outbound_api_keys(
      user_id,
      request_id,
      search_text,
      service_code,
      page,
      page_size,
      tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Gets an outbound API key.

  Calls `auth.get_outbound_api_key`.
  Returns a single key or error.
  """
  @spec get_outbound(RequestContext.t(), String.t(), integer()) :: {:ok, map()} | {:error, any()}
  def get_outbound(
        %RequestContext{user: %User{user_id: user_id}, request_id: request_id},
        service_code,
        tenant_id
      ) do
    case db_context().auth_get_outbound_api_key(
           user_id,
           request_id,
           service_code,
           tenant_id
         ) do
      {:ok, [key | _]} -> {:ok, key}
      {:ok, []} -> {:error, ErrorStruct.create(:not_found, "Outbound API key not found")}
      {:error, error} -> {:error, ErrorParsers.parse_error(error)}
    end
  end

  @doc """
  Gets an outbound API key by ID.

  Calls `auth.get_outbound_api_key_by_id`.
  Returns a single key or error.
  """
  @spec get_outbound_by_id(RequestContext.t(), integer(), integer()) ::
          {:ok, map()} | {:error, any()}
  def get_outbound_by_id(
        %RequestContext{user: %User{user_id: user_id}, request_id: request_id},
        api_key_id,
        tenant_id
      ) do
    case db_context().auth_get_outbound_api_key_by_id(
           user_id,
           request_id,
           api_key_id,
           tenant_id
         ) do
      {:ok, [key | _]} -> {:ok, key}
      {:ok, []} -> {:error, ErrorStruct.create(:not_found, "Outbound API key not found")}
      {:error, error} -> {:error, ErrorParsers.parse_error(error)}
    end
  end

  @doc """
  Gets an outbound API key secret.

  Calls `auth.get_outbound_api_key_secret`.
  Returns a single secret or error.
  """
  @spec get_outbound_secret(RequestContext.t(), String.t(), integer()) ::
          {:ok, map()} | {:error, any()}
  def get_outbound_secret(
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id},
        service_code,
        tenant_id
      ) do
    case db_context().auth_get_outbound_api_key_secret(
           username,
           user_id,
           request_id,
           service_code,
           tenant_id
         ) do
      {:ok, [secret | _]} -> {:ok, secret}
      {:ok, []} -> {:error, ErrorStruct.create(:not_found, "Outbound API key secret not found")}
      {:error, error} -> {:error, ErrorParsers.parse_error(error)}
    end
  end

  @doc """
  Gets an outbound API key secret by ID.

  Calls `auth.get_outbound_api_key_secret_by_id`.
  Returns a single secret or error.
  """
  @spec get_outbound_secret_by_id(RequestContext.t(), integer(), integer()) ::
          {:ok, map()} | {:error, any()}
  def get_outbound_secret_by_id(
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id},
        api_key_id,
        tenant_id
      ) do
    case db_context().auth_get_outbound_api_key_secret_by_id(
           username,
           user_id,
           request_id,
           api_key_id,
           tenant_id
         ) do
      {:ok, [secret | _]} -> {:ok, secret}
      {:ok, []} -> {:error, ErrorStruct.create(:not_found, "Outbound API key secret not found")}
      {:error, error} -> {:error, ErrorParsers.parse_error(error)}
    end
  end

  @doc """
  Creates an outbound API key.

  Calls `auth.create_outbound_api_key`.
  """
  @spec create_outbound(
          RequestContext.t(),
          String.t(),
          String.t(),
          String.t(),
          binary(),
          String.t(),
          String.t(),
          DateTime.t() | nil,
          String.t() | nil,
          integer()
        ) :: {:ok, map()} | {:error, any()}
  def create_outbound(
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id},
        title,
        description,
        service_code,
        encrypted_secret,
        service_url,
        extra_data,
        expire_at,
        notification_email,
        tenant_id
      ) do
    case db_context().auth_create_outbound_api_key(
           username,
           user_id,
           request_id,
           title,
           description,
           service_code,
           encrypted_secret,
           service_url,
           extra_data,
           expire_at,
           notification_email,
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :creation_failed}
      error -> error
    end
  end

  @doc """
  Updates an outbound API key.

  Calls `auth.update_outbound_api_key`.
  """
  @spec update_outbound(
          RequestContext.t(),
          integer(),
          String.t(),
          String.t(),
          String.t(),
          String.t(),
          DateTime.t() | nil,
          String.t() | nil,
          integer()
        ) :: {:ok, map()} | {:error, any()}
  def update_outbound(
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id},
        api_key_id,
        title,
        description,
        service_url,
        extra_data,
        expire_at,
        notification_email,
        tenant_id
      ) do
    case db_context().auth_update_outbound_api_key(
           username,
           user_id,
           request_id,
           api_key_id,
           title,
           description,
           service_url,
           extra_data,
           expire_at,
           notification_email,
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :update_failed}
      error -> error
    end
  end

  @doc """
  Updates an outbound API key's secret.

  Calls `auth.update_outbound_api_key_secret`.
  """
  @spec update_outbound_secret(RequestContext.t(), integer(), binary(), integer()) ::
          {:ok, map()} | {:error, any()}
  def update_outbound_secret(
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id},
        api_key_id,
        encrypted_secret,
        tenant_id
      ) do
    case db_context().auth_update_outbound_api_key_secret(
           username,
           user_id,
           request_id,
           api_key_id,
           encrypted_secret,
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :update_failed}
      error -> error
    end
  end

  @doc """
  Deletes an outbound API key.

  Calls `auth.delete_outbound_api_key`.
  """
  @spec delete_outbound(RequestContext.t(), integer(), integer()) ::
          {:ok, map()} | {:error, any()}
  def delete_outbound(
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id},
        api_key_id,
        tenant_id
      ) do
    case db_context().auth_delete_outbound_api_key(
           username,
           user_id,
           request_id,
           api_key_id,
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :delete_failed}
      error -> error
    end
  end
end
