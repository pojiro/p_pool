defmodule PPool.Serv do
  use GenServer

  defmodule State do
    defstruct limit: 0, sup: nil, refs: nil, queue: :queue.new()
  end

  def start(name, limit, sup) when is_atom(name) and is_integer(limit) do
    GenServer.start(__MODULE__, {limit, sup}, name: name)
  end

  def start_link(name, limit, sup) when is_atom(name) and is_integer(limit) do
    GenServer.start_link(__MODULE__, {limit, sup}, name: name)
  end

  def run(name, args) do
    GenServer.call(name, {:run, args})
  end

  def sync_queue(name, args) do
    GenServer.call(name, {:sync, args}, :infinity)
  end

  def async_queue(name, args) do
    GenServer.cast(name, {:async, args})
  end

  def stop(name) do
    GenServer.call(name, :stop)
  end

  ## callbacks

  @impl true
  def init({limit, sup}) do
    send(self(), {:start_worker_supervisor, sup})
    {:ok, %State{limit: limit, refs: :gb_sets.empty()}}
  end

  @impl true
  def handle_info({:start_worker_supervisor, sup}, state) do
    # 引数で受け取った sup は PPool.Sup の pid
    {:ok, pid} =
      PPool.Worker.Sup.child_spec()
      |> then(&Supervisor.start_child(sup, &1))

    Process.link(pid)

    {:noreply, %State{state | sup: pid}}
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _}, %State{refs: refs} = state) do
    IO.puts("received down msg")

    case :gb_sets.is_element(ref, refs) do
      true -> handle_down_worker(ref, state)
      false -> {:noreply, state}
    end
  end

  @impl true
  def handle_call({:run, {_m, _f, _a} = args}, _from, %State{limit: n, sup: sup, refs: r} = state)
      when n > 0 do
    # sup は PPool.Worker.Sup の pid
    {:ok, pid} = PPool.Worker.Sup.start_worker(sup, args)
    ref = Process.monitor(pid)
    {:reply, {:ok, pid}, %State{state | limit: n - 1, refs: :gb_sets.add(ref, r)}}
  end

  @impl true
  def handle_call({:run, _args}, _from, %State{limit: n} = state) when n <= 0 do
    {:reply, :noalloc, state}
  end

  @impl true
  def handle_call({:sync, args}, _from, %State{limit: n, sup: sup, refs: r} = state) when n > 0 do
    {:ok, pid} = PPool.Worker.Sup.start_worker(sup, args)
    ref = Process.monitor(pid)
    {:reply, {:ok, pid}, %State{state | limit: n - 1, refs: :gb_sets.add(ref, r)}}
  end

  @impl true
  def handle_call({:sync, args}, from, %State{limit: n, queue: q} = state) when n <= 0 do
    {:noreply, %State{state | queue: :queue.in({from, args}, q)}}
  end

  @impl true
  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end

  @impl true
  def handle_cast({:async, args}, %State{limit: n, sup: sup, refs: r} = state) when n > 0 do
    {:ok, pid} = PPool.Worker.Sup.start_worker(sup, args)
    ref = Process.monitor(pid)
    {:noreply, %State{state | limit: n - 1, refs: :gb_sets.add(ref, r)}}
  end

  @impl true
  def handle_cast({:async, args}, %State{limit: n, queue: q} = state) when n <= 0 do
    {:noreply, %State{state | queue: :queue.in(args, q)}}
  end

  defp handle_down_worker(ref, %State{limit: l, sup: sup, refs: refs} = s) do
    case :queue.out(s.queue) do
      {{:value, {from, args}}, q} ->
        {:ok, pid} = PPool.Worker.Sup.start_worker(sup, args)
        new_ref = Process.monitor(pid)
        new_refs = :gb_sets.insert(new_ref, :gb_sets.delete(ref, refs))
        GenServer.reply(from, {:ok, pid})
        {:noreply, %State{s | refs: new_refs, queue: q}}

      {{:value, args}, q} ->
        {:ok, pid} = PPool.Worker.Sup.start_worker(sup, args)
        new_ref = Process.monitor(pid)
        new_refs = :gb_sets.insert(new_ref, :gb_sets.delete(ref, refs))
        {:noreply, %State{s | refs: new_refs, queue: q}}

      {:empty, _} ->
        {:noreply, %State{s | limit: l + 1, refs: :gb_sets.delete(ref, refs)}}
    end
  end
end
