defmodule SampleApp.MixProject do
  use Mix.Project

  def project do
    [
      app: :sample_app,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      atomvm: [
        start: atomvm_start_module()
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:exatomvm, github: "atomvm/exatomvm", runtime: false},
      {:pythonx, "~> 0.4.0", runtime: false},
      {:req, "~> 0.7.0", runtime: false}
    ]
  end

  defp atomvm_start_module do
    case System.get_env("ATOMVM_EXPERIMENT") || "serial_dist" do
      "serial_dist" -> SampleApp
      "rs485_echo" -> SampleApp.RS485.Echo
      "modbus_rtu" -> SampleApp.Modbus.Client
      experiment -> raise "unknown ATOMVM_EXPERIMENT: #{inspect(experiment)}"
    end
  end
end
