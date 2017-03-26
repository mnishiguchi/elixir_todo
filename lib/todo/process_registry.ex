defmodule Todo.ProcessRegistry do
  use GenServer

  # Explicitly import the Kernel module in order to avoid its name collision with this module's `send/2`.
  # By default, the entire Kernel module is auto-imported.
  # We can still use `Kernel.send/2` via its full qualifier.
  import Kernel, except: [send: 2]

  @moduledoc """
  - Concurrent registry lookups
  - Maintains the alias-to-pid mapping
  - Monitor the registered process so that we can detect the termination of the
  registered process and react to it. (unidirectional crash propagation)
  - Avoid race conditions by keeping registration in the registry's process.
  - In real life, we want to uses:
    + [Registry](https://hexdocs.pm/elixir/Registry.html) [released in Elixir 1.4](http://elixir-lang.org/blog/2017/01/05/elixir-v1-4-0-released/)
    + gproc (a third-party library)
  """

  #---
  # INTERFACE FUNCTIONS
  #---

  def start_link do
    IO.puts "Staring #{__MODULE__}"
    GenServer.start_link(__MODULE__, nil, name: :process_registry)
  end

  def register_name(key, pid) do
    # Avoid race conditions by serializing the writes.
    GenServer.call(:process_registry, {:register_name, key, pid})
  end

  def unregister_name(key) do
    # Avoid race conditions by serializing the writes.
    GenServer.call(:process_registry, {:unregister_name, key})
  end

  @doc """
  Return a pid or `:undefined`
  """
  def whereis_name(key) do
    # Lookups are performed in the client process.
    # Key-based lookups in ETS tables are very fast.
    case :ets.lookup(:process_registry, key) do
      [{^key, pid}] -> pid
      _             -> :undefined
    end
  end

  def send(key, message) do
    case whereis_name(key) do
      :undefined ->
        {:badarg, {key, message}}
      pid ->
        Kernel.send(pid, message)
        pid
    end
  end

  #---
  # GEN SERVER CALLBACKS
  #---

  def init(_) do
    # Create a named ETS table.
    :ets.new(:process_registry, [:named_table, :protected, :set])

    {:ok, nil}  # We do not need state because we use a ETS table instead.
  end

  def handle_call {:register_name, key, pid}, _caller, state do
    # Registers a key-pid pair to the ETS table if it has not already been registered.
    if whereis_name(key) != :undefined do
      {:reply, :no, state}  # Do nothing.
    else
      Process.monitor(pid)                        # Monitor the specified process.
      :ets.insert(:process_registry, {key, pid})  # Register the specified process.

      {:reply, :yes, state}
    end
  end

  def handle_call {:unregister_name, key}, _caller, state do
    # Unregisters a key-pid pair from the ETS table.
    :ets.delete(:process_registry, key)

    {:reply, key, state}
  end

  # Handle a :DOWN message from a monitored process, when that process has terminated.
  def handle_info {:DOWN, _, :process, terminated_pid, _}, state do
    # When the registered process terminates, delete it from the ETC table.
    :ets.match_delete(:process_registry, {:_, terminated_pid})

    {:noreply, state}
  end

  # Match-all clause
  def handle_info(_, state), do: {:noreply, state}
end
