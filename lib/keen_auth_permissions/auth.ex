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
      KeenAuthPermissions.Auth.validate_token(request_context, target_user_id, nil, token, "password_reset", true)

      # Create an auth event
      KeenAuthPermissions.Auth.create_event(request_context, "login", target_user_id, ...)
  """

  alias KeenAuthPermissions.User
  alias KeenAuthPermissions.RequestContext
  alias KeenAuthPermissions.Error.{ErrorParsers, ErrorStruct}

  defp db_context(), do: KeenAuthPermissions.DbContext.get_global_db_context()

  # ============================================================================
  # Email Authentication Helpers (no RequestContext required)
  # ============================================================================

  @doc """
  Authenticates a user by email and password.

  This is a convenience function for email-based login that doesn't require
  a RequestContext. It verifies the credentials and returns the user if valid.

  ## Examples

      Auth.authenticate_by_email("user@example.com", "password123")
      # => {:ok, %{user_id: 1, email: "user@example.com", ...}}
      # => {:error, :invalid_credentials}
  """
  @spec authenticate_by_email(String.t(), String.t(), keyword()) :: {:ok, map()} | {:error, any()}
  def authenticate_by_email(email, password, opts \\ []) do
    authenticator = KeenAuthPermissions.ServiceAccounts.get(:authenticator)

    correlation_id = "auth-#{:erlang.unique_integer([:positive])}"

    context =
      %{
        "request_id" => correlation_id,
        "ip" => Keyword.get(opts, :ip),
        "user_agent" => Keyword.get(opts, :user_agent),
        "origin" => Keyword.get(opts, :origin)
      }
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Map.new()

    case db_context().auth_get_user_by_email_for_authentication(
           authenticator.user_id,
           correlation_id,
           email,
           context
         ) do
      {:ok, [user]} ->
        if verify_password(password, user.password_hash) do
          {:ok, user}
        else
          {:error, :invalid_credentials}
        end

      {:ok, []} ->
        # Timing attack mitigation - still do password check
        hasher().no_user_verify()
        {:error, :invalid_credentials}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Registers a new user with email and password.

  This is a convenience function that doesn't require a RequestContext.
  It creates a new user with the given email, password, and display name.

  ## Examples

      Auth.register_user("user@example.com", "password123", "John Doe")
      # => {:ok, %{user_id: 1, email: "user@example.com", ...}}
      # => {:error, %ErrorStruct{reason: :email_taken, ...}}
  """
  @spec register_user(String.t(), String.t(), String.t(), map() | nil) ::
          {:ok, map()} | {:error, any()}
  def register_user(email, password, display_name, user_data \\ nil) do
    password_hash = hash_password(password)
    ctx = RequestContext.service_ctx(:registrator)

    register(ctx, email, password_hash, display_name, user_data)
  end

  defp hasher do
    Application.get_env(:keen_auth_permissions, :password_hasher, Pbkdf2)
  end

  defp hash_password(password) do
    hasher().hash_pwd_salt(password)
  end

  defp verify_password(_password, nil), do: false
  defp verify_password(_password, ""), do: false

  defp verify_password(password, hash) do
    hasher().verify_pass(password, hash)
  end

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
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id} = ctx,
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
           user_data,
           RequestContext.to_context_map(ctx)
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
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id},
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
  Validates a token.

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
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id} = ctx,
        target_user_id,
        token_uid,
        token,
        token_type_code,
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
           RequestContext.to_context_map(ctx),
           set_as_used
         ) do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, ErrorStruct.create(:invalid_token, "Token is invalid or expired")}
      {:error, error} -> {:error, ErrorParsers.parse_error(error)}
    end
  end

  @doc """
  Sets a token as used.

  Calls `auth.set_token_as_used`.
  """
  @spec set_token_as_used(RequestContext.t(), String.t() | nil, String.t(), String.t()) ::
          {:ok, map()} | {:error, any()}
  def set_token_as_used(
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id} = ctx,
        token_uid,
        token,
        token_type_code
      ) do
    case db_context().auth_set_token_as_used(
           username,
           user_id,
           request_id,
           token_uid,
           token,
           token_type_code,
           RequestContext.to_context_map(ctx)
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :operation_failed}
      error -> error
    end
  end

  @doc """
  Sets a token as used by token value.

  Calls `auth.set_token_as_used_by_token`.
  """
  @spec set_token_as_used_by_token(RequestContext.t(), String.t(), String.t()) ::
          {:ok, map()} | {:error, any()}
  def set_token_as_used_by_token(
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id} = ctx,
        token,
        token_type
      ) do
    case db_context().auth_set_token_as_used_by_token(
           username,
           user_id,
           request_id,
           token,
           token_type,
           RequestContext.to_context_map(ctx)
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :operation_failed}
      error -> error
    end
  end

  @doc """
  Sets a token as failed.

  Calls `auth.set_token_as_failed`.
  """
  @spec set_token_as_failed(RequestContext.t(), String.t() | nil, String.t(), String.t()) ::
          {:ok, map()} | {:error, any()}
  def set_token_as_failed(
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id} = ctx,
        token_uid,
        token,
        token_type_code
      ) do
    case db_context().auth_set_token_as_failed(
           username,
           user_id,
           request_id,
           token_uid,
           token,
           token_type_code,
           RequestContext.to_context_map(ctx)
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :operation_failed}
      error -> error
    end
  end

  @doc """
  Sets a token as failed by token value.

  Calls `auth.set_token_as_failed_by_token`.
  """
  @spec set_token_as_failed_by_token(RequestContext.t(), String.t(), String.t()) ::
          {:ok, map()} | {:error, any()}
  def set_token_as_failed_by_token(
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id} = ctx,
        token,
        token_type
      ) do
    case db_context().auth_set_token_as_failed_by_token(
           username,
           user_id,
           request_id,
           token,
           token_type,
           RequestContext.to_context_map(ctx)
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
  Creates a user event.

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
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id} = ctx,
        event_type_code,
        target_user_id,
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
           RequestContext.to_context_map(ctx),
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
  Creates a user event with a payload map.

  Calls `auth.create_user_event` with JSON-encoded payload.
  """
  @spec create_event_with_payload(
          RequestContext.t(),
          String.t(),
          integer() | nil,
          map()
        ) :: {:ok, map()} | {:error, any()}
  def create_event_with_payload(
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id} = ctx,
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
           RequestContext.to_context_map(ctx),
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
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id},
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
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id},
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
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id},
        provider_code
      ) do
    case db_context().auth_delete_provider(
           username,
           user_id,
           request_id,
           provider_code
         )
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
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id},
        provider_code
      ) do
    case db_context().auth_enable_provider(
           username,
           user_id,
           request_id,
           provider_code
         )
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
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id},
        provider_code
      ) do
    case db_context().auth_disable_provider(
           username,
           user_id,
           request_id,
           provider_code
         )
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
        %RequestContext{user: %User{username: username, user_id: user_id}, request_id: request_id},
        provider_code
      ) do
    db_context().auth_get_provider_users(
      username,
      user_id,
      request_id,
      provider_code
    )
    |> ErrorParsers.parse_if_error()
  end
end
