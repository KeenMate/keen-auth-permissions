defmodule KeenAuthPermissions.PermissionsMapTest do
  use KeenAuthPermissions.DataCase, async: false

  alias KeenAuthPermissions.PermissionsMap

  setup_all do
    # Start a fresh instance under the module name for the whole test module.
    case PermissionsMap.start_link([]) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end

    :ok
  end

  describe "has?/2 and lookups" do
    test "returns false for a user missing the required permission" do
      user = %{permissions: []}
      refute PermissionsMap.has?(user, "nonexistent.perm")
    end

    test "has?/2 with non-user input returns false" do
      refute PermissionsMap.has?(nil, "anything")
      refute PermissionsMap.has?(%{}, "anything")
    end

    test "has_any?/2 and has_all?/2 handle empty permission lists" do
      user = %{permissions: []}
      refute PermissionsMap.has_any?(user, ["a", "b"])
      refute PermissionsMap.has_all?(user, ["a", "b"])
    end
  end

  describe "full_to_short/1 and short_to_full/1" do
    test "round-trips when the code exists, returns nil when it doesn't" do
      # Permission "system_admin" is seeded by ppm's auth.seed_permission_data.
      case PermissionsMap.full_to_short("system_admin") do
        nil -> :ok
        short ->
          assert is_binary(short)
          assert PermissionsMap.short_to_full(short) == "system_admin"
      end

      assert PermissionsMap.full_to_short("definitely.no.such.perm") == nil
      assert PermissionsMap.short_to_full("99.99.99") == nil
    end
  end

  describe "resolve_permissions/1 and reload/0" do
    test "returns a list for a list of short codes" do
      assert is_list(PermissionsMap.resolve_permissions(["99.99"]))
    end

    test "reload/0 succeeds" do
      assert :ok = PermissionsMap.reload()
    end
  end
end
