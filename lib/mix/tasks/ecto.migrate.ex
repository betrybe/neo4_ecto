defmodule Mix.Tasks.Ecto.Migrate do
  @moduledoc """
  Mix Task responsible of executing migration files to the Neo4j Database
  """
  use Mix.Task
  import Mix.Ecto
  alias Ecto.Neo4Ecto.Migrator

  # ToDo: Handle migrations for umbrella apps with multiple Repos
  def run(args) do
    [repo] = parse_repo(args)

    {:ok, _started} = Application.ensure_all_started(:neo4_ecto)

    ensure_repo(repo, args)

    case repo.start_link() do
      {:ok, _} ->
        Migrator.run()

      {:error, {:already_started, _pid}} ->
        {:ok, :restart}

      {:error, _} = error ->
        Mix.raise("Could not start repo #{inspect(repo)} error: #{inspect(error)}")
    end
  end
end
