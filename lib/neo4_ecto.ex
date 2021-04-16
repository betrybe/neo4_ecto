defmodule Neo4Ecto do
  @moduledoc false

  @behaviour Ecto.Adapter
  @behaviour Ecto.Adapter.Schema

  @impl true
  defmacro __before_compile__(_opts), do: :ok

  @impl true
  def ensure_all_started(_config, type) do
    {:ok, _} = Application.ensure_all_started(:bolt_sips, type)
  end

  @impl true
  def init(opts) do
    config = opts || neo4j_url()

    {:ok, Bolt.Sips.child_spec(config), %{}}
  end

  @impl true
  def checkout(_adapter_meta, _config, _fun), do: Bolt.Sips.conn()

  @impl true
  def loaders(:binary_id, ecto_type), do: [Ecto.UUID, ecto_type]
  def loaders(_primitive_type, ecto_type), do: [ecto_type]

  @impl true
  def dumpers(:binary_id, ecto_type), do: [ecto_type, Ecto.UUID]
  def dumpers(_primitive_type, ecto_type), do: [ecto_type]

  @impl true
  def autogenerate(:binary_id), do: Ecto.UUID.generate()
  def autogenerate(_), do: nil

  @impl true
  def insert(_adapter_meta, %{source: node}, fields, _on_conflict, _returning, _opts) do
    node
    |> build_query(fields)
    |> execute()
    |> do_insert()
  end

  @impl true
  def insert_all(_, _, _, _, _, _, _, _), do: raise "Not ready yet"

  @impl true
  def update(_, _, _, _, _, _), do: raise "Not ready yet"

  @impl true
  def delete(_, _, _, _), do: raise "Not ready yet"

  def execute(query) do
    Bolt.Sips.conn()
    |> Bolt.Sips.query!(query)
  end

  defp do_insert(response) do
    {:ok, transform(response)}
  end

  defp transform(%Bolt.Sips.Response{records: [[response]]}) do
    Map.new()
    |> Map.put(:id, response.id)
    |> Map.to_list()
  end

  defp build_query(node, data) do
    formatted_data =
      data
      |> Enum.map(fn {k, v} -> "n.#{k} = '#{v}'" end)
      |> Enum.join(", ")

    "CREATE (n:#{String.capitalize(node)}) SET #{formatted_data} RETURN n"
  end

  defp neo4j_url, do: Application.get_env(:neotest, :neo4j_url)
end
