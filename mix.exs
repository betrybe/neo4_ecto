defmodule Neo4Ecto.MixProject do
  use Mix.Project

  def project do
    [
      app: :neo4_ecto,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 3.6.1"},
      {:bolt_sips, "~> 2.0"},
      {:credo, "~> 1.3", only: [:dev, :test], runtime: false}
    ]
  end
end
