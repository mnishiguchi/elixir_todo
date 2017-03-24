defmodule Todo.SystemSupervisor do
  use Supervisor

  @moduledoc """
  The supervisor that responsible for starting the to-do system that depends on the process registry.
  Assumes that process registry is already started and working.
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

    supervise(children, strategy: :one_for_one)
  end
end
