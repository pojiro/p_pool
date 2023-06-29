defmodule PPool.SuperSup do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_pool(name, limit) do
    child_spec = %{
      id: name,
      start: {PPool.Sup, :start_link, [name, limit]},
      restart: :permanent,
      shutdown: 10500,
      type: :supervisor,
      modules: [PPool.Sup]
    }

    Supervisor.start_child(__MODULE__, child_spec)
  end

  def stop_pool(name) do
    Supervisor.terminate_child(__MODULE__, name)
    Supervisor.delete_child(__MODULE__, name)
  end

  @impl true
  def init(_init_arg) do
    Supervisor.init([], strategy: :one_for_one, max_restarts: 6, max_seconds: 3600)
  end
end
