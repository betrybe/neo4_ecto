defmodule Mix.Tasks.Ecto.Gen.Migration do
  use Mix.Task

  import Macro, only: [camelize: 1, underscore: 1]
  import Mix.Generator

  @switches [
    change: :string,
    repo: [:string, :keep],
    no_compile: :boolean,
    no_deps_check: :boolean,
    migrations_path: :string
  ]

  def run(args) do
    case OptionParser.parse!(args, strict: @switches) do
      {_opts, [name]} ->
        migration_file = "#{timestamp()}_#{underscore(name)}.exs"
        file = create_repo_migrations_path(migration_file)

        assigns = [mod: Module.concat([SkillTree.Repo.Migrations, camelize(name)])]
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
