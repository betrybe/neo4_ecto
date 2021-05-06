defmodule Neo4Ecto.Migration.Runner do
  @moduledoc """
  Handles all migration executions
  """

  alias Neo4Ecto

  ## Schema Migration Node Struct
  @enforce_keys [:version, :created_at]
  defstruct [:version, :created_at]

  ## temo ter uma funcao que pega todas a migrations no banco
  def get_versions do
    %Bolt.Sips.Response{results: results} =
      Neo4Ecto.execute("MATCH (sm:SCHEMA_MIGRATION) RETURN sm;")

    results
  end

  ## diferencia versoes de nodes na base dos arquivos
  def diff_versions_to_files(files) do
    ## e retorna o diff que é nao foi executado
    versions = get_versions()
    case versions do
      [] -> files
      _ -> files #faz o diff
    end
  end

  def execute(files) do
    ## roda os fe da mae que nao foi executado
    diff_versions_to_files(files)
    #executa o retorno
  end

  def migration_files() do
    {:ok, files} =
      File.cwd!()
      |> Path.join("priv/repo/migrations/")
      |> File.ls()

    files
  end

  def extract_file_timestamp(files) do
    regex = ~r/^(?<timestamp>([0-9]{14}))(.+?)\.exs/
    Enum.map(files, fn file ->
      regex
      |> Regex.named_captures(file)
      |> Map.put(:filename, file)
    end)
  end

  def run do
    ## roda os fe da mae que nao foi executado
    migration_files()
    |> extract_file_timestamp()
    |> execute()
    |> IO.inspect()
  end
end
