defmodule Todo.Server do
  use GenServer

  @moduledoc """
  A stateful server process built with the GenServer behaviour, which wraps Todo.List within.
  Persists the todo list relying on Todo.Database.
  Different Todo.Lists are handled by different Todo.Servers so that the systen can be efficient.

  ## STARTING A TODO.SERVER STANDALONE

      {:ok, pid} = Todo.Server.start("Masa's list")

  ## STARTING A TODO.SERVER THROUGH TODO.CACHE (RECOMMENDED)

      {:ok, cache}   = Todo.Cache.start
      masas_pid      = Todo.Cache.server_process(cache, "Masa's list")
      christines_pid = Todo.Cache.server_process(cache, "Christine's list")

  ## USING THE TODO FUNCTIONALITY

      Todo.Server.add_entry(pid, %{date: {2017, 2, 22}, title: "Study elixir"})
      Todo.Server.add_entry(pid, %{date: {2017, 2, 23}, title: "Study ruby"})
      Todo.Server.all_entries(pid)
      Todo.Server.update_entry(pid, 1, fn(old_entry) -> %{ old_entry | title: "Say hello!" }  end)
      Todo.Server.find_by_date(pid, {2017, 2, 22})
  """

  #---
  # INTERFACE FUNCTIONS
  #---

  # Returns {:ok, pid} or {:stop, reason}
  def start(uuid) do
    GenServer.start(__MODULE__,  # Will be replaced with the current module during the compilation.
                    uuid)        # For persisting and fetching a Todo.Server instance from Todo.Database.
  end

  def all_entries(server_pid) do
    GenServer.call(server_pid, { :all_entries })
  end

  def find_by_date(server_pid, date) do
    GenServer.call(server_pid, { :find_by_date, date })
  end

  def add_entry(server_pid, new_entry) do
    GenServer.cast(server_pid, { :add_entry, new_entry })
  end

  def update_entry(server_pid, todo_id, updater_fun) do
    GenServer.cast(server_pid, { :update_entry, todo_id, updater_fun })
  end

  #---
  # GEN SERVER CALLBACKS
  #---

  def init(uuid) do
    # NOTE: GenServe.start returns only after the process is initialized here, which
    # causes the creater's process to be blocked. So make sure that operations here are quick enough.
    # We can handle the iniitlization asynchronously by sending a request to self as long as our
    # process is not registered under a local alias.
    # If the process is registered, we need to use some special techniques so that
    # we ensure that we are the first one who send a request.
    # Discussed in Elixir in Action Capter 7.3.2.
    schedule_real_init(uuid)

    { :ok, nil }  # We do not initialize state here.
  end

  def handle_call({ :all_entries }, _from, { _uuid, todo_list } = state) do
    entries = Todo.List.all_entries(todo_list)

    { :reply, entries, state }
  end

  def handle_call({ :find_by_date, date }, _from, { _uuid, todo_list } = state) do
    entries = Todo.List.find_by_date(todo_list, date)

    { :reply, entries, state }
  end

  def handle_cast({ :add_entry, new_entry }, { uuid, todo_list }) do
    new_list = Todo.List.add_entry(todo_list, new_entry)
    Todo.Database.persist(uuid, new_list)

    { :noreply, { uuid, new_list } }
  end

  def handle_cast({ :update_entry, todo_id, updater_fun }, { uuid, todo_list }) do
    new_list = Todo.List.update_entry(todo_list, todo_id, updater_fun)
    Todo.Database.persist(uuid, new_list)

    { :noreply, { uuid, new_list } }
  end

  def handle_cast({ :real_init, uuid }, _state) do
    todo_list     = Todo.Database.get(uuid) || Todo.List.new
    initial_state = { uuid, todo_list }

    { :noreply, initial_state }
  end

  #---
  # PRIVATE FUNCTIONS
  #---

  defp schedule_real_init(uuid) do
    GenServer.cast(self, { :real_init, uuid })
  end
end
