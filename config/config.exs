import Config

Code.require_file("config_helpers.exs", __DIR__)

alias SampleApp.ConfigHelpers

node_alias = ConfigHelpers.read_alias("ATOMVM_NODE_ALIAS", "a")

config :sample_app,
  node_alias: node_alias,
  peer_alias:
    ConfigHelpers.read_alias("ATOMVM_PEER_ALIAS", if(node_alias == "a", do: "b", else: "a")),
  cookie: ConfigHelpers.read_string("ATOMVM_COOKIE", "AtomVM"),
  auto_ping: ConfigHelpers.read_boolean("ATOMVM_AUTO_PING", false),
  ping_delay_ms: ConfigHelpers.read_integer("ATOMVM_PING_DELAY_MS", 1_000, &(&1 >= 0)),
  pong_timeout_ms: ConfigHelpers.read_integer("ATOMVM_PONG_TIMEOUT_MS", 5_000, &(&1 > 0)),
  uart_peripheral: ConfigHelpers.read_string("ATOMVM_UART_PERIPHERAL", "UART1"),
  uart_speed: ConfigHelpers.read_integer("ATOMVM_UART_SPEED", 115_200, &(&1 > 0)),
  uart_tx_pin: ConfigHelpers.read_integer("ATOMVM_UART_TX_PIN", 23, &(&1 >= 0)),
  uart_rx_pin: ConfigHelpers.read_integer("ATOMVM_UART_RX_PIN", 24, &(&1 >= 0))
