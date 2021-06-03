defmodule Ecto.Adapters.Neo4Ecto.QueryBuilderTest do
  use ExUnit.Case

  alias Ecto.Adapters.Neo4Ecto.QueryBuilder

  doctest Ecto.Adapters.Neo4Ecto.QueryBuilder

  describe "create cypher" do
    test "returns create query when valid params" do
      assert QueryBuilder.cypher(:create, "user", name: "John Doe") ==
               "CREATE (n:User) SET n.name = 'John Doe' RETURN n"
    end
  end

  describe "update cypher" do
    test "returns update query when valid params" do
      assert QueryBuilder.cypher(:update, "user", [name: "John Doe"], 1) ==
               "MATCH (n:User) WHERE id(n) = 1 SET n.name = 'John Doe' RETURN n"
    end
  end

  describe "delete cypher" do
    test "returns delete query when valid params" do
      assert QueryBuilder.cypher(:delete, "user", 1) ==
               "MATCH (n:User) WHERE id(n) = 1 DELETE n RETURN n"
    end
  end
end
