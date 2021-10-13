defmodule Neo4Ecto.Cypher do
  @moduledoc """
  Cypher DSL implementation.

  With this module you will be able to create cypher queries
  programmatically.
  """

  defmodule Query do
    defstruct [sources: nil, wheres: [], select: nil]
  end

  def match(from, opts \\ [])

  def match(from, opts) do
    wheres = Keyword.get(opts, :where)
    %Query{sources: from, wheres: wheres}
  end
end
