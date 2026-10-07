defmodule SampleApp.Modbus.PDU do
  @moduledoc """
  The minimal Modbus protocol data unit implementation needed for function 0x03.
  """

  @read_holding_registers 0x03
  @max_read_registers 125

  def encode_read_holding_registers(address, quantity)
      when is_integer(address) and is_integer(quantity) and address >= 0 and
             address <= 0xFFFF and quantity >= 1 and
             quantity <= @max_read_registers do
    {:ok, <<@read_holding_registers, address::16, quantity::16>>}
  end

  def encode_read_holding_registers(_address, _quantity), do: {:error, :invalid_request}

  def decode_read_holding_registers(
        <<@read_holding_registers, byte_count, register_data::binary>>
      ) do
    cond do
      byte_count != byte_size(register_data) ->
        {:error, :byte_count_mismatch}

      rem(byte_count, 2) != 0 ->
        {:error, :odd_register_byte_count}

      true ->
        {:ok, decode_registers(register_data, [])}
    end
  end

  def decode_read_holding_registers(<<function, exception_code>>)
      when function == 0x83 do
    {:error, {:modbus_exception, exception_code}}
  end

  def decode_read_holding_registers(<<function, _rest::binary>>) do
    {:error, {:unexpected_function, function}}
  end

  def decode_read_holding_registers(_pdu), do: {:error, :malformed_pdu}

  defp decode_registers(<<>>, registers), do: reverse(registers, [])

  defp decode_registers(<<register::16, rest::binary>>, registers) do
    decode_registers(rest, [register | registers])
  end

  defp reverse([], result), do: result
  defp reverse([head | tail], result), do: reverse(tail, [head | result])
end
