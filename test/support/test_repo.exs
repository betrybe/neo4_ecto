Application.put_env(:neo4_ecto, :ecto_repos, [Neo4Ecto.TestRepo])

Application.put_env(:neo4_ecto, Neo4Ecto.TestRepo,
  database: "neo4ecto",
  hostname: "localhost",
  basic_auth: [username: "neo4j", password: "123456"],
  port: 7687,
  pool_size: 5,
  max_overflow: 1
)

Process.flag(:trap_exit, true)

defmodule Neo4Ecto.TestRepo do
  use Ecto.Repo, otp_app: :neo4_ecto, adapter: Ecto.Adapters.Neo4Ecto
end

Neo4Ecto.TestRepo.start_link()
