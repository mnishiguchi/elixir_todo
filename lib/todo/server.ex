defmodule Todo.Server do
  use GenServer

  @moduledoc """
  A stateful server process, which holds a single instance of Todo.List abstraction.
  Persists Todo.Lists, relying on Todo.Database.
  Different Todo.Lists are handled by different Todo.Servers so that the system can be efficient.

  ## STARTING A TODO.SERVER STANDALONE

      {:ok, pid} = Todo.Server.start("Masa's list")

  ## STARTING A TODO.SERVER THROUGH TODO.CACHE (RECOMMENDED)

      {:ok, cache}   = Todo.Cache.start
      masas_pid      = Todo.Cache.server_process("Masa's list")
      christines_pid = Todo.Cache.server_process("Christine's list")

  ## USING THE TODO FUNCTIONALITY

      Todo.Server.add_entry(pid, %{date: {2017, 2, 22}, title: "Study elixir"})
      Todo.Server.add_entry(pid, %{date: {2017, 2, 23}, title: "Study ruby"})
      Todo.Server.all_entries(pid)
      Todo.Server.update_entry(pid, 1, fn(old_entry) -> %{old_entry | title: "Say hello!"}  end)
      Todo.Server.find_by_date(pid, {2017, 2, 22})
  """

  #---
  # INTERFACE FUNCTIONS
  #---

  # Returns {:ok, pid} or {:stop, reason}
  def start_link(todo_list_name) do
    IO.puts "Staring #{__MODULE__} #{todo_list_name}"

    GenServer.start_link __MODULE__,
                         todo_list_name,                  # For persisting and fetching a Todo.Server instance from Todo.Database.
                         name: via_tuple(todo_list_name)  # Register in a process registry
  end

  # Create a proper via-tuple for dynamically registering a todo-server.
  defp via_tuple(todo_list_name) do
    {
      :via,
      :gproc,
      {:n, :l, {:todo_server, todo_list_name}} # A complex alias
    }
  end

  # Get a pid for a given todo-list-name.
  def whereis(todo_list_name) do
    :gproc.whereis_name {:n, :l, {:todo_server, todo_list_name}}
  end

  def all_entries(server_pid) do
    GenServer.call server_pid, {:all_entries}
  end

  def find_by_date(server_pid, date) do
    GenServer.call server_pid, {:find_by_date, date}
  end

  def add_entry(server_pid, new_entry) do
    GenServer.cast server_pid, {:add_entry, new_entry}
  end

  def update_entry(server_pid, todo_id, updater_fun) do
    GenServer.cast server_pid, {:update_entry, todo_id, updater_fun}
  end

  def delete_entry(server_pid, todo_id) do
    GenServer.cast server_pid, {:delete_entry, todo_id}
  end

  #---
  # GEN SERVER CALLBACKS
  #---

  def init(todo_list_name) do
    # NOTE: GenServe.start returns only after the process is initialized here, which
    # causes the creater's process to be blocked. So make sure that operations here are quick enough.
    # We can handle the iniitlization asynchronously by sending a request to self as long as our
    # process is not registered under a local alias.
    # If the process is registered, we need to use some special techniques so that
    # we ensure that we are the first one who send a request.
    # Discussed in Elixir in Action Capter 7.3.2.
    schedule_real_init(todo_list_name)

    {:ok, nil}  # We do not initialize state here.
  end

  def handle_call {:all_entries}, _from, {_todo_list_name, todo_list} = state do
    entries = Todo.List.all_entries(todo_list)

    {:reply, entries, state}
  end

  def handle_call {:find_by_date, date}, _from, {_todo_list_name, todo_list} = state do
    entries = Todo.List.find_by_date(todo_list, date)

    {:reply, entries, state}
  end

  def handle_cast {:add_entry, new_entry}, {todo_list_name, todo_list} do
    new_list = Todo.List.add_entry(todo_list, new_entry)
    Todo.Database.persist(todo_list_name, new_list)

    {:noreply, {todo_list_name, new_list}}
  end

  def handle_cast {:update_entry, todo_id, updater_fun}, {todo_list_name, todo_list} do
    new_list = Todo.List.update_entry(todo_list, todo_id, updater_fun)
    Todo.Database.persist(todo_list_name, new_list)

    {:noreply, {todo_list_name, new_list}}
  end

  def handle_cast {:delete_entry, todo_id}, {todo_list_name, todo_list} do
    new_list = Todo.List.delete_entry(todo_list, todo_id)
    Todo.Database.persist(todo_list_name, new_list)

    {:noreply, {todo_list_name, new_list}}
  end

  def handle_cast {:real_init, todo_list_name}, _state do
    todo_list     = Todo.Database.get(todo_list_name) || Todo.List.new
    initial_state = {todo_list_name, todo_list}

    {:noreply, initial_state}
  end

  #---
  # PRIVATE FUNCTIONS
  #---

  defp schedule_real_init(todo_list_name) do
    GenServer.cast self, {:real_init, todo_list_name}
  end
end
