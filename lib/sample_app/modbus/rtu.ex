defmodule SampleApp.Modbus.RTU do
  @moduledoc """
  Modbus RTU address/framing and CRC validation.
  """

  alias SampleApp.Modbus.{CRC16, PDU}

  def encode_read_holding_registers(unit_id, address, quantity)
      when is_integer(unit_id) and unit_id >= 1 and unit_id <= 247 do
    case PDU.encode_read_holding_registers(address, quantity) do
      {:ok, pdu} -> {:ok, CRC16.append(<<unit_id, pdu::binary>>)}
      error -> error
    end
  end

  def encode_read_holding_registers(_unit_id, _address, _quantity),
    do: {:error, :invalid_unit_id}

  def decode_read_holding_registers(frame, expected_unit_id) when is_binary(frame) do
    with :ok <- validate_crc(frame),
         {:ok, unit_id, pdu} <- split_frame(frame),
         :ok <- validate_unit_id(unit_id, expected_unit_id) do
      PDU.decode_read_holding_registers(pdu)
    end
  end

  def decode_read_holding_registers(frame, expected_unit_id, expected_quantity) do
    case decode_read_holding_registers(frame, expected_unit_id) do
      {:ok, registers} when length(registers) == expected_quantity ->
        {:ok, registers}

      {:ok, registers} ->
        {:error, {:unexpected_register_count, length(registers), expected_quantity}}

      error ->
        error
    end
  end

  defp validate_crc(frame) do
    if CRC16.valid?(frame), do: :ok, else: {:error, :invalid_crc}
  end

  defp split_frame(frame) when byte_size(frame) >= 4 do
    payload_size = byte_size(frame) - 3
    <<unit_id, pdu::binary-size(^payload_size), _crc::binary-size(2)>> = frame
    {:ok, unit_id, pdu}
  end

  defp split_frame(_frame), do: {:error, :frame_too_short}

  defp validate_unit_id(unit_id, unit_id), do: :ok
  defp validate_unit_id(actual, expected), do: {:error, {:unexpected_unit_id, actual, expected}}
end
