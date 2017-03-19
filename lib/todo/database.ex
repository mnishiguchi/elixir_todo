defmodule Todo.Database do
  @pool_size 3

  @moduledoc """
  The client interface point of the database-related operations.
  Delegates all the database operations to corresponding Todo.DatabaseWorker functions, which run in the caller process.
  Ensures that a single list is always handled by the same worker, which eliminates race conditions and keeps consistency.
  This module is not a process because it has no state to be maintained.
  """

  #---
  # INTERFACE FUNCTIONS
  #---

  def start_link(db_folder) do
    IO.puts "Staring #{__MODULE__}"

    Todo.PoolSupervisor.start_link(db_folder, @pool_size)
  end

  @doc """
  Persist e given key data pair to the database.
  Delegate the operation to DatabaseWorker.
  """
  def persist(key, data) do
    key
    |> get_worker
    |> Todo.DatabaseWorker.persist(key, data)
  end

  @doc """
  Return data for a given key.
  Delegate the operation to DatabaseWorker.
  """
  def get(key) do
    key
    |> get_worker
    |> Todo.DatabaseWorker.get(key)
  end

  #---
  # PRIVATE FUNCTIONS
  #---

  # Return a worker's pid for a given key.
  # Always return the same worker for the same key.
  defp get_worker(key) do
    hash_function(key)
  end

  # Compute the key’s numerical hash for the range of 1..@pool_size.
  defp hash_function(key) do
    :erlang.phash2(key, @pool_size) + 1
  end
end
