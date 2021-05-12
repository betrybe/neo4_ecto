defmodule Neo4Ecto.MigratorTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  import Support.FileHelpers

  alias Neo4Ecto.Migrator

  defp create_migration(name, repo_name) do
    module = name |> Path.basename() |> Path.rootname()

    File.write!(name, """
    defmodule Ecto.MigrationTest.S#{module} do
      def up do
        "CREATE CONSTRAINT unique_#{module}_id ON (test:#{repo_name}) ASSERT test.id IS UNIQUE"
      end
      def down do
        "DROP CONSTRAINT unique_#{module}_id"
      end
    end
    """)
  end

  defp clean_up, do: Migrator.run(:down)

  describe "run" do
    setup do
      on_exit(fn ->
        clean_up()
        File.rm_rf!("./priv")
        :ok
      end)
    end

    test "execute single migration file" do
      in_tmp(fn _path ->
        create_migration("1_test_migration.exs", "Teste")
      end)

      log = capture_log(fn ->
        Migrator.run()
      end)

      assert log =~ "Running 1 Ecto.MigrationTest.S1_test_migration.up"
      assert log =~ "Migrated 1 in"
    end

    test "execute multiple migration files" do
      in_tmp(fn _path ->
        create_migration("1_test_first_migration.exs", "Teste1")
        create_migration("2_test_second_migration.exs", "Teste2")
        create_migration("3_test_third_migration.exs", "Teste3")
      end)

      log = capture_log(&Migrator.run/0)

      assert log =~ "Running 1 Ecto.MigrationTest.S1_test_first_migration.up"
      assert log =~ "Migrated 1 in"
      assert log =~ "Running 2 Ecto.MigrationTest.S2_test_second_migration.up"
      assert log =~ "Migrated 2 in"
      assert log =~ "Running 3 Ecto.MigrationTest.S3_test_third_migration.up"
      assert log =~ "Migrated 3 in"
    end

    test "execute only versions yet to be migrated" do
      in_tmp(fn _path ->
        create_migration("1_test_first_migration.exs", "Teste1")
      end)
      Migrator.run()

      in_tmp(fn _path ->
        create_migration("1_test_first_migration.exs", "Teste1")
        create_migration("2_test_second_migration.exs", "Teste2")
        create_migration("3_test_third_migration.exs", "Teste3")
      end)

      log = capture_log(&Migrator.run/0)

      refute log =~ "Running 1 Ecto.MigrationTest.S1_test_first_migration.up"
      refute log =~ "Migrated 1 in"
      assert log =~ "Running 2 Ecto.MigrationTest.S2_test_second_migration.up"
      assert log =~ "Migrated 2 in"
      assert log =~ "Running 3 Ecto.MigrationTest.S3_test_third_migration.up"
      assert log =~ "Migrated 3 in"
    end

    test "does not execute any previously migrated versions and logs database is already up" do
      in_tmp(fn _path ->
        create_migration("1_test_first_migration.exs", "Teste1")
        create_migration("2_test_second_migration.exs", "Teste2")
      end)

      Migrator.run()
      log = capture_log(&Migrator.run/0)

      refute log =~ "Running 1 Ecto.MigrationTest.S1_test_first_migration.up"
      refute log =~ "Migrated 1 in"
      refute log =~ "Running 2 Ecto.MigrationTest.S2_test_second_migration.up"
      refute log =~ "Migrated 2 in"
      assert log =~ "Migrations already up"
    end
  end
end
