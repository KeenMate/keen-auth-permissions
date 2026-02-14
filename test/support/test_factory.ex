defmodule KeenAuthPermissions.TestFactory do
  @moduledoc """
  Factory functions for creating test data.

  These functions help create test data in a consistent way across all tests.
  """

  alias KeenAuthPermissions.UserGroups
  alias KeenAuthPermissions.Users
  alias KeenAuthPermissions.Tenants
  alias KeenAuthPermissions.PermSets
  alias KeenAuthPermissions.ApiKeys
  alias KeenAuthPermissions.Auth
  alias KeenAuthPermissions.User
  alias KeenAuthPermissions.RequestContext

  # Helper to ensure we have a RequestContext
  defp to_context(%RequestContext{} = ctx), do: ctx
  defp to_context(%User{} = user), do: RequestContext.new(user)

  @doc """
  Creates a test user group.
  """
  def create_test_group(user, attrs \\ %{}) do
    defaults = %{
      title: "Test Group #{unique_id()}",
      is_assignable: true,
      is_active: true,
      is_external: false,
      is_default: false,
      tenant_id: 1
    }

    params = Map.merge(defaults, attrs)

    UserGroups.create(
      to_context(user),
      params.title,
      params.is_assignable,
      params.is_active,
      params.is_external,
      params.is_default,
      params.tenant_id
    )
  end

  @doc """
  Creates a test tenant.
  """
  def create_test_tenant(user, attrs \\ %{}) do
    code = "test_tenant_#{unique_id()}"
    ctx = to_context(user)

    defaults = %{
      title: "Test Tenant #{unique_id()}",
      code: code,
      is_removable: true,
      is_assignable: true,
      tenant_owner_id: ctx.user.user_id
    }

    params = Map.merge(defaults, attrs)

    Tenants.create(
      ctx,
      params.title,
      params.code,
      params.is_removable,
      params.is_assignable,
      params.tenant_owner_id
    )
  end

  @doc """
  Creates a test permission set.
  """
  def create_test_perm_set(user, attrs \\ %{}) do
    defaults = %{
      title: "Test PermSet #{unique_id()}",
      is_system: false,
      is_assignable: true,
      permissions: [],
      tenant_id: 1
    }

    params = Map.merge(defaults, attrs)

    PermSets.create(
      to_context(user),
      params.title,
      params.is_system,
      params.is_assignable,
      params.permissions,
      params.tenant_id
    )
  end

  @doc """
  Creates a test API key with generated key and secret.
  """
  def create_test_api_key(user, attrs \\ %{}) do
    {:ok, api_key} = ApiKeys.generate_key()
    {:ok, api_secret} = ApiKeys.generate_secret()

    defaults = %{
      title: "Test API Key #{unique_id()}",
      description: "Test API key for automated tests",
      perm_set_code: nil,
      permission_codes: [],
      api_key: api_key,
      api_secret: api_secret,
      expire_at: nil,
      notification_email: nil,
      tenant_id: 1
    }

    params = Map.merge(defaults, attrs)

    case ApiKeys.create(
           to_context(user),
           params.title,
           params.description,
           params.perm_set_code,
           params.permission_codes,
           params.api_key,
           params.api_secret,
           params.expire_at,
           params.notification_email,
           params.tenant_id
         ) do
      {:ok, result} ->
        # Return the original secret for validation tests
        {:ok, Map.put(result, :plain_secret, api_secret)}

      error ->
        error
    end
  end

  @doc """
  Creates a test user via registration.
  """
  def create_test_user(admin_user, attrs \\ %{}) do
    email = "test_#{unique_id()}@example.com"

    defaults = %{
      email: email,
      password_hash: "test_hash_#{unique_id()}",
      display_name: "Test User #{unique_id()}",
      user_data: nil
    }

    params = Map.merge(defaults, attrs)

    Users.register(
      to_context(admin_user),
      params.email,
      params.password_hash,
      params.display_name,
      params.user_data
    )
  end

  @doc """
  Creates a test user event.
  """
  def create_user_logged_in(user, attrs \\ %{}) do
    ctx = to_context(user)

    defaults = %{
      event_type_code: "user_logged_in",
      target_user_id: ctx.user.user_id,
      ip_address: "127.0.0.1",
      user_agent: "TestAgent/1.0",
      origin: "test",
      event_data: nil,
      target_user_oid: nil,
      target_username: nil
    }

    params = Map.merge(defaults, attrs)

    Auth.create_event(
      ctx,
      params.event_type_code,
      params.target_user_id,
      params.ip_address,
      params.user_agent,
      params.origin,
      params.event_data,
      params.target_user_oid,
      params.target_username
    )
  end

  defp unique_id do
    # Combine timestamp and unique_integer to ensure uniqueness across VM restarts
    timestamp = System.system_time(:microsecond) |> rem(10_000_000)
    counter = :erlang.unique_integer([:positive]) |> rem(10_000)
    "#{timestamp}_#{counter}"
  end
end
