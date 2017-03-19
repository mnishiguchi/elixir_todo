defmodule Todo.Supervisor do
  use Supervisor

  @moduledoc """
  The top-level supervisor that responsible for starting the entire system.

  ## STARTING A SUPERVISOR PROCESS

      caller process              supervisor process               child processes
      ================================================================================
                    start                      start and supervise
      caller --------------------> :supervisor -------------------> child processes
                                        |
                                        |  get the supervisor specification
                                        v
                                   CallbackModule.init/1

      1. The init/1 callback is invoked, which provides a supervisor specification to the supervisor process.
      2. The supervior behaviour starts the corresponding child processes.
      3. If a child process crash, the supervisor is notified and performs the specified restart strategy.

  ## INTERACTING WITH CHILD PROCESSES

  When we invoke Supervisor.start or Supervisor.start_link, it returns {:ok, supervisor_pid}; we do not know the pids of child processes.
  Thus, if we want to interact with a child process, we must register it under an alias.

  ## EXAMPLES

      ## Start the supervisor process

      Todo.Supervisor.start_link

      ## Do some operations

      pid = Todo.Cache.server_process("masa")
      pid |> Todo.Server.all_entries

      ## Check the number of processes

      length :erlang.processes

      ## Terminate a child process in the supervision tree to see if it restarts correctly

      Process.whereis(:todo_cache)
      Process.whereis(:todo_cache) |> Process.exit(:kill)

      Process.whereis(:process_registry)
      Process.whereis(:process_registry) |> Process.exit(:kill)

      ## Terminate an individual worker to see if it restarts correctly

      Todo.ProcessRegistry.whereis_name({:database_worker, 2})
      Todo.ProcessRegistry.whereis_name({:database_worker, 2}) |> Process.exit(:kill)

      ## Continue to do some operations

      pid = Todo.Cache.server_process("masa")
      pid |> Todo.Server.all_entries

      ## Check the number of processes

      length :erlang.processes

      ## Kill Todo.Cache to see if it is restarted

      Process.whereis(:todo_cache) |> Process.exit(:kill)

      ## Kill Todo.Database to see if it is restarted

      Process.whereis(:database_server) |> Process.exit(:kill)
  """

  @doc """
  Starts the supervisor process.
  """
  def start_link do
    IO.puts "Staring #{__MODULE__}"

    Supervisor.start_link(__MODULE__, nil)
  end

  @doc """
  Only required callback function for the supervisor behaviour.
  Returns a supervisor specification that will be used by the supervisor process.
  """
  def init(_) do
    db_folder = "./persist"

    # the descriptions of the child processes as a list of tuples
    child_processes = [
                        worker(Todo.ProcessRegistry, []),
                        supervisor(Todo.Database, [db_folder]),  # Specify that Todo.Database is a supervisor.
                        worker(Todo.Cache, []),
                      ] |> IO.inspect

    # Must return a supervisor specification.
    supervise(child_processes, strategy: :one_for_one)
  end
end
