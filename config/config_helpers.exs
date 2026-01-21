defmodule SampleApp.ConfigHelpers do
  @moduledoc false

  def read_string(name, fallback, get_env \\ &System.get_env/1) do
    case get_env.(name) do
      nil -> fallback
      "" -> raise ArgumentError, "#{name} は空にできません"
      value -> value
    end
  end

  def read_integer(name, fallback, valid?, get_env \\ &System.get_env/1) do
    case get_env.(name) do
      nil ->
        fallback

      value ->
        case Integer.parse(value) do
          {integer, ""} ->
            if valid?.(integer) do
              integer
            else
              raise ArgumentError, "#{name}=#{inspect(value)} は範囲外です"
            end

          _ ->
            raise ArgumentError, "#{name}=#{inspect(value)} は整数で指定してください"
        end
    end
  end

  def read_alias(name, fallback, get_env \\ &System.get_env/1) do
    value = read_string(name, fallback, get_env)

    if Regex.match?(~r/\A[A-Za-z0-9_-]+\z/, value) do
      value
    else
      raise ArgumentError,
            "#{name}=#{inspect(value)} は英数字、_、- だけで指定してください"
    end
  end

  def read_boolean(name, fallback, get_env \\ &System.get_env/1) do
    case get_env.(name) do
      nil -> fallback
      value when value in ["1", "true", "TRUE", "yes", "YES", "on", "ON"] -> true
      value when value in ["0", "false", "FALSE", "no", "NO", "off", "OFF"] -> false
      value -> raise ArgumentError, "#{name}=#{inspect(value)} は true または false で指定してください"
    end
  end
end
