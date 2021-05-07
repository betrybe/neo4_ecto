defmodule Neo4Ecto do
  @moduledoc """
  Neo4j adapter for Ecto.

  Handle Ecto behaviours implementations in a way that enables us
  to use Neo4j like we use Ecto daily.

  Currently, this implementation covers:
  @Ecto.Adapter -> So you can use Neo4Ecto as your repo adapter

  ## Example

        defmodule MyApp.Repo do
          use Ecto.Repo, otp_app: :my_app, adapter: Neo4Ecto
        end

  @Ecto.Adapter.Schema -> You'll be able to use the basic functions of Repo, such as: [Repo.insert/1, Repo.update/2, Repo.delete/1]
  """

  @behaviour Ecto.Adapter
  @behaviour Ecto.Adapter.Schema

  alias Bolt.Sips

  @impl Ecto.Adapter
  defmacro __before_compile__(_opts), do: :ok

  @impl Ecto.Adapter
  def ensure_all_started(_config, type) do
    {:ok, _} = Application.ensure_all_started(:bolt_sips, type)
  end

  @impl Ecto.Adapter
  def init(opts) do
    config = opts || neo4j_url()

    {:ok, Sips.child_spec(config), %{}}
  end

  @impl Ecto.Adapter
  def checkout(_adapter_meta, _config, _fun), do: Sips.conn()

  @impl Ecto.Adapter
  def loaders(:binary_id, ecto_type), do: [Ecto.UUID, ecto_type]
  def loaders(_primitive_type, ecto_type), do: [ecto_type]

  @impl Ecto.Adapter
  def dumpers(:binary_id, ecto_type), do: [ecto_type, Ecto.UUID]
  def dumpers(_primitive_type, ecto_type), do: [ecto_type]

  @impl Ecto.Adapter.Schema
  def autogenerate(:binary_id), do: Ecto.UUID.generate()
  def autogenerate(_), do: nil

  @impl Ecto.Adapter.Schema
  def insert(_adapter_meta, %{source: node}, fields, _on_conflict, _returning, _opts) do
    "CREATE (n:#{String.capitalize(node)}) SET #{format_data(fields)} RETURN n"
    |> execute()
    |> do_insert()
  end

  @impl Ecto.Adapter.Schema
  def insert_all(_, _, _, _, _, _, _, _), do: raise("Not ready yet")

  @impl Ecto.Adapter.Schema
  def update(_adapter_meta, %{source: node}, fields, [id: id], _returning, _opts) do
    "MATCH (n:#{String.capitalize(node)}) WHERE id(n) = #{id} SET #{format_data(fields)} RETURN n"
    |> execute()
    |> do_update()
  end

  @impl Ecto.Adapter.Schema
  def delete(_adapter_meta, %{source: node}, [id: id], _opts) do
    "MATCH (n:#{String.capitalize(node)}) WHERE id(n) = #{id} DELETE n RETURN n"
    |> execute()
    |> do_delete()
  end

  def execute(query) do
    Sips.conn()
    |> Sips.query(query)
    |> case do
      {:ok, response} -> parse_response(response)
      {:error, error} -> {:error, error}
    end
  end

  defp do_insert(%Sips.Response{records: [[response]]}), do: {:ok, [id: response.id]}

  defp do_update(_response), do: {:ok, []}

  defp do_delete(_response), do: {:ok, []}

  defp format_data(fields) do
    fields
    |> Enum.map(fn {k, v} -> "n.#{k} = '#{v}'" end)
    |> Enum.join(", ")
  end

  defp parse_response(%Bolt.Sips.Response{type: type} = response) do
    case type do
      r when r in ["r", "rw"] ->
        %Bolt.Sips.Response{results: results} = response
        {:ok, results}

      w when w in ["w"] ->
        %Bolt.Sips.Response{stats: stats} = response
        {:ok, stats}
    end
  end

  defp neo4j_url, do: Application.get_env(:neotest, :neo4j_url)
end
