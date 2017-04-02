defmodule Todo.Supervisor do
  use Supervisor

  @moduledoc """
  The top-level supervisor that starts and supervises the process registry and
  the rest of the to-do system. When the registry crashes, the rest of the system will terminate as well.

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
    children =  [
      supervisor(Todo.Database, [db_folder]),  # Specify that Todo.Database is a supervisor.
      supervisor(Todo.ServerSupervisor, []),
      worker(Todo.Cache, []),
    ] |> IO.inspect

    # We use a :rest_for_one strategy, ensuring that a crash of the process registry takes down the entire system.
    supervise(children, strategy: :one_for_one)
  end
end
