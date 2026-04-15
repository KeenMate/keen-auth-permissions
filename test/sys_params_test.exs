defmodule KeenAuthPermissions.SysParamsTest do
  use KeenAuthPermissions.DataCase, async: false

  alias KeenAuthPermissions.SysParams

  describe "get/2" do
    test "reads a seeded parameter" do
      assert {:ok, param} = SysParams.get("journal", "level")
      assert is_binary(param.text_value) or param.text_value == nil
    end

    test "returns :not_found for an unknown parameter" do
      assert {:error, :not_found} = SysParams.get("nonexistent_group", "nonexistent_code")
    end
  end

  describe "update/5" do
    test "updates a text parameter and get/2 returns the new value" do
      {:ok, original} = SysParams.get("journal", "level")

      assert {:ok, _} = SysParams.update("journal", "level", "all")
      assert {:ok, %{text_value: "all"}} = SysParams.get("journal", "level")

      # Restore
      SysParams.update("journal", "level", original.text_value)
    end

    test "updates a numeric parameter" do
      {:ok, original} = SysParams.get("partition", "months_ahead")

      assert {:ok, _} = SysParams.update("partition", "months_ahead", nil, 6)
      assert {:ok, %{number_value: num}} = SysParams.get("partition", "months_ahead")
      assert num == 6 or num == Decimal.new(6)

      SysParams.update("partition", "months_ahead", nil, original.number_value)
    end
  end
end
