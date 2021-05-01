ExUnit.start()

defmodule Repo do
  use Ecto.Repo, otp_app: :neo4_ecto, adapter: Neo4Ecto
end

Application.put_env(:neo4_ecto, :ecto_repos, [Repo])

Application.put_env(:neo4_ecto, Repo,
  hostname: "localhost",
  port: 7687
)

Repo.start_link()

Process.flag(:trap_exit, true)
