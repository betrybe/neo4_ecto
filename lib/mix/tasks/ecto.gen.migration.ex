defmodule Mix.Tasks.Ecto.Gen.Migration do
  @moduledoc """
  Task responsible for generating new migration files.
  """
  use Mix.Task

  import Macro, only: [camelize: 1, underscore: 1]
  import Mix.Generator
  import Mix.Ecto

  def run(args) do
    repo = parse_repo(args)

    case OptionParser.parse!(args, strict: [source: :string]) do
      {_opts, [name]} ->
        migration_file = "#{timestamp()}_#{underscore(name)}.exs"
        file = create_repo_migrations_path(migration_file)

        assigns = [mod: Module.concat([repo, Migrations, camelize(name)])]
        create_file(file, migration_template(assigns))

        file

      {_, _} ->
        Mix.raise(
          "expected ecto.gen.migration to receive the migration file name, " <>
            "got: #{inspect(Enum.join(args, " "))}"
        )
    end
  end

  def create_repo_migrations_path(migration_file) do
    File.cwd!()
    |> Path.join("priv/repo/migrations/#{migration_file}")
  end

  defp timestamp do
    {{y, m, d}, {hh, mm, ss}} = :calendar.universal_time()
    "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  end

  defp pad(i) when i < 10, do: <<?0, ?0 + i>>
  defp pad(i), do: to_string(i)

  embed_template(:migration, """
  defmodule <%= inspect @mod %> do
    def up do

    end

    def down do

    end
  end
  """)
end
