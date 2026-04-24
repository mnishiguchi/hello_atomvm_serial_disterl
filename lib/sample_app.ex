defmodule SampleApp do
  @moduledoc """
  Entry point for the AtomVM application.
  """

  def start do
    identity = SampleApp.DeviceIdentity.resolve()

    :ok = SampleApp.SerialDist.start(identity)
    {:ok, _} = SampleApp.DemoNode.start_link(identity: identity)

    Process.sleep(:infinity)
  end
end
