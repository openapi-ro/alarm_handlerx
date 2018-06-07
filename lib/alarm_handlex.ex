defmodule AlarmHandlex do
  @moduledoc """
  Documentation for AlarmHandlex.
  """

  def start(_type,_args) do
    import Supervisor.Spec
    children = [
      worker(Registry, [:duplicate, AlarmHandlex.Registry],id: AlarmHandlex.Registry ),
      worker(AlarmHandler, [] )
    ]
    opts = [strategy: :one_for_one, name: AlarmHandlex.Supervisor]
    Supervisor.start_link(children,opts)
  end
end
