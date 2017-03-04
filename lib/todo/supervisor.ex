defmodule Todo.Supervisor do
  use Supervisor

  @moduledoc """
  ## STARTING A SUPERVISOR PROCESS

      caller process              supervisor process               child processes
      ================================================================================
                    start                      start and supervise
      caller --------------------> :supervisor -------------------> child processes
                                        |                           (workers)
                                        |  get the spec
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
      # Staring Elixir.Todo.Supervisor
      # Staring Elixir.Todo.Cache
      # Staring Elixir.Todo.Database
      # Staring Elixir.Todo.DatabaseWorker
      # Staring Elixir.Todo.DatabaseWorker
      # Staring Elixir.Todo.DatabaseWorker
      # {:ok, #PID<0.119.0>}

      ## Do some operations

      pid = Todo.Cache.server_process("masa")
      # Staring Elixir.Todo.Server
      # #PID<0.126.0>

      pid |> Todo.Server.all_entries
      # %{1 => %{date: {2017, 2, 22}, id: 1, title: "Say hello!"},
      #   2 => %{date: {2017, 2, 23}, id: 2, title: "Study ruby"},
      #   3 => %{date: {2017, 2, 22}, id: 3, title: "Study elixir"},

      ## Terminate one of the child processes of the supervision tree

      Process.whereis(:todo_cache)
      # #PID<0.120.0>

      Process.whereis(:todo_cache) |> Process.exit(:kill)
      # Staring Elixir.Todo.Cache
      # Staring Elixir.Todo.Database
      # true

      Process.whereis(:todo_cache)
      # #PID<0.132.0>

      ## Continue to do some operations

      pid = Todo.Cache.server_process("masa")
      # Staring Elixir.Todo.Server
      # #PID<0.135.0>

      pid |> Todo.Server.all_entries
      # %{1 => %{date: {2017, 2, 22}, id: 1, title: "Say hello!"},
      #   2 => %{date: {2017, 2, 23}, id: 2, title: "Study ruby"},
      #   3 => %{date: {2017, 2, 22}, id: 3, title: "Study elixir"},
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
    # Supervisor.Spec.worker/2
    #  - imported when `use Supervisor` is invoked
    #  - returns the description of the worker as a tuple
    child_processes = [
      worker(Todo.Cache, [])  # This worker will be started by calling Todo.Cache.start_link with [].
    ]

    # Must return a supervisor specification.
    supervise child_processes,        # processes that are to be started and supervised
              strategy: :one_for_one  # supervisor options
  end
end
