defmodule Todo.ProcessRegistry do
  use GenServer

  # Explicitly import the Kernel module in order to avoid its name collision with this module's `send/2`.
  # By default, the entire Kernel module is auto-imported.
  # We can still use `Kernel.send/2` via its full qualifier.
  import Kernel, except: [send: 2]

  @moduledoc """
  ## Process registry for a supervisor

  - A simple `gen_server` that maintains the alias-to-pid mapping.
  - Monitor the registered process so that we can detect the termination of the
  registered process and react to it. (unidirectional crash propagation)
  - In real life, we want to uses:
    + [Registry](https://hexdocs.pm/elixir/Registry.html) [released in Elixir 1.4](http://elixir-lang.org/blog/2017/01/05/elixir-v1-4-0-released/)
    + gproc (a third-party library)

  ## Why we need a process registry?
  - If a process is started from a supervisor, we don't have access to the pid of the worker process.
  - We can't keep a process's pid for a long time, because that process might be restarted and its successor will have a different pid.
  - Elixir aliases can only be atoms; thus we need to maintain a key-value map, where the keys are aliases and the values are pids.

  """

  #---
  # INTERFACE FUNCTIONS
  #---

  def start_link do
    IO.puts "Staring #{__MODULE__}"
    GenServer.start_link(__MODULE__, nil, name: :process_registry)
  end

  def register_name(key, pid) do
    GenServer.call(:process_registry, {:register_name, key, pid})
  end

  def whereis_name(key) do
    GenServer.call(:process_registry, {:whereis_name, key})
  end

  def unregister_name(key) do
    GenServer.call(:process_registry, {:unregister_name, key})
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
    {:ok, %{}}
  end

  def handle_call {:register_name, key, pid}, _caller, process_registry do
    case Map.get(process_registry, key) do
      nil ->
        Process.monitor(pid)
        updated_process_registry = Map.put(process_registry, key, pid)

        {:reply, :yes, updated_process_registry}
      _else ->
        {:reply, :no, process_registry}
    end
  end

  def handle_call {:whereis_name, key}, _caller, process_registry do
    {
      :reply,
      Map.get(process_registry, key, :undefined),
      process_registry
    }
  end

  def handle_call {:unregister_name, key}, _caller, process_registry do
    updated_process_registry = Map.delete(process_registry, key)

    {:reply, key, updated_process_registry}
  end

  # Handle a :DOWN message from a monitored process, when that process has terminated.
  def handle_info {:DOWN, _, :process, pid, _}, process_registry do
    {:noreply, deregister_pid(process_registry, pid)}
  end

  # Match-all clause
  def handle_info(_, state), do: {:noreply, state}

  #---
  # PRIVATE FUNCTIONS
  #---

  # https://github.com/sasa1977/elixir-in-action/blob/master/code_samples/ch09/pool_supervision/lib/todo/process_registry.ex#L62
  defp deregister_pid(process_registry, pid) do
    # We'll walk through each {key, value} item, and delete those elements whose
    # value is identical to the provided pid.
    Enum.reduce(
      process_registry, # enumerable
      process_registry, # registry_acc's initial value
      fn
        ({registered_alias, registered_process}, registry_acc) when registered_process == pid ->
          Map.delete(registry_acc, registered_alias)

        (_, registry_acc) -> registry_acc
      end
    )
  end
end
