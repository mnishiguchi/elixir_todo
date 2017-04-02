defmodule ElixirTodo.Mixfile do
  use Mix.Project

  def project do
    [app: :elixir_todo,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Application module and runtime dependencies
    [
      applications: [
        :logger,
        :gproc
      ],
      mod: {Todo.Application, []}
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    # Compile-time dependencies
    [
      # Extended process registry for Erlang https://github.com/uwiger/gproc
      {:gproc, "~> 0.5.0"},
      # A mocking library for Erlang http://eproxus.github.com/meck
      {:meck, "0.8.4", only: :test}
    ]
  end
end
