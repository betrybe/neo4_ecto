defmodule Mix.Tasks.Ecto.Migrate do
  @moduledoc """
  Mix Task responsible of executing migration files to the Neo4j Database
  """
  use Mix.Task
  alias Neo4Ecto.Migration.Runner

  def run(_args) do
  end
end
