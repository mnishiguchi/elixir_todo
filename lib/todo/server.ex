defmodule Todo.Server do
  use GenServer

  @moduledoc """
  A stateful server process built with the GenServer behaviour, which wraps Todo.List within.
  """

  @docp """
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
    GenServer.start(__MODULE__, nil )  # Callback module atom is the current module
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
  def init(_initial_state) do
    { :ok, Todo.List.new }  # Determine the initial state.
  end

  def handle_call({ :all_entries }, _from, state) do
    entries = Todo.List.all_entries(state)
    { :reply, entries, state }
  end

  def handle_call({ :find_by_date, date }, _from, state) do
    entries = Todo.List.find_by_date(state, date)
    { :reply, entries, state }
  end

  def handle_cast({ :add_entry, new_entry }, state) do
    new_state = Todo.List.add_entry(state, new_entry)
    { :noreply, new_state }
  end

  def handle_cast({ :update_entry, todo_id, updater_fun }, state) do
    new_state = Todo.List.update_entry(state, todo_id, updater_fun)
    { :noreply, new_state }
  end
end
