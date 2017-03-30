# ElixirTodo

This is a simple OTP application, with which I practice Elixir programming along with the book "Elixir in Action" by Sasa Juric.

---

## Supervision tree

```elixir
Todo.Application
  └── Todo.Supervisor (rest_for_one) # The top-level supervisor.
        ├── Todo.ProcessRegistry              # Dynamically register processes.
        └── Todo.SystemRegistry (one_for_one) # The todo system.
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
iex(1)> Application.start(:hello_world)
{:error, {:already_started, :hello_world}}
iex(2)> Application.stop(:hello_world)
:ok
17:04:42.874 [info]  Application hello_world exited: :stopped
iex(3)> Application.start(:hello_world)
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

Process.whereis(:process_registry)
Process.whereis(:process_registry) |> Process.exit(:kill)

## Terminate an individual worker to see if it restarts correctly

Todo.ProcessRegistry.whereis_name({:database_worker, 2})
Todo.ProcessRegistry.whereis_name({:database_worker, 2}) |> Process.exit(:kill)

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
