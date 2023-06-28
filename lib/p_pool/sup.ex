defmodule PPool.Sup do
  use Supervisor

  def start_link(name, limit, mfa) do
    Supervisor.start_link(__MODULE__, {name, limit, mfa})
  end

  @impl true
  def init({name, limit, mfa}) do
    children = [
      %{
        id: PPool.Serv,
        start: {PPool.Serv, :start_link, [name, limit, self(), mfa]},
        restart: :permanent,
        shutdown: 5000,
        type: :worker,
        modules: [PPool.Serv]
      }
    ]

    Supervisor.init(children, strategy: :one_for_all, max_restarts: 1, max_seconds: 3600)
  end
end
