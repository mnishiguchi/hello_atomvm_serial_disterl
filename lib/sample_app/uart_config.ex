defmodule SampleApp.UARTConfig do
  @moduledoc """
  Shared UART configuration for the independent serial experiments.

  The defaults use D6/GPIO11 (TX) and D7/GPIO12 (RX) on the Seeed Studio
  XIAO ESP32-C5 used for this experiment. Every setting can be overridden at
  flash time for another supported ESP32 board.
  """

  @compile {:no_warn_undefined, :uart}

  @peripheral Application.compile_env(:sample_app, :uart_peripheral, "UART1")
  @configured_speed Application.compile_env(:sample_app, :uart_speed, nil)
  @tx_pin Application.compile_env(:sample_app, :uart_tx_pin, 11)
  @rx_pin Application.compile_env(:sample_app, :uart_rx_pin, 12)
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
