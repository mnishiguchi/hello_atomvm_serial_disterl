defmodule SampleApp.ClockLogger do
  @moduledoc """
  Logs time once per tick interval.
  """

  use GenServer

  @timezone_name "JST"
  @timezone_offset_ms :timer.hours(9)

  @tick_interval_ms :timer.seconds(5)

  ## Public API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, Keyword.put(opts, :name, __MODULE__))
  end

  def stop do
    GenServer.stop(__MODULE__)
  end

  ## gen_server callbacks

  @impl GenServer
  def init(:ok) do
    print_local_time()
    schedule_tick()
    {:ok, %{}}
  end

  @impl GenServer
  def handle_info(:tick, state) do
    print_local_time()
    schedule_tick()
    {:noreply, state}
  end

  @impl GenServer
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  @impl GenServer
  def terminate(_reason, _state), do: :ok

  ## Internals

  defp schedule_tick do
    Process.send_after(self(), :tick, @tick_interval_ms)
  end

  defp print_local_time do
    epoch_ms = :erlang.system_time(:millisecond)
    local_ms = epoch_ms + @timezone_offset_ms

    {{year, month, day}, {hour, minute, second}} =
      :calendar.system_time_to_universal_time(local_ms, :millisecond)

    :io.format(
      ~c"Date: ~4..0B/~2..0B/~2..0B ~2..0B:~2..0B:~2..0B (~pms) ~s~n",
      [year, month, day, hour, minute, second, epoch_ms, @timezone_name]
    )
  end
end
