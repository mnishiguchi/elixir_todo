defmodule Todo.Server do
  @moduledoc """
  A stateful server process that wraps Todo.List within.

  USAGE:
    pid = Todo.Server.start
    Todo.Server.add_entry(pid, %{date: {2017, 2, 22}, title: "Study elixir"})
    Todo.Server.add_entry(pid, %{date: {2017, 2, 23}, title: "Study ruby"})
    Todo.Server.all_entries(pid)
    Todo.Server.update_entry(pid, 1, fn(old_entry) -> %{ old_entry | title: "Say hello!" }  end)
    Todo.Server.find_by_date(pid, {2017, 2, 22})
  """

  #---
  # INTERFACE FUNCTIONS
  #---

  def start do
    initial_state = Todo.List.new

    spawn(fn() ->
      loop(initial_state)
    end)
  end

  def add_entry(server_pid, new_entry) do
    send(server_pid, { :add_entry, new_entry })
  end

  def find_by_date(server_pid, date) do
    send(server_pid, { :find_by_date, self, date })

    receive do
      {:entries, entries} -> entries
      after 5000          -> {:error, :timeout}
    end
  end

  def all_entries(server_pid) do
    send(server_pid, { :all_entries, self })

    receive do
      {:entries, entries} -> entries
      after 5000          -> {:error, :timeout}
    end
  end

  def update_entry(server_pid, todo_id, updater_fun) do
    send(server_pid, {:update_entry, self, todo_id, updater_fun})

    receive do
      {:entries, entries} -> entries
      after 5000          -> {:error, :timeout}
    end
  end

  #---
  # IMPLEMENTATION FUNCTIONS
  #---

  defp loop(todo_list) do

    new_todo_list = receive do
      # NOTE: Ensure that process_message function returns a new todo list.
      message -> process_message(todo_list, message)
    end

    loop(new_todo_list)
  end

  defp process_message(todo_list, { :add_entry, new_entry }) do
    Todo.List.add_entry(todo_list, new_entry)
  end

  defp process_message(todo_list, { :find_by_date, caller, date }) do
    send(caller, { :entries, Todo.List.find_by_date(todo_list, date) })
    todo_list  # State remains unchanged.
  end

  defp process_message(todo_list, { :update_entry, caller, todo_id, updater_fun }) do
    send(caller, { :entries, Todo.List.update_entry(todo_list, todo_id, updater_fun) })
  end

  defp process_message(todo_list, { :all_entries, caller }) do
    send(caller, { :entries, Todo.List.all_entries(todo_list) })
    todo_list  # State remains unchanged.
  end
end
