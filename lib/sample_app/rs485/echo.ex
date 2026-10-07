defmodule SampleApp.RS485.Echo do
  @moduledoc """
  Raw UART byte echo used to prove the TTL-to-RS485 path before Modbus.
  """

  @compile {:no_warn_undefined, :uart}

  @default_speed 115_200
  @read_timeout_ms 5_000
  @banner "atomvm-rs485-ready\r\n"

  def start do
    case SampleApp.UARTConfig.open(@default_speed) do
      {:ok, uart, peripheral, opts} ->
        IO.puts("rs485_echo: uart #{peripheral} #{inspect(opts)}")
        IO.puts("rs485_echo: sending #{inspect(@banner)}")
        :ok = :uart.write(uart, @banner)
        receive_and_echo(uart)

      {:error, reason} ->
        IO.puts("rs485_echo: failed to open UART: #{inspect(reason)}")
        Process.sleep(:infinity)
    end
  end

  defp receive_and_echo(uart) do
    case :uart.read(uart, @read_timeout_ms) do
      {:ok, data} ->
        IO.puts("rs485_echo: received #{byte_size(data)} bytes: #{inspect(data)}")
        :ok = :uart.write(uart, data)
        IO.puts("rs485_echo: echoed #{byte_size(data)} bytes")
        receive_and_echo(uart)

      {:error, :timeout} ->
        receive_and_echo(uart)

      {:error, reason} ->
        IO.puts("rs485_echo: UART read failed: #{inspect(reason)}")
        Process.sleep(1_000)
        receive_and_echo(uart)
    end
  end
end
