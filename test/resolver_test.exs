defmodule KeenAuthPermissions.ResolverTest do
  use KeenAuthPermissions.DataCase, async: false

  alias KeenAuthPermissions.Resolver

  describe "user/1" do
    test "resolves a bigint-as-string to the same user_id" do
      assert {:ok, 1} = Resolver.user("1")
    end

    test "resolves a uuid-shaped non-existent identifier to :not_found" do
      # Pure happy path beyond bigint requires a known seed code/uuid which
      # ppm doesn't currently expose, so we just smoke-test the uuid branch.
      uuid = "00000000-0000-0000-0000-000000000000"
      assert match?({:error, _}, Resolver.user(uuid))
    end

    test "errors for an unknown identifier" do
      assert {:error, _} = Resolver.user("definitely_no_such_user_#{:rand.uniform(10_000_000)}")
    end
  end

  describe "tenant/1" do
    test "resolves integer id as string" do
      assert {:ok, 1} = Resolver.tenant("1")
    end

    test "errors for an unknown tenant" do
      assert {:error, _} = Resolver.tenant("unknown_tenant_#{:rand.uniform(10_000_000)}")
    end
  end

  describe "group/2" do
    test "errors when the group doesn't exist in the tenant" do
      assert {:error, _} =
               Resolver.group("no_such_group_#{:rand.uniform(10_000_000)}", default_tenant_id())
    end
  end
end
