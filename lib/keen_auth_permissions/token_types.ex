# This module provides a clean API for token type operations.
# It wraps the auto-generated database context functions with a cleaner interface.

defmodule KeenAuthPermissions.TokenTypes do
  @moduledoc """
  Clean facade API for token type management operations.

  Token types define the categories of tokens that can be created (e.g., "email_confirmation",
  "password_reset"). Each token type has a code, optional default expiration, and a system flag.

  ## Examples

      # List all token types
      KeenAuthPermissions.TokenTypes.list()

      # Create a new token type
      KeenAuthPermissions.TokenTypes.create(request_context, "email_confirmation", 86400, tenant_id)

      # Ensure a token type exists (create if missing)
      KeenAuthPermissions.TokenTypes.ensure_exists(request_context, "email_confirmation", 86400, tenant_id)
  """

  alias KeenAuthPermissions.User
  alias KeenAuthPermissions.RequestContext
  alias KeenAuthPermissions.Error.ErrorParsers

  defp db_context(), do: KeenAuthPermissions.DbContext.get_global_db_context()

  # ============================================================================
  # Query Operations
  # ============================================================================

  @doc """
  Lists all token types.

  Calls `public.get_token_types`.
  """
  @spec list() :: {:ok, list()} | {:error, any()}
  def list do
    db_context().get_token_types()
    |> ErrorParsers.parse_if_error()
  end

  # ============================================================================
  # CRUD Operations
  # ============================================================================

  @doc """
  Creates a new token type.

  Calls `public.create_token_type`.
  """
  @spec create(RequestContext.t(), String.t(), integer(), integer()) ::
          {:ok, map()} | {:error, any()}
  def create(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        code,
        default_expiration_in_seconds,
        tenant_id
      ) do
    case db_context().create_token_type(
           username,
           user_id,
           request_id,
           code,
           default_expiration_in_seconds,
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :creation_failed}
      error -> error
    end
  end

  @doc """
  Updates a token type.

  Calls `public.update_token_type`.
  """
  @spec update(RequestContext.t(), String.t(), integer(), integer()) ::
          {:ok, map()} | {:error, any()}
  def update(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        code,
        default_expiration_in_seconds,
        tenant_id
      ) do
    case db_context().update_token_type(
           username,
           user_id,
           request_id,
           code,
           default_expiration_in_seconds,
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :update_failed}
      error -> error
    end
  end

  @doc """
  Deletes a token type.

  Calls `public.delete_token_type`.
  """
  @spec delete(RequestContext.t(), String.t(), integer()) :: :ok | {:error, any()}
  def delete(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        code,
        tenant_id
      ) do
    case db_context().delete_token_type(username, user_id, request_id, code, tenant_id) do
      :ok -> :ok
      {:error, _} = error -> error
    end
  end

  # ============================================================================
  # Convenience Operations
  # ============================================================================

  @doc """
  Ensures a token type with the given code exists. Creates it if missing.

  Returns `{:ok, :exists}` if already present, `{:ok, result}` if created,
  or `{:error, reason}` on failure.

  ## Examples

      ctx = RequestContext.system_ctx()
      TokenTypes.ensure_exists(ctx, "email_confirmation", 86400, tenant_id)
  """
  @spec ensure_exists(RequestContext.t(), String.t(), integer(), integer()) ::
          {:ok, :exists | map()} | {:error, any()}
  def ensure_exists(%RequestContext{} = ctx, code, default_expiration_in_seconds, tenant_id) do
    case list() do
      {:ok, types} ->
        if Enum.any?(types, &(&1.code == code)) do
          {:ok, :exists}
        else
          create(ctx, code, default_expiration_in_seconds, tenant_id)
        end

      {:error, _} = error ->
        error
    end
  end
end
