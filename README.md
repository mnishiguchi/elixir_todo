# ElixirTodo

This is a simple OTP application, with which I practice Elixir programming along with the book "Elixir in Action" by Sasa Juric.

---

## Supervision tree

```elixir
Todo.Application
  └── Todo.Supervisor (one_for_one) # The top-level supervisor.
        └── Todo.SystemSupervisor (one_for_one) # The todo system.
              ├── Todo.PoolSupervisor (one_for_one) # Start all the children from here.
              │     ├── Todo.DatabaseWorker 1
              │     ├── Todo.DatabaseWorker 2
              │     ├── Todo.DatabaseWorker n
              │     :
              ├── Todo.ServerSupervisor (simple_one_for_one) # Start no child from here.
              │     ├── Todo.Server 1 # Dynamically started on demand from a caller.
              │     ├── Todo.Server 2 # Dynamically started on demand from a caller.
              │     ├── Todo.Server n # Dynamically started on demand from a caller.
              │     :
              └── Todo.Cache # The interface for Todo.Server instances.
```

---

## Usage

```elixir
# The app is automatically started.
$ iex -S mix

# Only one instance per application is allowed.
iex(1)> Application.start(:elixir_todo)
{:error, {:already_started, :elixir_todo}}
iex(2)> Application.stop(:elixir_todo)
:ok
17:04:42.874 [info]  Application elixir_todo exited: :stopped
iex(3)> Application.start(:elixir_todo)
:ok
```

```elixir
## Do some operations

pid = Todo.Cache.server_process("masa")
pid |> Todo.Server.all_entries

## Check the number of processes

length :erlang.processes

## Terminate a child process in the supervision tree to see if it restarts correctly

Process.whereis(:todo_cache)
Process.whereis(:todo_cache) |> Process.exit(:kill)

## Terminate an individual worker to see if it restarts correctly

:gproc.whereis_name({:n, :l, {:database_worker, 2}})
:gproc.whereis_name({:n, :l, {:database_worker, 2}}) |> Process.exit(:kill)

## Continue to do some operations

pid = Todo.Cache.server_process("masa")
pid |> Todo.Server.all_entries

## Check the number of processes

length :erlang.processes

## Kill Todo.Cache to see if it restarts correctly

Process.whereis(:todo_cache) |> Process.exit(:kill)

## Kill Todo.Database to see if it restarts correctly

Process.whereis(:database_server) |> Process.exit(:kill)
```

---

## Libraries

### [gproc](https://github.com/uwiger/gproc)
Extended process registry for Erlang

```elixir
def start_link(todo_list_name) do
  GenServer.start_link __MODULE__,
                       todo_list_name,  
                       name: via_tuple(todo_list_name)  # Register in the gproc registry
end

defp via_tuple(todo_list_name) do
  {
    :via, :gproc, { :n,                            # type:  unique registration (:n)
                    :l,                            # scope: local (:l)
                    {:todo_server, todo_list_name} # complex alias
                  }
  }
end

def whereis(todo_list_name) do
  :gproc.whereis_name {:n, :l, {:todo_server, todo_list_name}}
end
```
