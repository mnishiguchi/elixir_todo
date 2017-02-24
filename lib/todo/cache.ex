defmodule Todo.Cache do
  use GenServer

  @moduledoc """
  A singleton key-value store of Todo.List servers.
  Associates a server name with a server pid.
  Exports two functions: start/0 and server_process/2.
  """

  @docp """
  USAGE:
    {:ok, cache} = Todo.Cache.start

    masas_list      = Todo.Cache.server_process(cache, "masa")
    christines_list = Todo.Cache.server_process(cache, "christine")

    Todo.Server.add_entry(masas_list, %{date: {2017, 2, 22}, title: "Study elixir"})
    Todo.Server.add_entry(masas_list, %{date: {2017, 2, 23}, title: "Study ruby"})
    Todo.Server.all_entries(masas_list)
    Todo.Server.update_entry(masas_list, 1, fn(old_entry) -> %{ old_entry | title: "Say hello!" }  end)
    Todo.Server.find_by_date(masas_list, {2017, 2, 22})

    Todo.Server.add_entry(christines_list, %{date: {2017, 2, 22}, title: "Sing a song"})
    Todo.Server.add_entry(christines_list, %{date: {2017, 2, 23}, title: "Go to church"})
    Todo.Server.all_entries(christines_list)
  """

  #---
  # INTERFACE FUNCTIONS
  #---

  def start do
    # During the compilation, __MODULE__ is replaced with the current module.
    GenServer.start(__MODULE__, nil)
  end

  def server_process(cache_pid, todo_list_name) do
    GenServer.call(cache_pid, { :server_process, todo_list_name })
  end

  #---
  # GEN SERVER CALLBACKS
  #---

  def init(_initial_state) do
    { :ok, %{} } # Initial state is an empty map.
  end

  def handle_call({ :server_process, todo_list_name }, _from, todo_servers) do
    case Map.fetch(todo_servers, todo_list_name) do
      { :ok, todo_server } ->
          # todo_server exists, reply with its pid.
          { :reply, todo_server, todo_servers }
      :error ->
          # Start a new server process.
          { :ok, new_server }  = Todo.Server.start
          # Add that server to the state.
          new_state = Map.put(todo_servers, todo_list_name, new_server)
          # Reply with a server pid.
          { :reply, new_server, new_state }
    end
  end
end
