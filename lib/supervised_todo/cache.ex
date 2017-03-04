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

      Todo.Server.add_entry(masas_pid, %{date: {2017, 2, 22}, title: "Study elixir"})
      Todo.Server.add_entry(masas_pid, %{date: {2017, 2, 23}, title: "Study ruby"})
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
                         name: :todo_cache  # Register a single process under an alias
                                            # and link it to the caller process.
  end

  def server_process(todo_server_uuid) do
    GenServer.call :todo_cache, {:server_process, todo_server_uuid}
  end

  #---
  # GEN SERVER CALLBACKS
  #---

  def init(_initial_state) do
    Todo.Database.start("./persist")
    {:ok, %{}}  # Determine the initial state.
  end

  def handle_call {:server_process, todo_server_uuid}, _from, todo_servers do
    case Map.fetch(todo_servers, todo_server_uuid) do
      {:ok, todo_server} ->
          {:reply, todo_server, todo_servers}  # todo_server exists, reply with its pid.
      :error ->
          {:ok, new_server}  = Todo.Server.start(todo_server_uuid)        # Start a new server process.
          new_state = Map.put(todo_servers, todo_server_uuid, new_server) # Add that server to the state.
          {:reply, new_server, new_state}                                 # Reply with a server pid.
    end
  end
end
