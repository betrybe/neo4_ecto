defmodule Ecto.Adapters.Neo4Ecto do
  @moduledoc """
  Neo4Ecto is a Neo4j Adapter for Ecto.

  Through Neo4Ecto we can do normal Ecto implementations to connect
  and manage our Neo4j database in a much simpler way.

  Currently Neo4Ecto handles 3 of the main components from Ecto:
    * `Ecto.Adapter`
    * `Ecto.Adapter.Schema`
    * `Ecto.Adapter.Storage`

  ## Config Example

  Set `Neo4Ecto` as the default Ecto Adapter inside your Repo module:

      defmodule MyApp.Repo do
        use Ecto.Repo, otp_app: :my_app, adapter: Ecto.Adapters.Neo4Ecto
      end

  Add the proper configuration for Ecto to recognize your Neo4j
  Database, you may want something like this in your `config/config.exs`:

      config :my_app, ecto_repos: [MyApp.Repo]

      config :my_app, Repo,
        hostname: "localhost",
        basic_auth: [username: "neo4j", password: "password"],
        pool_size: 5

  Then your good to go.

  ## Usage

  From here, creating schemas, changesets and contexts feels just like doing normal Ecto stuff, that's why
  we really appreciate using Ecto as our standard library.

  Give it a try:

      defmodule MyApp.Context.User do
        @moduledoc false

        use Ecto.Schema
        import Ecto.Changeset

        schema "user" do
          field :name, :string
          field :age, :integer
        end

        @doc false
        def changeset(user, attrs) do
          user
          |> cast(attrs, [:name, :age])
        end
      end

  Now you have a ready to battle `User` schema.

      alias MyApp.Context.User
      alias MyApp.Repo

      attrs = %{name: "John Doe", age: 30}

      %User{}
      |> User.changeset(attrs)
      |> Repo.insert()

  """
  @behaviour Ecto.Adapter
  @behaviour Ecto.Adapter.Schema
  @behaviour Ecto.Adapter.Storage

  import Ecto.Adapters.Neo4Ecto.QueryBuilder

  alias Bolt.Sips

  @impl Ecto.Adapter
  defmacro __before_compile__(env) do
    Ecto.Adapters.Neo4Ecto.before_compile(env)
  end

  @impl Ecto.Adapter
  def ensure_all_started(_config, type) do
    {:ok, _} = Application.ensure_all_started(:bolt_sips, type)
  end

  @impl Ecto.Adapter
  def init(opts) do
    config = opts
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

  @impl Ecto.Adapter.Storage
  defdelegate storage_up(config), to: Neo4Ecto.Storage
  @impl Ecto.Adapter.Storage
  defdelegate storage_down(config), to: Neo4Ecto.Storage
  @impl Ecto.Adapter.Storage
  defdelegate storage_status(config), to: Neo4Ecto.Storage

  @impl Ecto.Adapter.Schema
  def autogenerate(:binary_id), do: Ecto.UUID.generate()
  def autogenerate(_), do: nil

  @impl Ecto.Adapter.Schema
  def insert(_adapter_meta, %{source: node}, fields, _on_conflict, _returning, _opts) do
    :create
    |> cypher(node, fields)
    |> query()
    |> struct_response()
  end

  @impl Ecto.Adapter.Schema
  def insert_all(_, _, _, _, _, _, _, _), do: raise("Not ready yet")

  @impl Ecto.Adapter.Schema
  def update(_adapter_meta, %{source: node}, fields, [id: id], _returning, _opts) do
    :update
    |> cypher(node, fields, id)
    |> query()
    |> struct_response()
    |> do_update()
  end

  @impl Ecto.Adapter.Schema
  def delete(_adapter_meta, %{source: node}, [id: id], _opts) do
    :delete
    |> cypher(node, id)
    |> query()
    |> struct_response()
    |> do_delete()
  end

  # ToDo: Refactor delete and update responses to follow Repo.Schema.load_each/4 pattern
  ##  defp load_each(struct, [{_, value} | kv], [{key, type} | types], adapter)
  ##  defp load_each(struct, [], _types, _adapter)

  defp do_update(_response), do: {:ok, []}

  defp do_delete(_response), do: {:ok, []}

  def struct_response({:ok, %Sips.Response{type: type} = response}) do
    case type do
      rw when rw in ["rw"] ->
        %Sips.Response{records: [[response]]} = response
        {:ok, [id: response.id]}

      r when r in ["r"] ->
        %Sips.Response{results: results} = response
        {:ok, results}

      w when w in ["w"] ->
        %Sips.Response{stats: stats} = response
        {:ok, stats}
    end
  end

  @doc """
  Run a pure Cypher query directly on database.

  On success, it returns a Bolt Sips Tuple containing
  a map with two keys: %{:ok, %Bolt.Sips.Response{}}

  ### Example
      iex> Ecto.Adapters.Neo4Ecto.query("MATCH (n:User {id: $id}", %{id: "unique_id"})

      or without params

      iex> Ecto.Adapters.Neo4Ecto.query("MATCH (n:User {id: 1}")
  """
  def query(query, params \\ %{})

  def query(query, params) when is_struct(params) do
    map_params = Map.from_struct(params)
    query(query, map_params)
  end

  def query(query, params) when is_map(params) do
    conn = Sips.conn()
    Sips.query(conn, query, params)
  end

  @doc """
    Same as `query/2` but raises on invalid queries.
  """
  def query!(query, params \\ %{})

  def query!(query, params) when is_struct(params) do
    map_params = Map.from_struct(params)
    query!(query, map_params)
  end

  def query!(query, params) when is_map(params) do
    conn = Sips.conn()
    Sips.query!(conn, query, params)
  end

  @doc false
  def before_compile(_env) do
    quote do
      def query(query, params \\ %{}) do
        Ecto.Adapters.Neo4Ecto.query(query, params)
      end

      def query!(query, params \\ %{}) do
        Ecto.Adapters.Neo4Ecto.query!(query, params)
      end
    end
  end
end
