defmodule SampleApp.Modbus.Transport do
  @moduledoc """
  Synchronous Modbus RTU transactions over AtomVM's UART driver.
  """

  import Bitwise

  @compile {:no_warn_undefined, :uart}

  def transact(uart, request, timeout_ms) do
    with :ok <- :uart.write(uart, request) do
      read_frame(uart, timeout_ms, <<>>)
    end
  end

  def expected_frame_length(buffer) when byte_size(buffer) < 2, do: :unknown

  def expected_frame_length(<<_unit_id, function, _rest::binary>>)
      when band(function, 0x80) != 0,
      do: 5

  def expected_frame_length(buffer) when byte_size(buffer) < 3, do: :unknown

  def expected_frame_length(<<_unit_id, _function, byte_count, _rest::binary>>),
    do: byte_count + 5

  defp read_frame(uart, timeout_ms, buffer) do
    case complete_frame(buffer) do
      {:ok, frame} ->
        {:ok, frame}

      :more ->
        case :uart.read(uart, timeout_ms) do
          {:ok, data} -> read_frame(uart, timeout_ms, <<buffer::binary, data::binary>>)
          error -> error
        end
    end
  end

  defp complete_frame(buffer) do
    case expected_frame_length(buffer) do
      :unknown ->
        :more

      length when byte_size(buffer) < length ->
        :more

      length ->
        <<frame::binary-size(^length), _rest::binary>> = buffer
        {:ok, frame}
    end
  end
end
