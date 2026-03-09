defmodule KeenAuthPermissions.Resolver do
  @moduledoc """
  Resolves user-facing identifiers (UUID, code) into internal database IDs.

  These functions allow applications to avoid exposing internal integer IDs
  (user_id, tenant_id, user_group_id) to clients. Instead, clients can use
  UUIDs or codes, and the resolver translates them to the internal IDs needed
  by other API calls.

  ## Accepted identifier formats

  | Function          | Accepts                          | Returns            | Error code |
  |-------------------|----------------------------------|--------------------|------------|
  | `resolve_user`    | bigint, UUID, or code as text    | `user_id` (bigint) | 33020      |
  | `resolve_tenant`  | integer, UUID, or code as text   | `tenant_id` (int)  | 34003      |
  | `resolve_group`   | integer or code as text          | `user_group_id`    | 33021      |

  ## Examples

      iex> Resolver.user("a1b2c3d4-...")
      {:ok, 42}

      iex> Resolver.tenant("acme")
      {:ok, 3}

      iex> Resolver.group("owners", 3)
      {:ok, 17}
  """

  alias KeenAuthPermissions.Error.ErrorParsers

  defp db_context(), do: KeenAuthPermissions.DbContext.get_global_db_context()

  @doc """
  Resolves a user identifier (bigint, UUID, or code) to a `user_id`.

  Calls `internal.resolve_user`.
  """
  @spec user(String.t()) :: {:ok, integer()} | {:error, any()}
  def user(identifier) do
    case db_context().internal_resolve_user(to_string(identifier))
         |> ErrorParsers.parse_if_error() do
      {:ok, [%{resolve_user: user_id}]} -> {:ok, user_id}
      {:ok, []} -> {:error, :not_found}
      error -> error
    end
  end

  @doc """
  Resolves a tenant identifier (integer, UUID, or code) to a `tenant_id`.

  Calls `internal.resolve_tenant`.
  """
  @spec tenant(String.t()) :: {:ok, integer()} | {:error, any()}
  def tenant(identifier) do
    case db_context().internal_resolve_tenant(to_string(identifier))
         |> ErrorParsers.parse_if_error() do
      {:ok, [%{resolve_tenant: tenant_id}]} -> {:ok, tenant_id}
      {:ok, []} -> {:error, :not_found}
      error -> error
    end
  end

  @doc """
  Resolves a group identifier (integer or code) to a `user_group_id` within a tenant.

  Calls `internal.resolve_group`.
  """
  @spec group(String.t(), integer()) :: {:ok, integer()} | {:error, any()}
  def group(identifier, tenant_id) do
    case db_context().internal_resolve_group(to_string(identifier), tenant_id)
         |> ErrorParsers.parse_if_error() do
      {:ok, [%{resolve_group: group_id}]} -> {:ok, group_id}
      {:ok, []} -> {:error, :not_found}
      error -> error
    end
  end
end
