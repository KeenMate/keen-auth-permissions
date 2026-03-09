# This module provides a clean API for blacklist operations.
# It wraps the auto-generated database context functions with a cleaner interface.

defmodule KeenAuthPermissions.Blacklist do
  @moduledoc """
  Clean facade API for blacklist management operations.

  Allows adding, removing, searching, and checking blacklisted users/identities.

  ## Examples

      # Add a user to the blacklist
      KeenAuthPermissions.Blacklist.create(context, "john", "azure", "uid", "oid", "violation", "notes", tenant_id)

      # Check if a user is blacklisted
      KeenAuthPermissions.Blacklist.is_blacklisted?("john", "azure", "uid", "oid")

      # Search the blacklist
      KeenAuthPermissions.Blacklist.search(context, "john", nil, 1, 20, tenant_id)
  """

  alias KeenAuthPermissions.User
  alias KeenAuthPermissions.RequestContext
  alias KeenAuthPermissions.Error.ErrorParsers

  defp db_context(), do: KeenAuthPermissions.DbContext.get_global_db_context()

  @doc """
  Creates a blacklist entry for a user.

  Calls `auth.create_blacklist_user`.
  """
  @spec create(
          RequestContext.t(),
          String.t(),
          String.t(),
          String.t(),
          String.t(),
          String.t() | nil,
          String.t() | nil,
          integer()
        ) :: {:ok, map()} | {:error, any()}
  def create(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        target_username,
        provider_code,
        provider_uid,
        provider_oid,
        reason,
        notes,
        tenant_id
      ) do
    case db_context().auth_create_blacklist_user(
           username,
           user_id,
           request_id,
           target_username,
           provider_code,
           provider_uid,
           provider_oid,
           reason,
           notes,
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :create_failed}
      error -> error
    end
  end

  @doc """
  Deletes a blacklist entry.

  Calls `auth.delete_blacklist_user`.
  """
  @spec delete(RequestContext.t(), integer(), integer()) :: {:ok, map()} | {:error, any()}
  def delete(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        blacklist_id,
        tenant_id
      ) do
    case db_context().auth_delete_blacklist_user(
           username,
           user_id,
           request_id,
           blacklist_id,
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :delete_failed}
      error -> error
    end
  end

  @doc """
  Searches the blacklist with filters.

  The blacklist operates at the application level, not per-tenant — a blacklisted user
  is blocked from logging into the entire application. One tenant cannot blacklist a user
  while another allows them access.

  Calls `auth.search_blacklist`.
  """
  @spec search(
          RequestContext.t(),
          String.t() | nil,
          String.t() | nil,
          integer(),
          integer(),
          integer()
        ) ::
          {:ok, list()} | {:error, any()}
  def search(
        %RequestContext{user: %User{user_id: user_id}, request_id: request_id},
        search_text,
        reason,
        page,
        page_size,
        tenant_id
      ) do
    db_context().auth_search_blacklist(
      user_id,
      request_id,
      search_text,
      reason,
      page,
      page_size,
      tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Checks if a user/identity is blacklisted.

  This is a public check that does not require a RequestContext.

  Calls `auth.is_blacklisted`.
  """
  @spec is_blacklisted?(String.t(), String.t(), String.t(), String.t()) ::
          {:ok, boolean()} | {:error, any()}
  def is_blacklisted?(username, provider_code, provider_uid, provider_oid) do
    case db_context().auth_is_blacklisted(username, provider_code, provider_uid, provider_oid) do
      {:ok, [%{is_blacklisted: result}]} -> {:ok, result}
      {:ok, []} -> {:ok, false}
      error -> error
    end
  end
end
