# This module provides a clean API for authentication operations.
# It wraps the auto-generated database context functions with a cleaner interface.

defmodule KeenAuthPermissions.Auth do
  @moduledoc """
  Clean facade API for authentication operations.

  Provides functions for user registration, login, tokens, providers, and events.

  ## Examples

      # Register a new user
      KeenAuthPermissions.Auth.register(request_context, "john@example.com", "hashed_pwd", "John Doe")

      # Validate a token
      KeenAuthPermissions.Auth.validate_token(request_context, target_user_id, nil, token, "password_reset", ...)

      # Create an auth event
      KeenAuthPermissions.Auth.create_event(request_context, "login", target_user_id, ...)
  """

  alias KeenAuthPermissions.User
  alias KeenAuthPermissions.RequestContext
  alias KeenAuthPermissions.Error.{ErrorParsers, ErrorStruct}

  defp db_context(), do: KeenAuthPermissions.DbContext.get_global_db_context()

  # ============================================================================
  # Registration Operations
  # ============================================================================

  @doc """
  Registers a new user.

  Calls `auth.register_user`.
  """
  @spec register(RequestContext.t(), String.t(), String.t(), String.t(), map() | nil) ::
          {:ok, map()} | {:error, any()}
  def register(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        email,
        password_hash,
        display_name,
        user_data \\ nil
      ) do
    case db_context().auth_register_user(
           username,
           user_id,
           request_id,
           email,
           password_hash,
           display_name,
           user_data
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :registration_failed}
      error -> error
    end
  end

  # ============================================================================
  # Token Operations
  # ============================================================================

  @doc """
  Creates a token.

  Calls `auth.create_token`.
  """
  @spec create_token(
          RequestContext.t(),
          integer(),
          String.t() | nil,
          integer() | nil,
          String.t(),
          String.t(),
          String.t(),
          DateTime.t() | nil,
          String.t() | nil
        ) :: {:ok, map()} | {:error, any()}
  def create_token(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        target_user_id,
        target_user_oid,
        user_event_id,
        token_type_code,
        token_channel_code,
        token,
        expires_at,
        token_data
      ) do
    case db_context().auth_create_token(
           username,
           user_id,
           request_id,
           target_user_id,
           target_user_oid,
           user_event_id,
           token_type_code,
           token_channel_code,
           token,
           expires_at,
           token_data
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :token_creation_failed}
      error -> error
    end
  end

  @doc """
  Validates a token using ip/user_agent/origin from context.

  Calls `auth.validate_token`.
  """
  @spec validate_token(
          RequestContext.t(),
          integer(),
          String.t() | nil,
          String.t(),
          String.t(),
          boolean()
        ) ::
          {:ok, map()} | {:error, any()}
  def validate_token(
        %RequestContext{ip: ip, user_agent: user_agent, origin: origin} = ctx,
        target_user_id,
        token_uid,
        token,
        token_type_code,
        set_as_used
      ) do
    validate_token(
      ctx,
      target_user_id,
      token_uid,
      token,
      token_type_code,
      ip,
      user_agent,
      origin,
      set_as_used
    )
  end

  @doc """
  Validates a token with explicit ip/user_agent/origin.

  Calls `auth.validate_token`.
  """
  @spec validate_token(
          RequestContext.t(),
          integer(),
          String.t() | nil,
          String.t(),
          String.t(),
          String.t() | nil,
          String.t() | nil,
          String.t() | nil,
          boolean()
        ) :: {:ok, map()} | {:error, any()}
  def validate_token(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        target_user_id,
        token_uid,
        token,
        token_type_code,
        ip_address,
        user_agent,
        origin,
        set_as_used
      ) do
    case db_context().auth_validate_token(
           username,
           user_id,
           request_id,
           target_user_id,
           token_uid,
           token,
           token_type_code,
           ip_address,
           user_agent,
           origin,
           set_as_used
         ) do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, ErrorStruct.create(:invalid_token, "Token is invalid or expired")}
      {:error, error} -> {:error, ErrorParsers.parse_error(error)}
    end
  end

  @doc """
  Sets a token as used using ip/user_agent/origin from context.

  Calls `auth.set_token_as_used`.
  """
  @spec set_token_as_used(RequestContext.t(), String.t() | nil, String.t(), String.t()) ::
          {:ok, map()} | {:error, any()}
  def set_token_as_used(
        %RequestContext{ip: ip, user_agent: user_agent, origin: origin} = ctx,
        token_uid,
        token,
        token_type_code
      ) do
    set_token_as_used(ctx, token_uid, token, token_type_code, ip, user_agent, origin)
  end

  @doc """
  Sets a token as used with explicit ip/user_agent/origin.

  Calls `auth.set_token_as_used`.
  """
  @spec set_token_as_used(
          RequestContext.t(),
          String.t() | nil,
          String.t(),
          String.t(),
          String.t() | nil,
          String.t() | nil,
          String.t() | nil
        ) :: {:ok, map()} | {:error, any()}
  def set_token_as_used(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        token_uid,
        token,
        token_type_code,
        ip_address,
        user_agent,
        origin
      ) do
    case db_context().auth_set_token_as_used(
           username,
           user_id,
           request_id,
           token_uid,
           token,
           token_type_code,
           ip_address,
           user_agent,
           origin
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :operation_failed}
      error -> error
    end
  end

  @doc """
  Sets a token as used by token value using ip/user_agent/origin from context.

  Calls `auth.set_token_as_used_by_token`.
  """
  @spec set_token_as_used_by_token(RequestContext.t(), String.t(), String.t()) ::
          {:ok, map()} | {:error, any()}
  def set_token_as_used_by_token(
        %RequestContext{ip: ip, user_agent: user_agent, origin: origin} = ctx,
        token,
        token_type
      ) do
    set_token_as_used_by_token(ctx, token, token_type, ip, user_agent, origin)
  end

  @doc """
  Sets a token as used by token value with explicit ip/user_agent/origin.

  Calls `auth.set_token_as_used_by_token`.
  """
  @spec set_token_as_used_by_token(
          RequestContext.t(),
          String.t(),
          String.t(),
          String.t() | nil,
          String.t() | nil,
          String.t() | nil
        ) :: {:ok, map()} | {:error, any()}
  def set_token_as_used_by_token(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        token,
        token_type,
        ip_address,
        user_agent,
        origin
      ) do
    case db_context().auth_set_token_as_used_by_token(
           username,
           user_id,
           request_id,
           token,
           token_type,
           ip_address,
           user_agent,
           origin
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :operation_failed}
      error -> error
    end
  end

  @doc """
  Sets a token as failed using ip/user_agent/origin from context.

  Calls `auth.set_token_as_failed`.
  """
  @spec set_token_as_failed(RequestContext.t(), String.t() | nil, String.t(), String.t()) ::
          {:ok, map()} | {:error, any()}
  def set_token_as_failed(
        %RequestContext{ip: ip, user_agent: user_agent, origin: origin} = ctx,
        token_uid,
        token,
        token_type_code
      ) do
    set_token_as_failed(ctx, token_uid, token, token_type_code, ip, user_agent, origin)
  end

  @doc """
  Sets a token as failed with explicit ip/user_agent/origin.

  Calls `auth.set_token_as_failed`.
  """
  @spec set_token_as_failed(
          RequestContext.t(),
          String.t() | nil,
          String.t(),
          String.t(),
          String.t() | nil,
          String.t() | nil,
          String.t() | nil
        ) :: {:ok, map()} | {:error, any()}
  def set_token_as_failed(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        token_uid,
        token,
        token_type_code,
        ip_address,
        user_agent,
        origin
      ) do
    case db_context().auth_set_token_as_failed(
           username,
           user_id,
           request_id,
           token_uid,
           token,
           token_type_code,
           ip_address,
           user_agent,
           origin
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :operation_failed}
      error -> error
    end
  end

  @doc """
  Sets a token as failed by token value using ip/user_agent/origin from context.

  Calls `auth.set_token_as_failed_by_token`.
  """
  @spec set_token_as_failed_by_token(RequestContext.t(), String.t(), String.t()) ::
          {:ok, map()} | {:error, any()}
  def set_token_as_failed_by_token(
        %RequestContext{ip: ip, user_agent: user_agent, origin: origin} = ctx,
        token,
        token_type
      ) do
    set_token_as_failed_by_token(ctx, token, token_type, ip, user_agent, origin)
  end

  @doc """
  Sets a token as failed by token value with explicit ip/user_agent/origin.

  Calls `auth.set_token_as_failed_by_token`.
  """
  @spec set_token_as_failed_by_token(
          RequestContext.t(),
          String.t(),
          String.t(),
          String.t() | nil,
          String.t() | nil,
          String.t() | nil
        ) :: {:ok, map()} | {:error, any()}
  def set_token_as_failed_by_token(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        token,
        token_type,
        ip_address,
        user_agent,
        origin
      ) do
    case db_context().auth_set_token_as_failed_by_token(
           username,
           user_id,
           request_id,
           token,
           token_type,
           ip_address,
           user_agent,
           origin
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :operation_failed}
      error -> error
    end
  end

  # ============================================================================
  # User Event Operations
  # ============================================================================

  @doc """
  Creates a user event using ip/user_agent/origin from context.

  Calls `auth.create_user_event`.
  """
  @spec create_event(
          RequestContext.t(),
          String.t(),
          integer() | nil,
          String.t() | nil,
          String.t() | nil,
          String.t() | nil
        ) :: {:ok, map()} | {:error, any()}
  def create_event(
        %RequestContext{ip: ip, user_agent: user_agent, origin: origin} = ctx,
        event_type_code,
        target_user_id,
        event_data,
        target_user_oid,
        target_username
      ) do
    create_event(
      ctx,
      event_type_code,
      target_user_id,
      ip,
      user_agent,
      origin,
      event_data,
      target_user_oid,
      target_username
    )
  end

  @doc """
  Creates a user event with explicit ip/user_agent/origin.

  Calls `auth.create_user_event`.
  """
  @spec create_event(
          RequestContext.t(),
          String.t(),
          integer() | nil,
          String.t() | nil,
          String.t() | nil,
          String.t() | nil,
          String.t() | nil,
          String.t() | nil,
          String.t() | nil
        ) :: {:ok, map()} | {:error, any()}
  def create_event(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        event_type_code,
        target_user_id,
        ip_address,
        user_agent,
        origin,
        event_data,
        target_user_oid,
        target_username
      ) do
    case db_context().auth_create_user_event(
           username,
           user_id,
           request_id,
           event_type_code,
           target_user_id,
           ip_address,
           user_agent,
           origin,
           event_data,
           target_user_oid,
           target_username
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :event_creation_failed}
      error -> error
    end
  end

  @doc """
  Creates a user event with a payload map using ip/user_agent/origin from context.

  Calls `auth.create_user_event` with JSON-encoded payload.
  """
  @spec create_event_with_payload(
          RequestContext.t(),
          String.t(),
          integer() | nil,
          map()
        ) :: {:ok, map()} | {:error, any()}
  def create_event_with_payload(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id,
          ip: ip,
          user_agent: user_agent,
          origin: origin
        },
        event_type_code,
        target_user_id,
        payload_map
      ) do
    case db_context().auth_create_user_event(
           username,
           user_id,
           request_id,
           event_type_code,
           target_user_id,
           ip,
           user_agent,
           origin,
           Jason.encode!(payload_map),
           nil,
           nil
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :event_creation_failed}
      error -> error
    end
  end

  # ============================================================================
  # Provider Operations
  # ============================================================================

  @doc """
  Creates a provider.

  Calls `auth.create_provider`.
  """
  @spec create_provider(RequestContext.t(), String.t(), String.t(), boolean()) ::
          {:ok, map()} | {:error, any()}
  def create_provider(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        provider_code,
        provider_name,
        is_active
      ) do
    case db_context().auth_create_provider(
           username,
           user_id,
           request_id,
           provider_code,
           provider_name,
           is_active
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :creation_failed}
      error -> error
    end
  end

  @doc """
  Updates a provider.

  Calls `auth.update_provider`.
  """
  @spec update_provider(RequestContext.t(), integer(), String.t(), String.t(), boolean()) ::
          {:ok, map()} | {:error, any()}
  def update_provider(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        provider_id,
        provider_code,
        provider_name,
        is_active
      ) do
    case db_context().auth_update_provider(
           username,
           user_id,
           request_id,
           provider_id,
           provider_code,
           provider_name,
           is_active
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :update_failed}
      error -> error
    end
  end

  @doc """
  Deletes a provider.

  Calls `auth.delete_provider`.
  """
  @spec delete_provider(RequestContext.t(), String.t()) :: {:ok, map()} | {:error, any()}
  def delete_provider(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        provider_code
      ) do
    case db_context().auth_delete_provider(username, user_id, request_id, provider_code)
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :delete_failed}
      error -> error
    end
  end

  @doc """
  Enables a provider.

  Calls `auth.enable_provider`.
  """
  @spec enable_provider(RequestContext.t(), String.t()) :: {:ok, map()} | {:error, any()}
  def enable_provider(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        provider_code
      ) do
    case db_context().auth_enable_provider(username, user_id, request_id, provider_code)
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :enable_failed}
      error -> error
    end
  end

  @doc """
  Disables a provider.

  Calls `auth.disable_provider`.
  """
  @spec disable_provider(RequestContext.t(), String.t()) :: {:ok, map()} | {:error, any()}
  def disable_provider(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        provider_code
      ) do
    case db_context().auth_disable_provider(username, user_id, request_id, provider_code)
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :disable_failed}
      error -> error
    end
  end

  @doc """
  Validates that a provider is active.

  Calls `auth.validate_provider_is_active`.
  Returns `{:ok, true}` if provider is active, `{:error, reason}` otherwise.
  """
  @spec validate_provider_is_active(String.t()) :: {:ok, boolean()} | {:error, any()}
  def validate_provider_is_active(provider_code) do
    case db_context().auth_validate_provider_is_active(provider_code) do
      :ok -> {:ok, true}
      {:error, _} = error -> error
    end
  end

  @doc """
  Gets users from a specific provider.

  Calls `auth.get_provider_users`.
  """
  @spec list_provider_users(RequestContext.t(), String.t()) :: {:ok, list()} | {:error, any()}
  def list_provider_users(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        provider_code
      ) do
    db_context().auth_get_provider_users(username, user_id, request_id, provider_code)
    |> ErrorParsers.parse_if_error()
  end
end
