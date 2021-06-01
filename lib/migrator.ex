defmodule Ecto.Neo4Ecto.Migrator do
  @moduledoc """
  Handles migrations modules loading and version control
  """

  alias Bolt.Sips
  alias Ecto.{Adapters.Neo4Ecto, Neo4Ecto.Migration.Runner}
  alias Ecto.Neo4Ecto.Migration.Runner

  require Logger

  ## ToDo Reinforce Schema Migration Node Struct
  @enforce_keys [:version, :created_at]
  defstruct [:version, :created_at]

  @migration_path "priv/repo/migrations"

  # ToDo use Repo as first parameter in order to get config dir
  def run do
    migrations_info() |> check_non_executed()
  end

  def run(:down) do
    migrations_info() |> do_run(:down)
  end

  defp migrations_info, do: Enum.map(migration_files(), &extract_migration_info(&1))

  defp get_versions do
    {:ok, %Sips.Response{results: versions}} =
      Neo4Ecto.query("MATCH (sm:SCHEMA_MIGRATION) RETURN sm;")

    versions
  end

  defp versions_numbers(versions) do
    Enum.map(versions, fn version ->
      %{
        "sm" => %Bolt.Sips.Types.Node{
          properties: %{"version" => version_number}
        }
      } = version

      version_number
    end)
  end

  defp check_non_executed(migrations) do
    case get_versions() do
      [] -> migrations |> do_run()
      versions -> pending_migrations(versions, migrations) |> do_run()
    end
  end

  defp pending_migrations(versions, migrations) do
    versions_numbers = versions_numbers(versions)

    Enum.filter(migrations, fn {migration_version, _module, _file} ->
      migration_version not in versions_numbers
    end)
    |> case do
      [] -> :already_up
      migrations -> migrations
    end
  end

  defp do_run(:already_up), do: Logger.info("Migrations already up")
  defp do_run(migrations, operation \\ :up)
  defp do_run([], _operation), do: Logger.info("Migrations finished")

  defp do_run([migration | rest], operation) do
    do_run(migration, operation)
    do_run(rest, operation)
  end

  defp do_run({version, module, _file}, operation) do
    if Code.ensure_loaded?(module) and
         function_exported?(module, operation, 0) do
      Runner.run(module, operation, version)
    end
  end

  defp do_compile_migration(file) do
    file |> Code.compile_file() |> Enum.map(&elem(&1, 0))
  end

  # TODO refactor the way we retrieve migrations path (should come from Repo)
  # maybe migrator should not call Runner module, but the oposite way (line 76)
  defp migration_files do
    File.cwd!()
    |> Path.join(@migration_path)
    |> File.ls!()
  end

  defp extract_migration_info(file) do
    base = Path.basename(file)
    full_path_file = Path.join(@migration_path, file)
    [module] = do_compile_migration(full_path_file)

    case Integer.parse(Path.rootname(base)) do
      {integer, "_" <> name} ->
        {integer, module, name}

      _ ->
        nil
    end
  end
end
