defmodule Neo4Ecto.Behaviours.Query do
  @moduledoc """
  Query Behaviour implementation.
  """

  require Logger

  @doc false
  defmacro __using__(_opts) do
    quote do
      @behaviour Ecto.Adapter.Queryable

      @impl Ecto.Adapter.Queryable
      def prepare(op, query) do
        {:cache, Neo4Ecto.QueryBuilder.prepare_query(op, query)}
      end

      @impl Ecto.Adapter.Queryable
      def execute(adapter_meta, query_meta, query, params, opts) do
        query
        |> elem(2)
        |> query()
        |> struct_response()
      end
    end
  end
end
