defmodule Todo.Cache do
  use GenServer

  @moduledoc """
  Maintains a collection of Todo.Server instances.
  Responsible for the creation and retrieval of a Todo.Server instance.

  A singleton key-value store of todo-list name to server pid, which
  provides a Todo.Server based on the given todo-list name.

  Exports two functions: start/0 and server_process/2.

                issue a request for
                 a server pid        ________________  handles one at a time
      Client_1 -------------------> |                | (creating / fetching a Todo.Server process)
      Client_2 -------------------> |   Todo.Cache   | ---------> Todo.Server
      Client_3 -------------------> |________________|

  ## STARTING A TODO.CACHE SERVER PROCESS

      {:ok, cache} = Todo.Cache.start_link

  ## STARTING OR FETCHING A TODO.SERVER PROCESS

      masas_pid      = Todo.Cache.server_process("masa")
      christines_pid = Todo.Cache.server_process("christine")

  ## USING THE TODO FUNCTIONALITY

      Todo.Server.add_entry(masas_pid, Todo.List.Entry.for_today("Study elixir"))
      Todo.Server.add_entry(masas_pid, Todo.List.Entry.for_date({2017, 2, 23}, "Study ruby"))
      Todo.Server.all_entries(masas_pid)
      Todo.Server.update_entry(masas_pid, 1, fn(old_entry) -> %{ old_entry | title: "Say hello!" } end)
      Todo.Server.find_by_date(masas_pid, {2017, 2, 22})

      Todo.Server.add_entry(christines_pid, %{date: {2017, 2, 22}, title: "Sing a song"})
      Todo.Server.add_entry(christines_pid, %{date: {2017, 2, 23}, title: "Go to church"})
      Todo.Server.all_entries(christines_pid)
  """

  #---
  # INTERFACE FUNCTIONS
  #---

  def start_link do
    IO.puts "Staring #{__MODULE__}"

    # During the compilation, __MODULE__ is replaced with the current module.
    GenServer.start_link __MODULE__,
                         nil,
                         name: :todo_cache  # local registration
  end

  @doc """
  Returns the pid of a todo-server process.
  """
  def server_process(todo_list_name) do
    # Issue a query for a Todo.Server process.
    case Todo.Server.whereis(todo_list_name) do
      :undefined ->
        GenServer.call :todo_cache, {:server_process, todo_list_name}
      pid -> pid
    end
  end

  #---
  # GEN SERVER CALLBACKS
  #---

  def init(_initial_state) do
    {:ok, nil}  # Determine the initial state.
  end

  def handle_call {:server_process, todo_list_name}, _from, todo_servers do
    # Dynamically start a process for the specified todo-list name.
    {:ok, pid} = Todo.ServerSupervisor.start_child(todo_list_name)

    {:reply, pid, todo_servers}
  end
end
