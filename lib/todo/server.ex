defmodule Todo.Server do
  use GenServer

  @moduledoc """
  A stateful server process built with the GenServer behaviour, which wraps Todo.List within.

  USAGE:
    {:ok, pid} = Todo.Server.start
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
  def start do
    GenServer.start(Todo.Server,     # Callback module atom
                    Todo.List.new)   # Initial params
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

  # The first argument provides initial data to GenServer.start/2's second argument.
  def init(initial_state) do
    { :ok, initial_state }
  end

  def handle_call({ :all_entries }, _for_internal_use, state) do
    { :reply, Todo.List.all_entries(state), state }
  end

  def handle_call({ :find_by_date, date }, _for_internal_use, state) do
    { :reply, Todo.List.find_by_date(state, date), state }
  end

  def handle_cast({ :add_entry, new_entry }, state) do
    { :noreply, Todo.List.add_entry(state, new_entry) }
  end

  def handle_cast({ :update_entry, todo_id, updater_fun }, state) do
    { :noreply, Todo.List.update_entry(state, todo_id, updater_fun)}
  end
end
