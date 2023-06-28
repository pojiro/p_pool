defmodule PPool.Worker.Sup do
  # use Supervisor
  use DynamicSupervisor

  def start_link(init_arg) do
    # Supervisor.start_link(__MODULE__, init_arg)
    DynamicSupervisor.start_link(__MODULE__, init_arg)
  end

  def child_spec(mfa) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [mfa]},
      restart: :temporary,
      shutdown: 10000,
      type: :supervisor,
      modules: [__MODULE__]
    }
  end

  def worker_child_spec({m, f, a}) do
    %{
      id: m,
      start: {m, f, a},
      restart: :temporary,
      shutdown: 5000,
      type: :worker,
      modules: [m]
    }
  end

  ## callbacks

  @impl true
  def init({m, f, a} = _init_arg) do
    _children = [
      %{
        id: m,
        start: {m, f, a},
        restart: :temporary,
        shutdown: 5000,
        type: :worker,
        modules: [m]
      }
    ]

    # Supervisor.init(children, strategy: :simple_one_for_one)
    DynamicSupervisor.init(
      strategy: :one_for_one
      # extra_arguments: [init_arg]
    )
  end
end
