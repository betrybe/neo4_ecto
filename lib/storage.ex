defmodule Neo4Ecto.Storage do
  @moduledoc """
  Storage Adapter module for Neo4j.
  """
  @behaviour Ecto.Adapter.Storage

  import Mix.Ecto

  @impl true
  def storage_up(opts) do
    repo = ensure_repo_started(opts)

    database =
      Keyword.fetch!(opts, :database) || raise ":database is nil in repository configuration"

    check_database_exists_command = "SHOW DATABASES WHERE name = '#{database}'"

    case run_command(check_database_exists_command, repo) do
      {:ok, []} ->
        create_database_command = "CREATE DATABASE #{database};"

        case run_command(create_database_command, repo) do
          {:ok, _} ->
            :ok

          {:error, error} ->
            {:error, Exception.message(error)}
        end

      _ ->
        {:error, :already_up}
    end
  end

  @impl true
  def storage_down(opts) do
    repo = ensure_repo_started(opts)

    database =
      Keyword.fetch!(opts, :database) || raise ":database is nil in repository configuration"

    drop_database_command = "DROP DATABASE #{database};"

    case run_command(drop_database_command, repo) do
      {:ok, _} ->
        :ok

      {:error, error} ->
        {:error, error}
    end
  end

  @impl true
  def storage_status(opts) do
    repo = ensure_repo_started(opts)

    database =
      Keyword.fetch!(opts, :database) || raise ":database is nil in repository configuration"

    check_database_status = "SHOW DATABASES WHERE name = '#{database}'"

    case run_command(check_database_status, repo) do
      {:ok, []} -> :down
      {:ok, _result} -> :up
      error -> {:error, error}
    end
  end

  defp run_command(cypher, repo) do
    case run_query(cypher, repo) do
      {:ok, %Bolt.Sips.Response{results: results}} ->
        {:ok, results}

      {:ok, %Bolt.Sips.Response{stats: %{"system-updates" => 1}}} ->
        {:ok, :executed}

      {:error,
       %Bolt.Sips.Error{
         code: "Neo.ClientError.Database.DatabaseNotFound"
       }} ->
        {:error, :already_down}
    end
  end

  defp run_query(cypher, repo) do
    case repo.start_link() do
      {:ok, bolt_pid} ->
        conn = Bolt.Sips.conn()

        result = Bolt.Sips.query(conn, cypher)
        GenServer.stop(bolt_pid)
        result

      {:error, _} = error ->
        Mix.raise("Could not start repo #{inspect(repo)} error: #{inspect(error)}")
    end
  end

  defp ensure_repo_started(opts) do
    [repo] = parse_repo(opts)

    {:ok, _started} = Application.ensure_all_started(:neo4_ecto)

    ensure_repo(repo, opts)
    repo
  end
end
