defmodule Neo4Ecto.QueryBuilder do
  @moduledoc """
  This module holds the cypher implementation for basic CRUD operations, including:
    - create;
    - delete;
    - update.

  Check more on `cypher/3` and `cypher/4` functions bellow.
  """

  @type node_name() :: String.t()
  @type op_name() :: atom()
  @type params() :: keyword()
  @type cypher_query() :: String.t()
  @type id() :: integer()

  @doc """
  Build a cypher query about the respective params.

  ## Example

      iex> Neo4Ecto.QueryBuilder.cypher(:create, "user", [name: "John Doe", age: 27])
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

  @doc """
  Handles the cypher query generation through an action.

  ## Example

      iex> Neo4Ecto.QueryBuilder.prepare_query(:all, #Ecto.Query<from u0 in User, where u0.name == "frantz", select: u0>)
      "MATCH (n:User) WHERE n.name = 'frantz' RETURN n"

  """
  @spec prepare_query(atom(), Ecto.Query.t()) :: String.t()
  def prepare_query(:all, query) do
    %Ecto.Query.FromExpr{source: {from, _schema}} = query.from
    %Ecto.Query.BooleanExpr{expr: expr} = List.first(query.wheres)

    where = build_where(expr)

    "MATCH (n:#{String.capitalize(from)}) WHERE #{where} RETURN n"
  end

  defp build_where({:==, _context, [args, val | _]}) when is_binary(val) do
    {{:., _, [{:&, _, _}, arg]}, _, _} = args

    format_data([{arg, val}])
  end

  defp build_where({:==, _context, [args, vals | _]}) do
    {{:., _, [{:&, _, _}, arg]}, _, _} = args
    %Ecto.Query.Tagged{type: {_, ^arg}, value: val} = vals

    format_data([{arg, val}])
  end


  defp format_data(fields) do
    fields
    |> Enum.map(fn {k, v} -> "n.#{k} = '#{v}'" end)
    |> Enum.join(", ")
  end
end
