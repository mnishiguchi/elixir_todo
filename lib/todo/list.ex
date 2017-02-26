defmodule Todo.List do
  defstruct auto_id: 1, entries: %{}

  @moduledoc """
  An abstraction that represents a todo list.

  ## DATA STRUCTURE

      todo_list = %Todo.List{ entries: %{}, auto_id: 1 }
      entry     = %{date: {2017, 2, 22}, title: "Study elixir"}
  """

  @doc """
  Create a new Todo.List instance with no entry.
  """
  def new, do: %Todo.List{}

  @doc """
  Create a new Todo.List instance with multiple entries.
  """
  def new(entries \\ []) do
    Enum.reduce entries,                          # A list of entries
                %Todo.List{},                     # The initial accumulator value
                fn(entry, todo_list_acc) ->       # A lambda that updates the accumulator (Shorthand: &add_entry(&2, &1))
                  add_entry(todo_list_acc, entry)
                end
  end

  @doc """
  Add an entry to an existing Todo.List instance.
  """
  def add_entry %Todo.List{ entries: entries, auto_id: auto_id } = todo_list,
                %{ date: _date, title: _title } = entry
  do
    entry       = Map.put(entry, :id, auto_id)      # Set the new id.
    new_entries = Map.put(entries, auto_id, entry)  # Add the new entry to the list.

    # Update the struct and return.
    %Todo.List{ todo_list | entries: new_entries, auto_id: auto_id + 1 }
  end

  @doc """
  Returns a list of entries that match with the specified date.
  """
  def find_by_date %Todo.List{ entries: entries },
                   date
  do
    entries
    |> Stream.filter(
         fn {_, entry} -> entry[:date] == date end) # Filter entries for specified date.
    |> Enum.map(
         fn {_, entry} -> entry end)                # Return a list of results
  end

  @doc """
  Returns all entries.
  """
  def all_entries %Todo.List{ entries: entries } do
    entries
  end

  @doc """
  Update an existing Todo.List instance with the specified entry.
  """
  def update_entry todo_list, %{} = new_entry do
    update_entry(todo_list,
                 new_entry.id,
                 fn(_old_entry) -> new_entry end)
  end

  @doc """
  Update an existing Todo.List instance.
  """
  def update_entry %Todo.List{ entries: entries } = todo_list,  # an instance of Todo.List
                   entry_id,                                    # the id of the entry that we want to update_entry
                   updater_fun                                  # an updater lambda
  do
    case entries[entry_id] do
      nil -> todo_list
      old_entry ->
        new_entry = %{} = updater_fun.(old_entry)  # Ensure that updater_fun returns a map.
        new_entries = Map.put(entries, new_entry.id, new_entry)
        %Todo.List{ todo_list | entries: new_entries }
    end
  end
end
