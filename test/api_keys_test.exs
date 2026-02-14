defmodule KeenAuthPermissions.ApiKeysTest do
  use KeenAuthPermissions.DataCase, async: false

  alias KeenAuthPermissions.ApiKeys

  @moduletag :clean_db

  describe "generation functions" do
    test "generate_key/0 generates a unique API key" do
      assert {:ok, key1} = ApiKeys.generate_key()
      assert {:ok, key2} = ApiKeys.generate_key()

      assert is_binary(key1)
      assert is_binary(key2)
      assert key1 != key2
    end

    test "generate_secret/0 generates a unique API secret" do
      assert {:ok, secret1} = ApiKeys.generate_secret()
      assert {:ok, secret2} = ApiKeys.generate_secret()

      assert is_binary(secret1)
      assert is_binary(secret2)
      assert secret1 != secret2
    end

    test "generate_secret_hash/1 generates a hash from a secret" do
      {:ok, secret} = ApiKeys.generate_secret()

      assert {:ok, hash} = ApiKeys.generate_secret_hash(secret)
      assert is_binary(hash)
      assert hash != secret
    end

    test "generate_username/1 generates a username from an API key" do
      {:ok, api_key} = ApiKeys.generate_key()

      assert {:ok, username} = ApiKeys.generate_username(api_key)
      assert is_binary(username)
    end
  end

  describe "search/5" do
    test "searches API keys" do
      ctx = system_context()

      assert {:ok, results} = ApiKeys.search(ctx, nil, 1, 100, default_tenant_id())
      assert is_list(results)
    end

    test "searches API keys by text" do
      ctx = system_context()

      assert {:ok, results} = ApiKeys.search(ctx, "test", 1, 100, default_tenant_id())
      assert is_list(results)
    end
  end

  describe "create/10, update/7, and delete/3" do
    test "creates a new API key" do
      ctx = system_context()

      {:ok, api_key} = ApiKeys.generate_key()
      {:ok, api_secret} = ApiKeys.generate_secret()

      assert {:ok, created} =
               ApiKeys.create(
                 ctx,
                 "Test API Key #{unique_string()}",
                 "Test description",
                 nil,
                 [],
                 api_key,
                 api_secret,
                 nil,
                 nil,
                 default_tenant_id()
               )

      assert is_binary(created.api_key)
    end

    test "updates an existing API key" do
      ctx = system_context()

      # Create an API key first
      {:ok, created} = create_test_api_key(ctx)

      new_title = "Updated API Key #{unique_string()}"

      assert {:ok, updated} =
               ApiKeys.update(
                 ctx,
                 created.api_key_id,
                 new_title,
                 "Updated description",
                 nil,
                 nil,
                 default_tenant_id()
               )

      assert updated.title == new_title
    end

    test "deletes an API key" do
      ctx = system_context()

      # Create an API key first
      {:ok, created} = create_test_api_key(ctx)

      # Delete it
      assert {:ok, _deleted} = ApiKeys.delete(ctx, created.api_key_id, default_tenant_id())
    end
  end

  describe "update_secret/4" do
    test "updates the API key secret" do
      ctx = system_context()

      {:ok, created} = create_test_api_key(ctx)
      {:ok, new_secret} = ApiKeys.generate_secret()

      assert {:ok, _updated} =
               ApiKeys.update_secret(
                 ctx,
                 created.api_key_id,
                 new_secret,
                 default_tenant_id()
               )
    end
  end

  describe "permission operations" do
    test "list_permissions/3 returns API key permissions" do
      ctx = system_context()

      {:ok, created} = create_test_api_key(ctx)

      assert {:ok, permissions} =
               ApiKeys.list_permissions(ctx, created.api_key_id, default_tenant_id())

      assert is_list(permissions)
    end
  end

  describe "validate/7" do
    test "validates an API key with correct credentials" do
      ctx = system_context()

      {:ok, created} = create_test_api_key(ctx)

      assert {:ok, result} =
               ApiKeys.validate(
                 ctx,
                 created.api_key,
                 created.plain_secret,
                 "127.0.0.1",
                 "TestAgent/1.0",
                 "test",
                 default_tenant_id()
               )

      assert is_map(result)
    end

    test "returns error for invalid API key" do
      ctx = system_context()

      assert {:error, _} =
               ApiKeys.validate(
                 ctx,
                 "invalid_key",
                 "invalid_secret",
                 "127.0.0.1",
                 "TestAgent/1.0",
                 "test",
                 default_tenant_id()
               )
    end
  end

  describe "outbound API key operations" do
    test "search_outbound/6 searches outbound API keys" do
      ctx = system_context()

      assert {:ok, results} =
               ApiKeys.search_outbound(ctx, nil, nil, 1, 100, default_tenant_id())

      assert is_list(results)
    end

    test "create_outbound/10 creates an outbound API key" do
      ctx = system_context()
      service_code = "test_service_#{unique_string()}"

      assert {:ok, created} =
               ApiKeys.create_outbound(
                 ctx,
                 "Test Outbound API Key #{unique_string()}",
                 "Test description",
                 service_code,
                 <<1, 2, 3, 4>>,
                 "https://api.example.com",
                 "{}",
                 nil,
                 nil,
                 default_tenant_id()
               )

      assert created.service_code == service_code
    end

    test "get_outbound/3 retrieves an outbound API key" do
      ctx = system_context()
      service_code = "test_service_#{unique_string()}"

      {:ok, _created} =
        ApiKeys.create_outbound(
          ctx,
          "Test Outbound Key",
          "Description",
          service_code,
          <<1, 2, 3>>,
          "https://api.example.com",
          "{}",
          nil,
          nil,
          default_tenant_id()
        )

      assert {:ok, fetched} =
               ApiKeys.get_outbound(ctx, service_code, default_tenant_id())

      assert fetched.service_code == service_code
    end

    test "delete_outbound/3 deletes an outbound API key" do
      ctx = system_context()
      service_code = "test_service_#{unique_string()}"

      {:ok, created} =
        ApiKeys.create_outbound(
          ctx,
          "Test Outbound Key",
          "Description",
          service_code,
          <<1, 2, 3>>,
          "https://api.example.com",
          "{}",
          nil,
          nil,
          default_tenant_id()
        )

      assert {:ok, _deleted} =
               ApiKeys.delete_outbound(ctx, created.api_key_id, default_tenant_id())
    end
  end
end
