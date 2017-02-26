defmodule Todo.DatabaseWorker do
  use GenServer

  @moduledoc """
  Persists Todo.List to the local file system.
  """

  #---
  # INTERFACE FUNCTIONS
  #---

  @doc """
  Starts a DatabaseWorker server process with the specified initial state.
  """
  def start(db_folder) do
    # We do not register the process under an alias because we want to run multiple instances.
    GenServer.start(__MODULE__, db_folder)
  end

  def persist(pid, key, data) do
    GenServer.cast(pid, { :persist, key, data })
  end

  def get(pid, key) do
    GenServer.call(pid, { :get, key })
  end

  #---
  # GEN SERVER CALLBACKS
  #---

  def init(db_folder) do
    File.mkdir_p(db_folder) # Ensure that the folder exists.

    { :ok, db_folder }      # Determine the initial state.
  end

  @doc """
  Store the data to the db_folder
  """
  def handle_cast({ :persist, key, data }, db_folder) do
    # Handle file writing in a spawned process.
    spawn(fn() ->
      file_name(db_folder, key)
      |> File.write!(:erlang.term_to_binary(data))
    end)

    { :noreply, db_folder }
  end

  # def handle_cast({ :persist, key, data }, db_folder) do
  #   file_name(db_folder, key)
  #   |> File.write!(:erlang.term_to_binary(data))
  #
  #   { :noreply, db_folder }
  # end

  @doc """
  Read the data from the db_folder
  """
  def handle_call({ :get, key }, caller, db_folder) do
    # Handle file reading in a spawned process.
    spawn(fn() ->
      data =  case File.read(file_name(db_folder, key)) do
                { :ok, binary } -> :erlang.binary_to_term(binary)
                _error          -> nil
              end

      # Respond from inside of the spawned process.
      GenServer.reply(caller, data)
    end)

    # No need to reply from database.
    { :noreply, db_folder }
  end

  # def handle_call({ :get, key }, _from, db_folder) do
  #   data =  case File.read(file_name(db_folder, key)) do
  #             { :ok, binary } -> :erlang.binary_to_term(binary)
  #             _error          -> nil
  #           end
  #
  #   { :reply, data, db_folder }
  # end

  @docp """
  Build a file name string for the key.
  """
  defp file_name(db_folder, key) do
    "#{db_folder}/#{key}"
  end
end
