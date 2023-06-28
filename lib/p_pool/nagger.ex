defmodule PPool.Nagger do
  use GenServer

  require Logger

  def start_link({task, delay, max, send_to}) do
    Logger.debug("start_link nagger")
    GenServer.start_link(__MODULE__, {task, delay, max, send_to})
  end

  def stop(pid) do
    GenServer.call(pid, :stop)
  end

  ## callbacks

  @impl true
  def init({task, delay, max, send_to}) do
    {:ok, {task, delay, max, send_to}, delay}
  end

  @impl true
  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end

  @impl true
  def handle_info(:timeout, {task, delay, max, send_to}) do
    send(send_to, {self(), task})

    case max do
      :infinity -> {:noreply, {task, delay, max, send_to}, delay}
      max when max <= 1 -> {:stop, :normal, {task, delay, 0, send_to}}
      max when max > 1 -> {:noreply, {task, delay, max - 1, send_to}, delay}
    end
  end
end
