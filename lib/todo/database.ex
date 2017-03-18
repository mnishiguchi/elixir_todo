defmodule Todo.Database do
  use GenServer

  @moduledoc """
  Maintains a pool of Todo.DatabaseWorkers and forwards database requests to them.
  Ensures that a single list is always handled by the same worker,
  which eliminates race conditions and keeps consistency.
  """

  #---
  # INTERFACE FUNCTIONS
  #---

  def start_link(db_folder) do
    IO.puts "Staring #{__MODULE__}"

    GenServer.start_link __MODULE__,             # Will be replaced with the current module during the compilation.
                         db_folder,              # Folder location will be kept as the process state.
                         name: :database_server  # Locally register the process under an alias so that we do not need pass the pid around.
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
  # GEN SERVER CALLBACKS
  #---

  @doc """
  Start three workers and store their pids in a Map of 0-based index => pid.
  """
  def init(db_folder) do
    worker_pool = start_workers(db_folder)
    {:ok, worker_pool}  # Determine the initial state.
  end

  # Returns a map of index to pid.
  defp start_workers(db_folder) do
    for index <- 0..2, into: %{} do
      {:ok, pid} = Todo.DatabaseWorker.start_link(db_folder)

      {index, pid}
    end
    |> IO.inspect

    # Enum.reduce 0..2, %{}, fn(index, acc) ->
    #   {:ok, pid} = Todo.DatabaseWorker.start_link(db_folder) do
    #
    #   {index, pid}
    # end
  end

  @doc """
  Respond with a worker id for a given key.
  """
  def handle_call {:get_worker, key}, _caller, workers do
    worker_key = hash_function(key)
    worker_pid = workers[ worker_key ]

    {:reply, worker_pid, workers}
  end

  #---
  # PRIVATE FUNCTIONS
  #---

  # Return a worker's pid for a given key.
  # Always return the same worker for the same key.
  defp get_worker(key) do
    GenServer.call :database_server, {:get_worker, key}
  end

  # Compute the key’s numerical hash for the range of 0..2 (3 buckets).
  defp hash_function(key) do
    :erlang.phash2(key, 3)
  end
end
