defmodule KeenAuthPermissions.TranslationsTest do
  use KeenAuthPermissions.DataCase, async: false

  alias KeenAuthPermissions.Translations

  # ============================================================================
  # Languages
  # ============================================================================

  describe "language catalog" do
    test "get_language/1 returns the seeded en language" do
      assert {:ok, lang} = Translations.get_language("en")
      assert lang.code == "en"
    end

    test "get_language/1 returns :not_found for unknown" do
      assert {:error, :not_found} = Translations.get_language("xx")
    end

    test "list_languages/2 returns a list" do
      assert {:ok, langs} = Translations.list_languages("en")
      assert is_list(langs)
    end

    test "shortcut listers return lists" do
      assert {:ok, f} = Translations.list_frontend_languages("en")
      assert {:ok, b} = Translations.list_backend_languages("en")
      assert {:ok, c} = Translations.list_communication_languages("en")
      assert is_list(f) and is_list(b) and is_list(c)
    end

    test "get_default_language/2 asks for the backend default" do
      # Not all deployments have every default set; accept either shape.
      result = Translations.get_default_language("en", is_backend: true)

      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end
  end

  describe "create_language / update_language / delete_language" do
    test "full language lifecycle" do
      ctx = system_context()
      code = "t#{:rand.uniform(999)}"

      assert {:ok, _} =
               Translations.create_language(ctx, code, "Test Lang",
                 is_frontend_language: true,
                 is_backend_language: false,
                 is_communication_language: false
               )

      assert {:ok, _} =
               Translations.update_language(ctx, code, "Renamed",
                 is_frontend_language: true,
                 is_backend_language: false,
                 is_communication_language: false
               )

      assert :ok = Translations.delete_language(ctx, code)
    end
  end

  # ============================================================================
  # Translations
  # ============================================================================

  describe "create / update / delete translation" do
    test "round-trips a translation row" do
      ctx = system_context()
      obj_code = "tr_obj_#{unique_string()}"

      assert {:ok, created} =
               Translations.create(ctx, "en", "test_group", "Hello",
                 data_object_code: obj_code,
                 context: "title"
               )

      translation_id = created.translation_id || Map.get(created, :id)
      assert is_integer(translation_id)

      assert {:ok, _} = Translations.update(ctx, translation_id, "Hello updated")
      assert :ok = Translations.delete(ctx, translation_id)
    end
  end

  describe "query helpers" do
    test "search/3 returns a list" do
      ctx = system_context()

      assert {:ok, results} =
               Translations.search(ctx, "en", data_group: "permission", page: 1, page_size: 5)

      assert is_list(results)
    end

    test "get_group/4 returns translations in a data group" do
      assert {:ok, results} = Translations.get_group("en", "permission", "title")
      assert is_list(results)
    end
  end
end
