defmodule Neo4Ecto.Migration.Runner do
  @moduledoc """
  Handles execution of all migration operations:
    - :up
    - :down
  """

  alias Bolt.Sips

  def run(module, operation, version) do
    migration_query = apply(module, operation, [])

    case operation do
      :up -> up(migration_query, version)
      _ -> nil
    end
  end

  def up(migration_query, version) do
    Sips.conn()
    |> Sips.query!("""
    #{migration_query};
    CREATE (sm:SCHEMA_MIGRATION {version: #{version}, created_at: timestamp()})
    RETURN sm;
    """)
  end
end
