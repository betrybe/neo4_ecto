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
    Neo4Ecto.execute("MATCH (sm:SCHEMA_MIGRATION) RETURN sm;")
  end

  ## diferencia versoes de nodes na base dos arquivos
  def diff_versions_to_files do
    ## e retorna o diff que é nao foi executado
  end

  def execute do
    ## roda os fe da mae que nao foi executado
  end

  def run do
    ##
  end
end
