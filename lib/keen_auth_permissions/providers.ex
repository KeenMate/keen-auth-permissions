defmodule KeenAuthPermissions.Providers do
  @moduledoc """
  Facade for authentication-provider setup.

  A "provider" is an external identity source (Entra ID, Google, GitHub, ...) that
  ppm trusts to authenticate users and, optionally, to vend group memberships.

  This module wraps the upsert-style ("ensure") helpers used during application
  bootstrap — define your providers and any external-group → internal-group
  mappings declaratively at startup; the SP no-ops if the row already matches.

  ## Capability flags

  - `is_active` — provider can be used for login at all
  - `allows_group_mapping` — external group memberships can be mapped to internal groups
  - `allows_group_sync` — provider supports periodic membership refresh (implies mapping)

  ## Examples

      # Bootstrap a single provider
      Providers.ensure(
        ctx, "entra", "Microsoft Entra ID",
        is_active: true,
        allows_group_mapping: true,
        allows_group_sync: true
      )

      # Map an external (e.g. AD) group object id to an internal user_group
      Providers.ensure_group_mapping(
        ctx, group.user_group_id, "entra",
        "object-id-12345", "AD: Engineers", nil, tenant_id
      )
  """

  alias KeenAuthPermissions.User
  alias KeenAuthPermissions.RequestContext
  alias KeenAuthPermissions.Error.ErrorParsers

  defp db_context(), do: KeenAuthPermissions.DbContext.get_global_db_context()

  @doc """
  Upserts a provider definition.

  Idempotent — safe to call on every boot. Returns the resulting provider row.

  Options (all default to `false` except where noted):
    * `:is_active` — defaults to `true`
    * `:allows_group_mapping`
    * `:allows_group_sync`
    * `:tenant_id` — defaults to `1`

  Calls `auth.ensure_provider`.
  """
  @spec ensure(RequestContext.t(), String.t(), String.t(), keyword()) ::
          {:ok, map()} | {:error, any()}
  def ensure(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        provider_code,
        provider_name,
        opts \\ []
      ) do
    is_active = Keyword.get(opts, :is_active, true)
    allows_group_mapping = Keyword.get(opts, :allows_group_mapping, false)
    allows_group_sync = Keyword.get(opts, :allows_group_sync, false)
    tenant_id = Keyword.get(opts, :tenant_id, 1)

    case db_context().auth_ensure_provider(
           username,
           user_id,
           request_id,
           provider_code,
           provider_name,
           is_active,
           allows_group_mapping,
           allows_group_sync,
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :ensure_failed}
      error -> error
    end
  end

  @doc """
  Upserts a mapping from an external provider group/role onto an internal user_group.

  Used to declaratively wire AD/Entra group object ids (or any external group key)
  to an internal `user_group_id`. Idempotent.

  The provider must have been created with `allows_group_mapping: true` —
  otherwise the SP raises (validated by `auth.validate_provider_allows_group_mapping`).

  Calls `auth.ensure_user_group_mapping`.
  """
  @spec ensure_group_mapping(
          RequestContext.t(),
          integer(),
          String.t(),
          String.t(),
          String.t() | nil,
          String.t() | nil,
          integer()
        ) :: {:ok, map()} | {:error, any()}
  def ensure_group_mapping(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        user_group_id,
        provider_code,
        mapped_object_id,
        mapped_object_name \\ nil,
        mapped_role \\ nil,
        tenant_id \\ 1
      ) do
    case db_context().auth_ensure_user_group_mapping(
           username,
           user_id,
           request_id,
           user_group_id,
           provider_code,
           mapped_object_id,
           mapped_object_name,
           mapped_role,
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :ensure_failed}
      error -> error
    end
  end
end
