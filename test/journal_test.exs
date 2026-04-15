defmodule KeenAuthPermissions.JournalTest do
  use KeenAuthPermissions.DataCase, async: false

  alias KeenAuthPermissions.Journal

  # Seeded by ppm: (event_id: 10001, code: "user_created", category: "user_event")
  @seeded_event_id 10001
  @seeded_event_code "user_created"

  describe "create/5 and create_by_code/5" do
    test "creates an entry by numeric event_id" do
      ctx = system_context()

      assert {:ok, _result} =
               Journal.create(
                 ctx,
                 @seeded_event_id,
                 %{"fixture" => unique_string()},
                 %{"source" => "test", "note" => "backend-created"},
                 default_tenant_id()
               )
    end

    test "creates an entry by event code" do
      ctx = system_context()

      assert {:ok, _result} =
               Journal.create_by_code(
                 ctx,
                 @seeded_event_code,
                 %{"fixture" => unique_string()},
                 %{"source" => "test"},
                 default_tenant_id()
               )
    end
  end

  describe "create_for_entity/6 and create_for_entity_by_code/6" do
    test "creates an entity-tagged entry by event_id" do
      ctx = system_context()

      assert {:ok, _result} =
               Journal.create_for_entity(
                 ctx,
                 @seeded_event_id,
                 "user",
                 ctx.user.user_id,
                 %{"fixture" => unique_string()},
                 default_tenant_id()
               )
    end

    test "creates an entity-tagged entry by event code" do
      ctx = system_context()

      assert {:ok, _result} =
               Journal.create_for_entity_by_code(
                 ctx,
                 @seeded_event_code,
                 "user",
                 ctx.user.user_id,
                 %{"fixture" => unique_string()},
                 default_tenant_id()
               )
    end
  end

  describe "search/12 and get/3" do
    @tag :skip
    # BLOCKED: upstream `public.search_journal_msgs` calls `public.search_journal`
    # with a bare `null` for the `_event_category` argument — Postgres can't
    # resolve the overload and raises "function search_journal(..., unknown, ...)
    # does not exist". Needs `null::text` cast in the inner call (018_functions_public.sql).
    test "can find an entry we just created" do
      ctx = system_context()
      marker = unique_string()

      {:ok, _} =
        Journal.create_by_code(
          ctx,
          @seeded_event_code,
          %{"fixture" => marker},
          %{"marker" => marker},
          default_tenant_id()
        )

      assert {:ok, results} =
               Journal.search(
                 ctx,
                 nil,
                 nil,
                 nil,
                 nil,
                 @seeded_event_id,
                 nil,
                 nil,
                 nil,
                 nil,
                 1,
                 50,
                 default_tenant_id()
               )

      assert is_list(results)
      assert length(results) > 0
    end

    test "get/3 returns :not_found for a non-existent id" do
      ctx = system_context()
      assert {:error, :not_found} = Journal.get(ctx, -1, default_tenant_id())
    end
  end

  describe "helpers" do
    test "format_message/3 substitutes payload values into a template" do
      assert {:ok, text} =
               Journal.format_message("Hello {name}", %{"name" => "world"}, "system")

      assert is_binary(text)
    end
  end
end
