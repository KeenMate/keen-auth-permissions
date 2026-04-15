defmodule KeenAuthPermissions.BlacklistTest do
  use KeenAuthPermissions.DataCase, async: false

  alias KeenAuthPermissions.Blacklist

  @moduletag :clean_db

  describe "search/5" do
    test "lists blacklist entries" do
      ctx = system_context()
      assert {:ok, results} = Blacklist.search(ctx, nil, 1, 100, default_tenant_id())
      assert is_list(results)
    end
  end

  describe "is_blacklisted?/4" do
    test "returns false for an unknown identity" do
      uniq = unique_string()

      assert {:ok, false} =
               Blacklist.is_blacklisted?("never_blacklisted_#{uniq}", "email", uniq, uniq)
    end
  end

  describe "create/8 and delete/3" do
    test "creates and deletes a blacklist entry" do
      ctx = system_context()
      username = "blocked_#{unique_string()}"
      provider_uid = "uid_#{unique_string()}"
      provider_oid = "oid_#{unique_string()}"

      assert {:ok, created} =
               Blacklist.create(
                 ctx,
                 username,
                 "email",
                 provider_uid,
                 provider_oid,
                 "violation",
                 "test entry",
                 default_tenant_id()
               )

      assert {:ok, true} =
               Blacklist.is_blacklisted?(username, "email", provider_uid, provider_oid)

      # Model only exposes the returning scalar under this key.
      id = Map.get(created, :create_blacklist_user)
      assert is_integer(id)

      assert {:ok, _} = Blacklist.delete(ctx, id, default_tenant_id())

      assert {:ok, false} =
               Blacklist.is_blacklisted?(username, "email", provider_uid, provider_oid)
    end
  end
end
