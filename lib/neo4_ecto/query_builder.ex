defmodule Ecto.Adapters.Neo4Ecto.QueryBuilder do
  @moduledoc false

  @type node_name() :: String.t()
  @type op_name() :: atom()
  @type params() :: keyword()
  @type cypher_query() :: String.t()
  @type id() :: integer()

  @doc """
  Build a cypher query about the respective params.

  ## Example

      iex> Ecto.Adapters.Neo4Ecto.QueryBuilder.cypher(:create, "user", [name: "John Doe", age: 27])
      "CREATE (n:User) SET n.name = 'John Doe', n.age = '27' RETURN n"

  """
  @spec cypher(op_name(), node_name(), params) :: cypher_query()
  def cypher(:create, node, fields) do
    "CREATE (n:#{String.capitalize(node)}) SET #{format_data(fields)} RETURN n"
  end

  @spec cypher(op_name(), node_name(), id()) :: cypher_query()
  def cypher(:delete, node, id) do
    "MATCH (n:#{String.capitalize(node)}) WHERE id(n) = #{id} DELETE n RETURN n"
  end

  @spec cypher(op_name(), node_name(), params(), id()) :: cypher_query()
  def cypher(:update, node, fields, id) do
    "MATCH (n:#{String.capitalize(node)}) WHERE id(n) = #{id} SET #{format_data(fields)} RETURN n"
  end

  defp format_data(fields) do
    fields
    |> Enum.map(fn {k, v} -> "n.#{k} = '#{v}'" end)
    |> Enum.join(", ")
  end
end
