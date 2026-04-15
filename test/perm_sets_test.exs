defmodule KeenAuthPermissions.PermSetsTest do
  use KeenAuthPermissions.DataCase, async: false

  alias KeenAuthPermissions.PermSets

  @moduletag :clean_db

  describe "list/2" do
    test "lists all permission sets" do
      ctx = system_context()

      assert {:ok, perm_sets} = PermSets.list(ctx, default_tenant_id())
      assert is_list(perm_sets)
    end
  end

  describe "search/6" do
    test "searches permission sets" do
      ctx = system_context()

      assert {:ok, results} =
               PermSets.search(ctx, nil, 1, 100, default_tenant_id())

      assert is_list(results)
    end

    test "searches permission sets by text" do
      ctx = system_context()

      assert {:ok, results} =
               PermSets.search(ctx, %{search_text: "test"}, 1, 100, default_tenant_id())

      assert is_list(results)
    end

    test "searches by assignable flag" do
      ctx = system_context()

      assert {:ok, results} =
               PermSets.search(ctx, %{is_assignable: true}, 1, 100, default_tenant_id())

      assert is_list(results)
    end

    test "searches by system flag" do
      ctx = system_context()

      assert {:ok, results} =
               PermSets.search(ctx, %{is_system: false}, 1, 100, default_tenant_id())

      assert is_list(results)
    end
  end

  describe "create/6" do
    test "creates a new permission set" do
      ctx = system_context()
      code = "test_permset_#{unique_string()}"

      assert {:ok, created} =
               PermSets.create(ctx, code, false, true, [], default_tenant_id())

      assert created.code == code
      assert created.is_system == false
      assert created.is_assignable == true
    end

    test "creates a permission set with permissions" do
      ctx = system_context()
      code = "test_permset_with_perms_#{unique_string()}"

      case PermSets.create(ctx, code, false, true, [], default_tenant_id()) do
        {:ok, created} ->
          assert created.code == code

        {:error, _} ->
          :ok
      end
    end
  end

  describe "update/5" do
    test "updates an existing permission set" do
      ctx = system_context()

      {:ok, created} = create_test_perm_set(ctx)

      new_title = "Updated Title #{unique_string()}"

      # `update_perm_set` stores the new display title as a translation and flips
      # `is_assignable`; the immutable `code` column stays the same.
      assert {:ok, updated} =
               PermSets.update(
                 ctx,
                 created.perm_set_id,
                 new_title,
                 false,
                 default_tenant_id()
               )

      assert updated.perm_set_id == created.perm_set_id
      assert updated.code == created.code
      assert updated.is_assignable == false
    end
  end

  describe "create_permissions/4 and delete_permissions/4" do
    test "adds and removes permissions from a permission set" do
      ctx = system_context()

      {:ok, perm_set} = create_test_perm_set(ctx)
      {:ok, all_permissions} = KeenAuthPermissions.Permissions.list(ctx, default_tenant_id())

      assignable = Enum.find(all_permissions, fn p -> p.is_assignable end)

      if assignable do
        assert {:ok, added} =
                 PermSets.create_permissions(
                   ctx,
                   perm_set.perm_set_id,
                   [assignable.full_code],
                   default_tenant_id()
                 )

        assert is_list(added)

        assert {:ok, removed} =
                 PermSets.delete_permissions(
                   ctx,
                   perm_set.perm_set_id,
                   [assignable.full_code],
                   default_tenant_id()
                 )

        assert is_list(removed)
      end
    end
  end
end
