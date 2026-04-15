defmodule KeenAuthPermissions.EventsTest do
  use KeenAuthPermissions.DataCase, async: false

  alias KeenAuthPermissions.Events

  # Use a high id that's safely outside the 10000–39999 core range (and outside
  # the 50000–50999 example range, so re-runs don't collide with each other).
  defp next_id, do: 60_000 + :rand.uniform(9_999)

  describe "full category + code + message lifecycle" do
    test "registers a category, a code inside it, a message, then tears down" do
      ctx = system_context()
      suffix = unique_string()
      category_code = "app_cat_#{suffix}"

      event_id = next_id()
      range_start = event_id
      range_end = event_id + 100

      assert {:ok, _} =
               Events.create_category(ctx, category_code, "App Events", range_start, range_end,
                 source: "test"
               )

      event_code = "app_event_#{suffix}"

      assert {:ok, _} =
               Events.create_code(ctx, event_id, event_code, category_code, "App Event",
                 description: "Test event",
                 source: "test"
               )

      assert {:ok, msg} =
               Events.create_message(ctx, event_id, "Hello {name}", language_code: "en")

      message_id = msg.event_message_id || Map.get(msg, :id) || Map.get(msg, :create_event_message)
      assert is_integer(message_id)

      # Retrieve the template we just registered.
      assert {:ok, tpl} = Events.get_message_template(event_id, "en")
      assert is_binary(tpl)
      assert tpl =~ "Hello"

      # Teardown (reverse dependency order: message → code → category)
      assert :ok = Events.delete_message(ctx, message_id)
      assert :ok = Events.delete_code(ctx, event_id)
      assert :ok = Events.delete_category(ctx, category_code)
    end
  end

  describe "get_message_template/2" do
    test "returns :not_found for an unknown event_id" do
      assert {:error, :not_found} = Events.get_message_template(-999_999, "en")
    end
  end
end
