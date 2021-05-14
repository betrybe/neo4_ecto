defmodule Neo4Ecto.MixProject do
  use Mix.Project

  def project do
    [
      app: :neo4_ecto,
      version: "0.0.1",
      elixir: "~> 1.8",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: description()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 3.6.1"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:bolt_sips, "~> 2.0"},
      {:credo, "~> 1.3", only: [:dev, :test], runtime: false}
    ]
  end

  defp description do
    "Neo4Ecto is an Ecto adapter that sits on top of Bolt.Sips driver."
  end

  defp package do
    [
      # These are the default files included in the package
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/betrybe/neo4_ecto/"}
    ]
  end
end
