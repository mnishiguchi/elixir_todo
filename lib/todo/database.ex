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

  def start(db_folder) do
    GenServer.start __MODULE__,             # Will be replaced with the current module during the compilation.
                    db_folder,              # Folder location will be kept as the process state.
                    name: :database_server  # Locally register the process under an alias so that we do not need pass the pid around.
  end

  @doc """
  Persist e given key data pair to the database.
  """
  def persist(key, data) do
    # Obtain the worker’s pid and forward to interface functions of DatabaseWorker.
    worker_pid = get_worker(key)
    GenServer.cast worker_pid, {:persist, key, data}
  end

  @doc """
  Return data for a given key.
  """
  def get(key) do
    # Obtain the worker’s pid and forward to interface functions of DatabaseWorker.
    worker_pid = get_worker(key)
    GenServer.call worker_pid, {:get, key}
  end

  #---
  # GEN SERVER CALLBACKS
  #---

  @doc """
  Start three workers and store their pids in a Map of 0-based index => pid.
  """
  def init(db_folder) do
    worker_pool = Enum.reduce 0..2, %{}, fn(index, acc) ->
                    case Todo.DatabaseWorker.start(db_folder) do
                      {:ok, pid} ->
                        Map.put(acc, index, pid)
                      _error ->
                        raise "Error starting a Todo.DatabaseWorker process"
                    end
                  end

    {:ok, worker_pool}  # Determine the initial state.
  end

  @doc """
  Respond with a worker id for a given key.
  """
  def handle_call {:worker_pid, key}, _caller, worker_pool do
    worker_pid = worker_pool[ hash_function(key) ]

    {:reply, worker_pid, worker_pool}
  end

  #---
  # PRIVATE FUNCTIONS
  #---

  # Return a worker's pid for a given key.
  # Always return the same worker for the same key.
  defp get_worker(key) do
    GenServer.call :database_server, {:worker_pid, key}
  end

  # Compute the key’s numerical hash for the range of 0..2 (3 buckets).
  defp hash_function(key) do
    :erlang.phash2(key, 3)
  end
end
