defmodule SampleApp.UARTConfig do
  @moduledoc """
  Shared UART configuration for the independent serial experiments.

  GPIO24 (TX) and GPIO23 (RX) are exposed on the ESP32-C5-DevKitC-1 headers
  and are not strapping pins. Every setting can be overridden at flash time.
  """

  @compile {:no_warn_undefined, :uart}

  @peripheral Application.compile_env(:sample_app, :uart_peripheral, "UART1")
  @configured_speed Application.compile_env(:sample_app, :uart_speed, nil)
  @tx_pin Application.compile_env(:sample_app, :uart_tx_pin, 24)
  @rx_pin Application.compile_env(:sample_app, :uart_rx_pin, 23)
  @data_bits Application.compile_env(:sample_app, :uart_data_bits, 8)
  @stop_bits Application.compile_env(:sample_app, :uart_stop_bits, 1)
  @parity Application.compile_env(:sample_app, :uart_parity, :none)

  def open(default_speed) do
    peripheral = @peripheral
    opts = options(default_speed)

    case :uart.open(peripheral, opts) do
      {:error, _reason} = error -> error
      uart -> {:ok, uart, peripheral, opts}
    end
  end

  def options(default_speed, opts \\ []) do
    uart_opts = [
      {:speed, @configured_speed || default_speed},
      {:tx, @tx_pin},
      {:rx, @rx_pin},
      {:data_bits, @data_bits},
      {:stop_bits, @stop_bits},
      {:flow_control, :none},
      {:parity, @parity}
    ]

    if Keyword.get(opts, :include_peripheral, false) do
      [{:peripheral, @peripheral} | uart_opts]
    else
      uart_opts
    end
  end
end
