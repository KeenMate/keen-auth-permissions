defmodule KeenAuthPermissions.EventClassificationTest do
  use ExUnit.Case, async: true

  alias KeenAuthPermissions.EventClassification

  describe "classify/1" do
    test "returns :hard for account-destructive events" do
      for event <- ~w(user_deleted user_disabled user_locked tenant_deleted provider_deleted provider_disabled) do
        assert EventClassification.classify(event) == :hard,
               "expected #{event} to be :hard"
      end
    end

    test "returns :medium for permission-change events" do
      for event <- ~w(group_deleted group_disabled permission_assignability_changed perm_set_updated) do
        assert EventClassification.classify(event) == :medium,
               "expected #{event} to be :medium"
      end
    end

    test "returns :soft for minor membership/permission events" do
      for event <- ~w(permission_assigned group_member_added api_key_created) do
        assert EventClassification.classify(event) == :soft,
               "expected #{event} to be :soft"
      end
    end

    test "returns :unknown for unrecognized events" do
      assert EventClassification.classify("definitely_not_a_real_event") == :unknown
    end

    test "respects app-level overrides" do
      Application.put_env(:keen_auth_permissions, :event_classification, %{
        "perm_set_updated" => :hard
      })

      assert EventClassification.classify("perm_set_updated") == :hard
    after
      Application.delete_env(:keen_auth_permissions, :event_classification)
    end
  end

  describe "message/1" do
    test "returns a human-readable string for known events" do
      assert is_binary(EventClassification.message("user_deleted"))
      assert is_binary(EventClassification.message("tenant_deleted"))
    end

    test "falls back for unknown events" do
      assert is_binary(EventClassification.message("something_brand_new"))
    end
  end
end
