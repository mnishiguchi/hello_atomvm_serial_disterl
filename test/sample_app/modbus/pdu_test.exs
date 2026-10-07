defmodule SampleApp.Modbus.PDUTest do
  use ExUnit.Case, async: true

  alias SampleApp.Modbus.PDU

  test "encodes read holding registers" do
    assert PDU.encode_read_holding_registers(0x0010, 2) ==
             {:ok, <<0x03, 0x00, 0x10, 0x00, 0x02>>}
  end

  test "validates request ranges" do
    assert PDU.encode_read_holding_registers(-1, 1) == {:error, :invalid_request}
    assert PDU.encode_read_holding_registers(0, 0) == {:error, :invalid_request}
    assert PDU.encode_read_holding_registers(0, 126) == {:error, :invalid_request}
  end

  test "decodes register values" do
    assert PDU.decode_read_holding_registers(<<0x03, 4, 0x00, 0x0A, 0x01, 0x02>>) ==
             {:ok, [10, 258]}
  end

  test "decodes Modbus exceptions" do
    assert PDU.decode_read_holding_registers(<<0x83, 0x02>>) ==
             {:error, {:modbus_exception, 0x02}}
  end

  test "rejects malformed register data" do
    assert PDU.decode_read_holding_registers(<<0x03, 4, 0, 1>>) ==
             {:error, :byte_count_mismatch}

    assert PDU.decode_read_holding_registers(<<0x03, 1, 0>>) ==
             {:error, :odd_register_byte_count}
  end
end
