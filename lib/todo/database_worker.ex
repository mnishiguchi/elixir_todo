defmodule Todo.DatabaseWorker do
  use GenServer

  @moduledoc """
  Performs read/write operations on the file system.
  """

  #---
  # INTERFACE FUNCTIONS
  #---

  @doc """
  Starts a DatabaseWorker server process with the specified initial state.
  """
  def start_link(db_folder) do
    IO.puts "Staring #{__MODULE__}"

    # We do not register the process under an alias because we want to run multiple instances.
    GenServer.start_link(__MODULE__, db_folder)
  end

  @doc """
  Persist e given key data pair to the database.
  """
  def persist(worker_pid, key, data) do
    GenServer.cast(worker_pid, {:persist, key, data})
  end

  @doc """
  Return data for a given key.
  """
  def get(worker_pid, key) do
    GenServer.call(worker_pid, {:get, key})
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
  def handle_call {:get, key}, caller, db_folder do
    # Handle file reading in a spawned process.
    spawn(fn() ->
      data =  case File.read(file_name(db_folder, key)) do
                {:ok, binary} -> :erlang.binary_to_term(binary)
                _error        -> nil
              end

      # Respond from inside of the spawned process.
      GenServer.reply(caller, data)
    end)

    # No need to reply from database.
    {:noreply, db_folder}
  end

  #---
  # PRIVATE FUNCTIONS
  #---

  # Build a file name string for the key.
  defp file_name(db_folder, key) do
    "#{db_folder}/#{key}"
  end
end
