defmodule SampleApp.DemoNodeTest do
  use ExUnit.Case

  test "ping の送信元へ pong を返す" do
    identity = %{
      alias: "a",
      peer_alias: "b",
      node_name: :"a@serial.local",
      peer_node_name: :"b@serial.local"
    }

    pid = start_supervised!({SampleApp.DemoNode, identity: identity})
    send(pid, {:ping, self(), 1})

    assert_receive {:pong, from_node, 1}
    assert from_node == node()
  end
end
