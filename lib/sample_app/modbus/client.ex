defmodule SampleApp.Modbus.Client do
  @moduledoc """
  Periodic Modbus RTU function 0x03 experiment over AtomVM UART.
  """

  alias SampleApp.Modbus.{RTU, Transport}

  @default_speed 9_600
  @unit_id Application.compile_env(:sample_app, :modbus_unit_id, 1)
  @start_address Application.compile_env(:sample_app, :modbus_start_address, 0)
  @quantity Application.compile_env(:sample_app, :modbus_quantity, 1)
  @timeout_ms Application.compile_env(:sample_app, :modbus_response_timeout_ms, 1_000)
  @interval_ms Application.compile_env(:sample_app, :modbus_request_interval_ms, 5_000)

  def start do
    case {SampleApp.UARTConfig.open(@default_speed),
          RTU.encode_read_holding_registers(@unit_id, @start_address, @quantity)} do
      {{:ok, uart, peripheral, opts}, {:ok, request}} ->
        IO.puts("modbus_rtu: uart #{peripheral} #{inspect(opts)}")
        IO.puts("modbus_rtu: unit #{@unit_id}, address #{@start_address}, quantity #{@quantity}")
        request_loop(uart, request, @unit_id)

      {{:error, reason}, _request} ->
        IO.puts("modbus_rtu: failed to open UART: #{inspect(reason)}")
        Process.sleep(:infinity)

      {_uart, {:error, reason}} ->
        IO.puts("modbus_rtu: invalid request: #{inspect(reason)}")
        Process.sleep(:infinity)
    end
  end

  defp request_loop(uart, request, unit_id) do
    IO.puts("modbus_rtu: sending #{inspect(request)}")

    case Transport.transact(uart, request, @timeout_ms) do
      {:ok, response} ->
        log_response(response, unit_id)

      {:error, reason} ->
        IO.puts("modbus_rtu: receive failed: #{inspect(reason)}")
    end

    Process.sleep(@interval_ms)
    request_loop(uart, request, unit_id)
  end

  defp log_response(response, unit_id) do
    case RTU.decode_read_holding_registers(response, unit_id, @quantity) do
      {:ok, registers} ->
        IO.puts("modbus_rtu: registers #{inspect(registers)}")

      {:error, reason} ->
        IO.puts("modbus_rtu: invalid response #{inspect(response)}: #{inspect(reason)}")
    end
  end
end
