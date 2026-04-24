defmodule SampleApp.DemoNode do
  @moduledoc """
  Registered demo process for serial distributed Erlang ping/pong.
  """

  use GenServer

  @demo_name :demo
  @default_ping_delay_ms 1_000

  def start_link(opts) do
    identity = Keyword.fetch!(opts, :identity)
    GenServer.start_link(__MODULE__, identity, name: @demo_name)
  end

  def send_ping do
    GenServer.cast(@demo_name, :send_ping)
  end

  @impl GenServer
  def init(identity) do
    IO.puts("demo: registered process #{inspect(@demo_name)}")

    if auto_ping_enabled?() do
      Process.send_after(self(), :auto_ping, ping_delay_ms())
    end

    {:ok, identity}
  end

  @impl GenServer
  def handle_cast(:send_ping, state) do
    send_ping_to_peer(state)
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(:auto_ping, state) do
    send_ping_to_peer(state)
    {:noreply, state}
  end

  def handle_info({:ping, from_pid}, state) when is_pid(from_pid) do
    IO.puts("demo: received ping from #{inspect(node(from_pid))}")
    send(from_pid, {:pong, node()})
    IO.puts("demo: sent pong from #{inspect(node())}")
    {:noreply, state}
  end

  def handle_info({:pong, from_node}, state) do
    IO.puts("demo: received pong from #{inspect(from_node)}")
    {:noreply, state}
  end

  def handle_info({:hello, from_node}, state) do
    IO.puts("demo: received hello from #{inspect(from_node)}")
    {:noreply, state}
  end

  def handle_info({:set_led, mode}, state) do
    IO.puts("demo: ignoring LED request #{inspect(mode)}")
    {:noreply, state}
  end

  def handle_info(message, state) do
    IO.puts("demo: received #{inspect(message)}")
    {:noreply, state}
  end

  defp send_ping_to_peer(%{peer_node_name: peer_node_name}) do
    IO.puts("demo: sending ping to #{inspect(peer_node_name)}")
    send({@demo_name, peer_node_name}, {:ping, self()})
  end

  defp auto_ping_enabled? do
    truthy_env?("ATOMVM_AUTO_PING")
  end

  defp ping_delay_ms do
    case System.get_env("ATOMVM_PING_DELAY_MS") do
      value when is_binary(value) ->
        case Integer.parse(value) do
          {integer, ""} when integer >= 0 -> integer
          _ -> @default_ping_delay_ms
        end

      _ ->
        @default_ping_delay_ms
    end
  end

  defp truthy_env?(env_name) do
    case System.get_env(env_name) do
      value when value in ["1", "true", "TRUE", "yes", "YES", "on", "ON"] -> true
      _ -> false
    end
  end
end
