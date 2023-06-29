defmodule PPoolTest do
  use ExUnit.Case

  setup do
    pool_name = Nagger
    pool_size = 2

    :p_pool
    |> tap(&Application.stop(&1))
    |> tap(&Application.start(&1))

    PPool.start_pool(pool_name, pool_size)

    %{pool_name: pool_name, pool_size: pool_size}
  end

  test "run/2", %{pool_name: pool_name} do
    PPool.run(pool_name, {PPool.Nagger, :start_link, {"test", 10000, 10, self()}})
  end

  test "run/2 return :noalloc", %{pool_name: pool_name, pool_size: pool_size} do
    for _ <- 1..pool_size do
      PPool.run(pool_name, {PPool.Nagger, :start_link, {"test", 10000, 10, self()}})
    end

    assert :noalloc ==
             PPool.run(pool_name, {PPool.Nagger, :start_link, {"test", 10000, 10, self()}})
  end

  test "async_queue/2", %{pool_name: pool_name} do
    PPool.async_queue(pool_name, {PPool.Nagger, :start_link, {"test", 10000, 10, self()}})
  end

  test "sync_queue/2", %{pool_name: pool_name} do
    PPool.sync_queue(pool_name, {PPool.Nagger, :start_link, {"test", 10000, 10, self()}})
  end
end
