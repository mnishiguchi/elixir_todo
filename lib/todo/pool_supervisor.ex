  defmodule Todo.PoolSupervisor do
  use Supervisor

  @moduledoc """
  Started by a `Todo.Database` process.
  Isolates the database-related processes from the rest of the system.

  ## SUPERVISION TREE

      Todo.Supervisor (one_for_one)
        ├── Todo.ProcessRegistry
        ├── Todo.PoolSupervisor (one_for_one)
        │     ├── Todo.DatabaseWorker 1
        │     ├── Todo.DatabaseWorker 2
        │     ├── Todo.DatabaseWorker n
        │     :
        └── Todo.Cache
              ├── Todo.Server 1
              ├── Todo.Server 2
              ├── Todo.Server n
              :
  """

  def start_link(db_folder, pool_size) do
    IO.puts "Staring #{__MODULE__}"

    Supervisor.start_link __MODULE__, {db_folder, pool_size}
  end

  def init {db_folder, pool_size} do
    # the descriptions of the child processes as a list of tuples
    # NOTE: A unique id is necessary when the same module handles multiple modules.
    child_processes = for worker_id <- 1..pool_size do
                        worker(
                          Todo.DatabaseWorker,
                          [db_folder, worker_id],
                          id: {:database_worker, worker_id}
                        )
                      end |> IO.inspect

    # Must return a supervisor specification.
    supervise child_processes,        # processes that are to be started and supervised
              strategy: :one_for_one  # supervisor options
  end
end
