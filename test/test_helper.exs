ExUnit.start()

defmodule Repo do
  use Ecto.Repo, otp_app: :neo4_ecto, adapter: Neo4Ecto
end

defmodule User do
  use Ecto.Schema

  import Ecto.Changeset

  schema "user" do
    field(:name, :string)
  end

  @fields ~w(name)a

  def changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, @fields)
    |> validate_required(@fields)
  end

  def update_changeset(%__MODULE__{} = user, attrs) do
    user
    |> cast(attrs, @fields)
    |> validate_required(@fields)
  end
end

Application.put_env(:neo4_ecto, :ecto_repos, [Repo])

Application.put_env(:neo4_ecto, Repo,
  hostname: "localhost",
  basic_auth: [username: "neo4j", password: "123456"],
  port: 7687,
  pool_size: 15,
  max_overflow: 2,
  database: "neo4jtest"
)

Process.flag(:trap_exit, true)
