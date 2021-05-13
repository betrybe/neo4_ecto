Application.put_env(:neo4_ecto, :ecto_repos, [Repo])

Application.put_env(:neo4_ecto, Repo,
  hostname: "localhost",
  port: 7687,
  pool_size: 15,
  max_overflow: 2
)

Process.flag(:trap_exit, true)

defmodule Neo4Ecto.TestRepo do
  use Ecto.Repo, otp_app: :neo4_ecto, adapter: Neo4Ecto
end

Neo4Ecto.TestRepo.start_link()
