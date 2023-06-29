defmodule PPool.Worker.Sup do
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg)
  end

  def child_spec() do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [nil]},
      restart: :temporary,
      shutdown: 10000,
      type: :supervisor,
      modules: [__MODULE__]
    }
  end

  def start_worker(sup, args) do
    DynamicSupervisor.start_child(sup, worker_child_spec(args))
  end

  defp worker_child_spec({m, f, a}) do
    %{
      id: m,
      start: {m, f, [a]},
      restart: :temporary,
      shutdown: 5000,
      type: :worker,
      modules: [m]
    }
  end

  ## callbacks

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
