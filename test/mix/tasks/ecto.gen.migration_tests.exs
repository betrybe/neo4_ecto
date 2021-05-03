defmodule Mix.Tasks.Ecto.Gen.MigrationTest do
  use ExUnit.Case

  import Mix.Tasks.Ecto.Gen.Migration, only: [run: 1]

  @migration_path Path.absname("./priv/repo/migrations")

  setup do
    on_exit(fn ->
      File.rm_rf!(@migration_path)
      :ok
    end)
  end

  describe "run/1" do
    test "migration generates default template" do
      file_path = run(["AddUserConstraint"])
      file_content = File.read!(file_path)

      assert file_content =~ "defmodule SkillTree.Repo.Migrations.AddUserConstraint do"
      assert file_content =~ "def up do\n\n  end"
      assert file_content =~ "def down do\n\n  end"
    end

    test "migration generates right path and snake_case file name" do
      file_path = run(["AddSomeRule"])
      file_content = File.read!(file_path)

      assert Path.dirname(file_path) == @migration_path
      assert Path.basename(file_path) =~ ~r/^\d{14}_add_some_rule\.exs/
    end

    test "raises error when migration args are empty" do
      assert_raise Mix.Error, fn -> run([]) end
    end
  end
end
