defmodule SampleApp.Modbus.RTUTest do
  use ExUnit.Case, async: true

  alias SampleApp.Modbus.RTU

  test "encodes a function 0x03 RTU request with low CRC byte first" do
    assert RTU.encode_read_holding_registers(1, 0, 10) ==
             {:ok, <<0x01, 0x03, 0x00, 0x00, 0x00, 0x0A, 0xC5, 0xCD>>}
  end

  test "decodes a CRC-valid function 0x03 response" do
    assert RTU.decode_read_holding_registers(
             <<0x01, 0x03, 0x02, 0x00, 0x0A, 0x38, 0x43>>,
             1
           ) == {:ok, [10]}
  end

  test "validates the expected register count" do
    frame = <<0x01, 0x03, 0x02, 0x00, 0x0A, 0x38, 0x43>>

    assert RTU.decode_read_holding_registers(frame, 1, 1) == {:ok, [10]}

    assert RTU.decode_read_holding_registers(frame, 1, 2) ==
             {:error, {:unexpected_register_count, 1, 2}}
  end

  test "rejects an invalid CRC" do
    assert RTU.decode_read_holding_registers(
             <<0x01, 0x03, 0x02, 0x00, 0x0B, 0x38, 0x43>>,
             1
           ) == {:error, :invalid_crc}
  end

  test "rejects a response from a different unit" do
    assert RTU.decode_read_holding_registers(
             <<0x01, 0x03, 0x02, 0x00, 0x0A, 0x38, 0x43>>,
             2
           ) == {:error, {:unexpected_unit_id, 1, 2}}
  end

  test "decodes an exception response" do
    assert RTU.decode_read_holding_registers(<<0x01, 0x83, 0x02, 0xC0, 0xF1>>, 1) ==
             {:error, {:modbus_exception, 0x02}}
  end
end
