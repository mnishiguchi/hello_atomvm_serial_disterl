defmodule SampleApp.DeviceIdentity do
  @moduledoc """
  Resolves local and peer node identity for the serial demo.
  """

  @node_suffix "serial.local"

  def resolve do
    alias_name = fetch_alias("ATOMVM_NODE_ALIAS", "a")
    peer_alias = fetch_alias("ATOMVM_PEER_ALIAS", default_peer_alias(alias_name))

    %{
      alias: alias_name,
      peer_alias: peer_alias,
      node_name: :"#{alias_name}@#{@node_suffix}",
      peer_node_name: :"#{peer_alias}@#{@node_suffix}"
    }
  end

  defp fetch_alias(env_name, fallback) do
    case System.get_env(env_name) do
      value when is_binary(value) and byte_size(value) > 0 -> value
      _ -> fallback
    end
  end

  defp default_peer_alias("a"), do: "b"
  defp default_peer_alias(_alias_name), do: "a"
end
