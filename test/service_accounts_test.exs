defmodule KeenAuthPermissions.ServiceAccountsTest do
  use ExUnit.Case, async: true

  alias KeenAuthPermissions.ServiceAccounts
  alias KeenAuthPermissions.User

  describe "get/1" do
    test "returns defaults for every built-in account" do
      for name <- [:system, :registrator, :authenticator, :token_manager, :api_gateway, :group_syncer, :data_processor] do
        info = ServiceAccounts.get(name)
        assert is_integer(info.user_id)
        assert is_binary(info.username)
        assert is_binary(info.display_name)
        assert is_binary(info.email)
      end
    end

    test "raises when asked for an unknown account with no config" do
      assert_raise ArgumentError, fn ->
        ServiceAccounts.get(:definitely_not_registered)
      end
    end
  end

  describe "user/1" do
    test "returns a %User{} struct for a built-in account" do
      assert %User{} = user = ServiceAccounts.user(:authenticator)
      assert user.user_id == 3
      assert user.username == "svc_authenticator"
    end
  end

  describe "names/0" do
    test "includes every built-in account name" do
      names = ServiceAccounts.names()

      for expected <- [:system, :registrator, :authenticator, :token_manager, :api_gateway, :group_syncer, :data_processor] do
        assert expected in names
      end
    end
  end
end
