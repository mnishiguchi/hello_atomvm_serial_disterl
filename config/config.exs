import Config

parse_integer = fn name, fallback ->
  case System.get_env(name) do
    value when is_binary(value) ->
      case Integer.parse(value) do
        {integer, ""} -> integer
        _ -> fallback
      end

    _ ->
      fallback
  end
end

truthy = fn name ->
  System.get_env(name) in ["1", "true", "TRUE", "yes", "YES", "on", "ON"]
end

node_alias = System.get_env("ATOMVM_NODE_ALIAS") || "a"

peer_alias =
  System.get_env("ATOMVM_PEER_ALIAS") || if(node_alias == "a", do: "b", else: "a")

uart_parity =
  case System.get_env("ATOMVM_UART_PARITY") do
    "even" -> :even
    "odd" -> :odd
    _ -> :none
  end

config :sample_app,
  node_alias: node_alias,
  peer_alias: peer_alias,
  auto_ping: truthy.("ATOMVM_AUTO_PING"),
  ping_delay_ms: parse_integer.("ATOMVM_PING_DELAY_MS", 1_000),
  uart_peripheral: System.get_env("ATOMVM_UART_PERIPHERAL") || "UART1",
  uart_speed: parse_integer.("ATOMVM_UART_SPEED", nil),
  uart_tx_pin: parse_integer.("ATOMVM_UART_TX_PIN", 11),
  uart_rx_pin: parse_integer.("ATOMVM_UART_RX_PIN", 12),
  uart_data_bits: parse_integer.("ATOMVM_UART_DATA_BITS", 8),
  uart_stop_bits: parse_integer.("ATOMVM_UART_STOP_BITS", 1),
  uart_parity: uart_parity,
  modbus_unit_id: parse_integer.("MODBUS_UNIT_ID", 1),
  modbus_start_address: parse_integer.("MODBUS_START_ADDRESS", 0),
  modbus_quantity: parse_integer.("MODBUS_QUANTITY", 1),
  modbus_response_timeout_ms: parse_integer.("MODBUS_RESPONSE_TIMEOUT_MS", 1_000),
  modbus_request_interval_ms: parse_integer.("MODBUS_REQUEST_INTERVAL_MS", 5_000)
