defmodule PPool do
  @moduledoc """
  API module for the pool
  """

  use Application

  @impl true
  def start(_type, _args) do
    PPool.SuperSup.start_link([])
  end

  @impl true
  def stop(_state), do: :ok

  defdelegate start_pool(name, limit), to: PPool.SuperSup
  defdelegate stop_pool(name), to: PPool.SuperSup
  defdelegate run(name, args), to: PPool.Serv
  defdelegate async_queue(name, args), to: PPool.Serv
  defdelegate sync_queue(name, args), to: PPool.Serv
end
