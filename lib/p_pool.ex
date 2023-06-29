defmodule PPool do
  @moduledoc """
  API module for the pool
  """

  def start_link(), do: PPool.SuperSup.start_link([])
  defdelegate stop(), to: PPool.SuperSup
  defdelegate start_pool(name, limit), to: PPool.SuperSup
  defdelegate stop_pool(name), to: PPool.SuperSup
  defdelegate run(name, args), to: PPool.Serv
  defdelegate async_queue(name, args), to: PPool.Serv
  defdelegate sync_queue(name, args), to: PPool.Serv
end
