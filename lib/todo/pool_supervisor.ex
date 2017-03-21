  defmodule Todo.PoolSupervisor do
  use Supervisor

  @moduledoc """
  Started by a `Todo.Database` process.
  Isolates the database-related processes from the rest of the system.
  """

  def start_link(db_folder, pool_size) do
    IO.puts "Staring #{__MODULE__}"

    Supervisor.start_link __MODULE__, {db_folder, pool_size}
  end

  def init {db_folder, pool_size} do
    # the descriptions of the child processes as a list of tuples
    children =  for worker_id <- 1..pool_size do
                  worker(
                    Todo.DatabaseWorker,
                    [db_folder, worker_id],
                    id: {:database_worker, worker_id} # NOTE: A unique id is necessary when the same module handles multiple modules.
                  )
                end |> IO.inspect

    supervise(children, strategy: :one_for_one)
  end
end
