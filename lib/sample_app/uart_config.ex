defmodule SampleApp.UARTConfig do
  @moduledoc """
  Compile-time UART configuration shared by the serial distribution setup.

  Values are read from the host environment by `config/config.exs` while the
  application is built, so no host environment access is needed on AtomVM.
  The defaults route UART1 TX to D4/GPIO23 and UART1 RX to D5/GPIO24 through
  the ESP32-C5 GPIO matrix. D6/GPIO11 and D7/GPIO12 are correctly labeled as
  the board's default UART0 pins, but the AtomVM firmware uses that pair for
  its console.
  """

  @peripheral Application.compile_env(:sample_app, :uart_peripheral, "UART1")
  @speed Application.compile_env(:sample_app, :uart_speed, 115_200)
  @tx_pin Application.compile_env(:sample_app, :uart_tx_pin, 23)
  @rx_pin Application.compile_env(:sample_app, :uart_rx_pin, 24)

  def options do
    [
      {:peripheral, @peripheral},
      {:speed, @speed},
      {:tx, @tx_pin},
      {:rx, @rx_pin}
    ]
  end
end
