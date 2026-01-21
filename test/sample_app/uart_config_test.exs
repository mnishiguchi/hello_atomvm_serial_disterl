defmodule SampleApp.UARTConfigTest do
  use ExUnit.Case, async: true

  @peripheral Application.compile_env(:sample_app, :uart_peripheral, "UART1")
  @speed Application.compile_env(:sample_app, :uart_speed, 115_200)
  @tx_pin Application.compile_env(:sample_app, :uart_tx_pin, 23)
  @rx_pin Application.compile_env(:sample_app, :uart_rx_pin, 24)

  test "returns the compile-time UART configuration" do
    assert SampleApp.UARTConfig.options() == [
             {:peripheral, @peripheral},
             {:speed, @speed},
             {:tx, @tx_pin},
             {:rx, @rx_pin}
           ]
  end
end
