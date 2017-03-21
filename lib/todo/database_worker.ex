defmodule Todo.DatabaseWorker do
  use GenServer

  @moduledoc """
  Performs read/write operations on the file system, which are forwarded from a `Todo.Database` process.
  """

  #---
  # INTERFACE FUNCTIONS
  #---

  @doc """
  Starts a DatabaseWorker server process with the specified initial state.
  """
  def start_link(db_folder, worker_id) do
    IO.puts "Staring #{__MODULE__} #{worker_id}"

    GenServer.start_link __MODULE__,
                         db_folder,
                         name: via_tuple(worker_id)
  end

  @doc """
  Persist e given key data pair to the database.
  """
  def persist(worker_id, key, data) do
    GenServer.cast via_tuple(worker_id), {:persist, key, data}
  end

  @doc """
  Return data for a given key.
  """
  def get(worker_id, key) do
    GenServer.call via_tuple(worker_id), {:get, key}
  end

  # Create a proper via-tuple for dynamically registering a todo-database-worker.
  defp via_tuple(worker_id) do
    {
      :via,
      Todo.ProcessRegistry,          # A registry module
      {:database_worker, worker_id}  # A complex alias
    }
  end

  #---
  # GEN SERVER CALLBACKS
  #---

  def init(db_folder) do
    File.mkdir_p(db_folder) # Ensure that the folder exists.

    {:ok, db_folder}        # Determine the initial state.
  end

  @doc """
  Persist the data to the db_folder
  """
  def handle_cast {:persist, key, data}, db_folder do
    file_name(db_folder, key)
    |> File.write!(:erlang.term_to_binary(data))

    {:noreply, db_folder}
  end

  @doc """
  Read the data from the db_folder
  """
  def handle_call {:get, key}, _caller, db_folder do
    data =  case File.read(file_name(db_folder, key)) do
              {:ok, binary} ->
                :erlang.binary_to_term(binary)
              _else ->
                nil
            end

    {:reply, data, db_folder}
  end

  #---
  # Utilities
  #---

  # Build a file name string for the key.
  defp file_name(db_folder, key) do
    "#{db_folder}/#{key}"
  end
end
