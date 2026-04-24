defmodule SampleApp.SerialDist do
  @moduledoc """
  Starts AtomVM serial distributed Erlang for the demo application.
  """

  @compile {:no_warn_undefined, :net_kernel}

  @cookie <<"AtomVM">>
  @default_uart_peripheral "UART1"
  @default_uart_speed 115_200
  @default_uart_tx_pin 17
  @default_uart_rx_pin 16

  def start(identity) do
    node_name = identity.node_name
    uart_opts = uart_opts()

    case :net_kernel.start(node_name, dist_options(uart_opts)) do
      {:ok, _pid} ->
        :ok = :net_kernel.set_cookie(@cookie)
        log_success(identity, uart_opts)
        :ok

      {:error, {:already_started, _pid}} ->
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

  defp uart_opts do
    [
      {:peripheral, System.get_env("ATOMVM_UART_PERIPHERAL") || @default_uart_peripheral},
      {:speed, env_integer("ATOMVM_UART_SPEED", @default_uart_speed)},
      {:tx, env_integer("ATOMVM_UART_TX_PIN", @default_uart_tx_pin)},
      {:rx, env_integer("ATOMVM_UART_RX_PIN", @default_uart_rx_pin)}
    ]
  end

  defp env_integer(env_name, fallback) do
    case System.get_env(env_name) do
      value when is_binary(value) ->
        case Integer.parse(value) do
          {integer, ""} -> integer
          _ -> fallback
        end

      _ ->
        fallback
    end
  end

  defp log_success(identity, uart_opts) do
    IO.puts("serial_dist: started")
    IO.puts("serial_dist: alias #{identity.alias}")
    IO.puts("serial_dist: node #{inspect(identity.node_name)}")
    IO.puts("serial_dist: peer #{inspect(identity.peer_node_name)}")
    IO.puts("serial_dist: cookie #{inspect(@cookie)}")
    IO.puts("serial_dist: uart #{inspect(uart_opts)}")
    IO.puts("serial_dist: ready")
  end
end
