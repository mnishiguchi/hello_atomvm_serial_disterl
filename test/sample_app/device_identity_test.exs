defmodule SampleApp.DeviceIdentityTest do
  use ExUnit.Case, async: true

  @alias_name Application.compile_env(:sample_app, :node_alias, "a")
  @peer_alias Application.compile_env(:sample_app, :peer_alias, "b")

  test "resolves the configured pair of serial node names" do
    assert SampleApp.DeviceIdentity.resolve() == %{
             alias: @alias_name,
             peer_alias: @peer_alias,
             node_name: :"#{@alias_name}@serial.local",
             peer_node_name: :"#{@peer_alias}@serial.local"
           }
  end
end
