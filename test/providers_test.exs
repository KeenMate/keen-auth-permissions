defmodule KeenAuthPermissions.ProvidersTest do
  use KeenAuthPermissions.DataCase, async: false

  alias KeenAuthPermissions.Providers

  describe "ensure/4" do
    test "is idempotent — second call with same code returns ok" do
      ctx = system_context()
      code = "prov_#{unique_string()}"

      assert {:ok, _first} = Providers.ensure(ctx, code, "Ephemeral provider")

      assert {:ok, _second} =
               Providers.ensure(ctx, code, "Ephemeral provider",
                 is_active: true,
                 allows_group_mapping: true
               )
    end

    test "honors capability opts (no crash on group-mapping-enabled creation)" do
      ctx = system_context()
      code = "prov_caps_#{unique_string()}"

      assert {:ok, _} =
               Providers.ensure(ctx, code, "Capable",
                 allows_group_mapping: true,
                 allows_group_sync: true
               )
    end
  end

  describe "ensure_group_mapping/7" do
    test "wires an external object id to an internal user_group via a mapping-capable provider" do
      ctx = system_context()
      provider = ensure_entra_provider()
      {:ok, group} = create_test_group(ctx, %{is_external: true})

      assert {:ok, _} =
               Providers.ensure_group_mapping(
                 ctx,
                 group.user_group_id,
                 provider,
                 "obj-#{unique_string()}",
                 "External Group Display",
                 nil,
                 default_tenant_id()
               )
    end
  end
end
