defmodule Todo.Application do
  use Application

  def start(_, _) do
    # Start the application's top-level supervisor.
    Todo.Supervisor.start_link
  end
end
