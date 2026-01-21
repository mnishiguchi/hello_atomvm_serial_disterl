defmodule SampleApp.ConfigHelpersTest do
  use ExUnit.Case, async: true

  alias SampleApp.ConfigHelpers

  test "環境変数がなければ整数の既定値を返す" do
    assert ConfigHelpers.read_integer("VALUE", 23, &(&1 >= 0), fn _ -> nil end) == 23
  end

  test "正しい整数を読み取る" do
    assert ConfigHelpers.read_integer("VALUE", 23, &(&1 >= 0), fn _ -> "42" end) == 42
  end

  test "整数でない値を拒否する" do
    assert_raise ArgumentError, ~r/VALUE="oops" は整数/, fn ->
      ConfigHelpers.read_integer("VALUE", 23, &(&1 >= 0), fn _ -> "oops" end)
    end
  end

  test "範囲外の整数を拒否する" do
    assert_raise ArgumentError, ~r/VALUE="-1" は範囲外/, fn ->
      ConfigHelpers.read_integer("VALUE", 23, &(&1 >= 0), fn _ -> "-1" end)
    end
  end

  test "@ を含む node alias を拒否する" do
    assert_raise ArgumentError, ~r/ATOMVM_NODE_ALIAS="a@foo"/, fn ->
      ConfigHelpers.read_alias("ATOMVM_NODE_ALIAS", "a", fn _ -> "a@foo" end)
    end
  end

  test "不明な真偽値を拒否する" do
    assert_raise ArgumentError, ~r/ATOMVM_AUTO_PING="ture"/, fn ->
      ConfigHelpers.read_boolean("ATOMVM_AUTO_PING", false, fn _ -> "ture" end)
    end
  end
end
