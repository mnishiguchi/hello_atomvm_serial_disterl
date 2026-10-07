defmodule SampleApp.Modbus.TransportTest do
  use ExUnit.Case, async: true

  alias SampleApp.Modbus.Transport

  test "derives normal and exception response lengths from partial buffers" do
    assert Transport.expected_frame_length(<<>>) == :unknown
    assert Transport.expected_frame_length(<<1, 3>>) == :unknown
    assert Transport.expected_frame_length(<<1, 3, 4>>) == 9
    assert Transport.expected_frame_length(<<1, 0x83>>) == 5
  end
end
