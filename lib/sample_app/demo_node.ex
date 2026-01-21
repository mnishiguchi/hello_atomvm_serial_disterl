defmodule SampleApp.DemoNode do
  @moduledoc """
  Registered demo process for serial distributed Erlang ping/pong.
  """

  use GenServer

  @demo_name :demo
  @auto_ping Application.compile_env(:sample_app, :auto_ping, false)
  @ping_delay_ms Application.compile_env(:sample_app, :ping_delay_ms, 1_000)
  @pong_timeout_ms Application.compile_env(:sample_app, :pong_timeout_ms, 5_000)

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

    if @auto_ping do
      Process.send_after(self(), :auto_ping, @ping_delay_ms)
    end

    {:ok, %{identity: identity, pending_ping_id: nil, next_ping_id: 1}}
  end

  @impl GenServer
  def handle_cast(:send_ping, state) do
    {:noreply, send_ping_to_peer(state)}
  end

  @impl GenServer
  def handle_info(:auto_ping, state) do
    {:noreply, send_ping_to_peer(state)}
  end

  def handle_info({:ping, from_pid, ping_id}, state) when is_pid(from_pid) do
    IO.puts("demo: received ping from #{inspect(node(from_pid))}")
    send(from_pid, {:pong, node(), ping_id})
    IO.puts("demo: sent pong from #{inspect(node())}")
    {:noreply, state}
  end

  def handle_info({:pong, from_node, ping_id}, %{pending_ping_id: ping_id} = state) do
    IO.puts("demo: received pong from #{inspect(from_node)}")
    {:noreply, %{state | pending_ping_id: nil}}
  end

  def handle_info({:pong_timeout, ping_id}, %{pending_ping_id: ping_id} = state) do
    peer_node_name = state.identity.peer_node_name
    IO.puts("demo: pong timeout from #{inspect(peer_node_name)}")
    {:noreply, %{state | pending_ping_id: nil}}
  end

  def handle_info({:pong_timeout, _ping_id}, state) do
    {:noreply, state}
  end

  def handle_info(message, state) do
    IO.puts("demo: received #{inspect(message)}")
    {:noreply, state}
  end

  defp send_ping_to_peer(%{pending_ping_id: nil} = state) do
    peer_node_name = state.identity.peer_node_name
    ping_id = state.next_ping_id

    IO.puts("demo: sending ping to #{inspect(peer_node_name)}")
    send({@demo_name, peer_node_name}, {:ping, self(), ping_id})
    Process.send_after(self(), {:pong_timeout, ping_id}, @pong_timeout_ms)

    %{state | pending_ping_id: ping_id, next_ping_id: ping_id + 1}
  end

  defp send_ping_to_peer(state) do
    IO.puts("demo: waiting for pong")
    state
  end
end
