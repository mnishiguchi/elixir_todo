defmodule Todo.ServerSupervisor do
  use Supervisor

  @moduledoc """
  Supervises all the Todo.Server instances so that we can isolate them from the rest of the system.
  The child processes are dynamically started from a Todo.Cache process.
  """

  @doc """
  Starts the supervisor process.
  """
  def start_link do
    IO.puts "Staring #{__MODULE__}"

    Supervisor.start_link __MODULE__,
                          nil,
                          name: :todo_server_supervisor  # local registration
  end

  @doc """
  Dynamically starts a child process.
  """
  def start_child(todo_list_name) do
    Supervisor.start_child :todo_server_supervisor,  # ref to the supervisor
                           [todo_list_name]          # args passed to Todo.Server.start_link
                                                     # NOTE: This list is appended to the one given in the child spec in `init/1`
  end

  @doc """
  Only required callback function for the supervisor behaviour.
  Returns a supervisor specification that will be used by the supervisor process.
  """
  def init(_) do
    # the descriptions of the child processes as a list of tuples
    children =  [
                  worker(Todo.Server, []), # Args will be provided when actually starting a child.
                ] |> IO.inspect

    supervise(children, strategy: :simple_one_for_one)
  end
end
