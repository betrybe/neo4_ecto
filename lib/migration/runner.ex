defmodule Neo4Ecto.Migration.Runner do
  @moduledoc """
  Handles execution of all migration operations:
    - :up
    - :down
  """
  require Logger

  alias Bolt.Sips

  def run(module, operation, version) do
    migration_query = apply(module, operation, [])

    Logger.info("== Running #{version} #{inspect(module)}.#{operation}/0")

    case operation do
      :up -> up(migration_query, version)
      :down -> down(migration_query, version)
      _ -> nil
    end
  end

  def up(migration_query, version) do
    query(
      """
      #{migration_query};
      CREATE (sm:SCHEMA_MIGRATION {version: #{version}, created_at: timestamp()})
      RETURN sm;
      """,
      version
    )
  end

  defp down(migration_query, version) do
    query(
      """
       #{migration_query};
      MATCH (sm:SCHEMA_MIGRATION {version: #{version}})
      DELETE sm
      """,
      version
    )
  end

  defp query(query, version) do
    {time, _} =
      :timer.tc(fn ->
        Sips.conn()
        |> Sips.query!(query)
      end)

    Logger.info("== Migrated #{version} in #{inspect(div(time, 100_000) / 10)}s")
  end
end
