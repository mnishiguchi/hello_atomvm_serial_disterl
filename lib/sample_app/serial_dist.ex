defmodule SampleApp.SerialDist do
  @moduledoc """
  Starts AtomVM serial distributed Erlang for the demo application.
  """

  @compile {:no_warn_undefined, :net_kernel}

  @cookie Application.compile_env(:sample_app, :cookie, "AtomVM")

  def start(identity) do
    node_name = identity.node_name
    uart_opts = SampleApp.UARTConfig.options()

    case :net_kernel.start(node_name, dist_options(uart_opts)) do
      {:ok, _pid} ->
        :ok = :net_kernel.set_cookie(@cookie)
        log_success(identity, uart_opts)
        :ok

      other ->
        IO.puts("serial_dist: failed to start #{inspect(other)}")
        {:error, {:net_kernel_start_failed, other}}
    end
  end

  defp dist_options(uart_opts) do
    %{
      name_domain: :longnames,
      proto_dist: :serial_dist,
      avm_dist_opts: %{
        uart_opts: uart_opts,
        uart_module: :uart
      }
    }
  end

  defp log_success(identity, uart_opts) do
    IO.puts("serial_dist: started")
    IO.puts("serial_dist: alias #{identity.alias}")
    IO.puts("serial_dist: node #{inspect(identity.node_name)}")
    IO.puts("serial_dist: peer #{inspect(identity.peer_node_name)}")
    IO.puts("serial_dist: cookie configured")
    IO.puts("serial_dist: uart #{inspect(uart_opts)}")
    IO.puts("serial_dist: ready")
  end
end
