defmodule SampleApp.DeviceIdentity do
  @moduledoc """
  Resolves local and peer node identity for the serial demo.
  """

  @node_suffix "serial.local"
  @alias_name Application.compile_env(:sample_app, :node_alias, "a")
  @peer_alias Application.compile_env(:sample_app, :peer_alias, "b")

  def resolve do
    %{
      alias: @alias_name,
      peer_alias: @peer_alias,
      node_name: :"#{@alias_name}@#{@node_suffix}",
      peer_node_name: :"#{@peer_alias}@#{@node_suffix}"
    }
  end
end
