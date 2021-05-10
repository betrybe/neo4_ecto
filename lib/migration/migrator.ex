defmodule Neo4Ecto.Migration.Migrator do
  @moduledoc """
  Handles migrations modules loading and version control
  """

  alias Neo4Ecto.Migration.Runner

  ## ToDo Reinforce Schema Migration Node Struct
  @enforce_keys [:version, :created_at]
  defstruct [:version, :created_at]

  def run do
    migrations_files = migration_files()
    migration_info = Enum.map(migrations_files, &extract_migration_info(&1))

    check_non_executed(migration_info)
  end

  def get_versions do
    {:ok, versions} = Neo4Ecto.execute("MATCH (sm:SCHEMA_MIGRATION) RETURN sm;")
    versions
  end

  def check_non_executed([migration_info]) do
    case get_versions() do
      [] -> do_run(migration_info)
      _versions -> migration_info
    end
  end

  defp do_run({version, module, _file}, operation \\ :up) do
    if Code.ensure_loaded?(module) and
         function_exported?(module, operation, 0) do
      Runner.run(module, operation, version)
    end
  end

  defp do_compile_migration(file) do
    file |> Code.compile_file() |> Enum.map(&elem(&1, 0))
  end

  defp migration_files do
    File.cwd!()
    |> Path.join("priv/repo/migrations/")
    |> File.ls!()
  end

  defp extract_migration_info(file) do
    base = Path.basename(file)
    full_path_file = Path.join("priv/repo/migrations/", file)
    [module] = do_compile_migration(full_path_file)

    case Integer.parse(Path.rootname(base)) do
      {integer, "_" <> name} ->
        {integer, module, name}

      _ ->
        nil
    end
  end
end
