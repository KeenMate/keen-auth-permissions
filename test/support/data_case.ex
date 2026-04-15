defmodule KeenAuthPermissions.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring database access.

  It provides helpers for creating test data and cleaning up after tests.
  """

  use ExUnit.CaseTemplate

  alias KeenAuthPermissions.TestRepo
  alias KeenAuthPermissions.User
  alias KeenAuthPermissions.RequestContext

  using do
    quote do
      alias KeenAuthPermissions.TestRepo
      alias KeenAuthPermissions.TestDatabase
      alias KeenAuthPermissions.User
      alias KeenAuthPermissions.RequestContext

      import KeenAuthPermissions.DataCase
      import KeenAuthPermissions.TestFactory
    end
  end

  setup_all do
    # Ensure the repo is started
    case TestRepo.start_link() do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
      {:error, reason} -> raise "Failed to start TestRepo: #{inspect(reason)}"
    end

    # Ensure token states are seeded
    ensure_token_states()

    :ok
  end

  defp ensure_token_states do
    # Seed const.token_state if not already present
    # Note: 'invalid' is used by auth.create_token when invalidating previous tokens
    TestRepo.query!("""
      INSERT INTO const.token_state (code) VALUES
        ('valid'),
        ('used'),
        ('expired'),
        ('failed'),
        ('validation_failed'),
        ('invalid')
      ON CONFLICT (code) DO NOTHING
    """)

    # Also seed const.token_channel if needed
    TestRepo.query!("""
      INSERT INTO const.token_channel (code) VALUES
        ('email'),
        ('sms'),
        ('app')
      ON CONFLICT (code) DO NOTHING
    """)

    # Also seed const.token_type if needed
    TestRepo.query!("""
      INSERT INTO const.token_type (code, default_expiration_in_seconds) VALUES
        ('password_reset', 3600),
        ('email_verification', 86400),
        ('invite', 604800),
        ('mfa', 300)
      ON CONFLICT (code) DO NOTHING
    """)
  end

  setup tags do
    # Clean up test data before each test if tagged
    if tags[:clean_db] do
      clean_test_data()
    end

    :ok
  end

  @doc """
  Creates a system user for test operations.
  """
  def system_user do
    %User{
      user_id: 1,
      code: "system",
      uuid: nil,
      username: "system",
      email: nil,
      display_name: "System",
      groups: [],
      permissions: []
    }
  end

  @doc """
  Creates a system request context for test operations.
  """
  def system_context do
    RequestContext.new(system_user())
  end

  @doc """
  Creates a request context from a user.
  """
  def context(%User{} = user), do: RequestContext.new(user)
  def context(%RequestContext{} = ctx), do: ctx

  @doc """
  Creates a test user struct with the given attributes.
  """
  def build_user(attrs \\ %{}) do
    defaults = %{
      user_id: 1,
      code: "test_user",
      uuid: nil,
      username: "test_user",
      email: "test@example.com",
      display_name: "Test User",
      groups: [],
      permissions: []
    }

    struct(User, Map.merge(defaults, attrs))
  end

  @doc """
  Cleans up test data from the database.

  This removes any data created during tests while preserving system data.
  """
  def clean_test_data do
    # Cleanup disabled - schema columns differ from expected
    # TODO: Update cleanup queries to match actual database schema
    # or use stored procedures for cleanup instead of direct SQL
    :ok
  end

  @doc """
  Gets the default tenant ID for tests.
  """
  def default_tenant_id, do: 1

  @doc """
  Ensures the `entra` provider exists with `allows_group_mapping` and `allows_group_sync`
  both `true`. Returns the provider code so tests can use it as the value for `_provider_code`.

  Used to be `aad` — ppm no longer seeds it, so tests that exercise group-mapping create
  their own capability-enabled provider.
  """
  def ensure_entra_provider do
    KeenAuthPermissions.Providers.ensure(
      system_context(),
      "entra",
      "Microsoft Entra ID",
      is_active: true,
      allows_group_mapping: true,
      allows_group_sync: true
    )

    "entra"
  end

  @doc """
  Generates a unique string for test data.
  """
  def unique_string(prefix \\ "test") do
    # Combine a per-VM monotonic integer with system time microseconds so
    # values stay unique across separate test-VM runs (the integer alone
    # restarts at 0 each VM boot, which collides with rows left in the DB
    # by previous runs).
    "#{prefix}_#{System.system_time(:microsecond)}_#{:erlang.unique_integer([:positive])}"
  end
end
