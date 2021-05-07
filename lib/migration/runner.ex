defmodule Neo4Ecto.Migration.Runner do
  @moduledoc """
  Handles all migration executions
  """

  alias Neo4Ecto

  ## Schema Migration Node Struct
  @enforce_keys [:version, :created_at]
  defstruct [:version, :created_at]

  def run do
    migrations =
      migration_files()
      |> extract_migration_timestamp()

    IO.inspect(migrations)
    check_non_executed(migrations)
  end

  def get_versions do
    Neo4Ecto.execute("MATCH (sm:SCHEMA_MIGRATION) RETURN sm;")
  end

  def check_non_executed(files) do
    versions = get_versions()

    case get_versions do
      [] -> execute(files)
      versions -> files
    end
  end

  def execute(files) do
    ## Abrir arquivo
    ## Acessar Module dele
    ## Extrair oque tiver dentro da funcao Up and down

    # file_path ->  Trybe.Repo.Migrations.CreateMigrationDefaultPrefix.up
    # Enum.map(files, fn x -> )
  end

  defp migration_files do
    File.cwd!()
    |> Path.join("priv/repo/migrations/")
    |> File.ls!()
  end

  defp extract_migration_timestamp(files) do
    Enum.map(files, fn file ->
      %{"timestamp" => timestamp} =
        Regex.named_captures(~r/^(?<timestamp>([0-9]{14}))(.+?)\.exs/, file)

      {file, timestamp}
    end)
  end
end
