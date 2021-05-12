defmodule Neo4Ecto.MigratorTest do
  use ExUnit.Case, async: false

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

  defp schema_migrations() do
    {:ok, migrations} = Neo4Ecto.execute("MATCH (sm:SCHEMA_MIGRATION) RETURN sm")
    migrations
  end

  defp clean_up do
    if File.exists?("priv") do
      Migrator.run(:down)
      Neo4Ecto.execute("MATCH (sm:SCHEMA_MIGRATION) DELETE sm")
    end
  end

  describe "run/:up" do
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

      log = capture_log(&Migrator.run/0)
      Migrator.run()

      assert log =~ "Running 1 Ecto.MigrationTest.S1_test_migration.up"
      assert log =~ "Migrated 1 in"
      assert length(schema_migrations()) == 1
    end

    test "execute multiple migration files" do
      in_tmp(fn _path ->
        create_migration("1_test_first_migration.exs", "Teste1")
        create_migration("2_test_second_migration.exs", "Teste2")
        create_migration("3_test_third_migration.exs", "Teste3")
      end)

      log = capture_log(&Migrator.run/0)

      assert length(schema_migrations()) == 3
      assert log =~ "Running 1 Ecto.MigrationTest.S1_test_first_migration.up"
      assert log =~ "Migrated 1 in"
      assert log =~ "Running 2 Ecto.MigrationTest.S2_test_second_migration.up"
      assert log =~ "Migrated 2 in"
      assert log =~ "Running 3 Ecto.MigrationTest.S3_test_third_migration.up"
      assert log =~ "Migrated 3 in"
    end

    test "execute only versions yet to be migrated" do
      in_tmp(fn _path ->
        create_migration("4_test_fourth_migration.exs", "Teste4")
      end)

      Migrator.run()

      in_tmp(fn _path ->
        create_migration("4_test_fourth_migration.exs", "Teste4")
        create_migration("5_test_fifth_migration.exs", "Teste5")
        create_migration("6_test_sixth_migration.exs", "Teste6")
      end)

      log = capture_log(&Migrator.run/0)

      assert length(schema_migrations()) == 3
      refute log =~ "Running 4 Ecto.MigrationTest.S4_test_fourth_migration.up"
      refute log =~ "Migrated 4 in"
      assert log =~ "Running 5 Ecto.MigrationTest.S5_test_fifth_migration.up"
      assert log =~ "Migrated 5 in"
      assert log =~ "Running 6 Ecto.MigrationTest.S6_test_sixth_migration.up"
      assert log =~ "Migrated 6 in"
    end

    test "does not execute any previously migrated versions and logs database is already up" do
      in_tmp(fn _path ->
        create_migration("7_test_seventh_migration.exs", "Teste7")
        create_migration("8_test_eighth_migration.exs", "Teste8")
      end)

      Migrator.run()

      assert length(schema_migrations()) == 2

      log = capture_log(&Migrator.run/0)

      assert length(schema_migrations()) == 2
      refute log =~ "Running 7 Ecto.MigrationTest.S7_test_seventh_migration.up"
      refute log =~ "Migrated 7 in"
      refute log =~ "Running 8 Ecto.MigrationTest.S8_test_eighth_migration.up"
      refute log =~ "Migrated 8 in"
      assert log =~ "Migrations already up"
    end

    test "shows log of Migration already up if all migrations was previously run" do
      in_tmp(fn _path ->
        create_migration("9_test_ninth_migration.exs", "Teste9")
        create_migration("10_test_tenth_migration.exs", "Teste10")
      end)

      Migrator.run()

      assert length(schema_migrations()) == 2

      log = capture_log(&Migrator.run/0)

      assert length(schema_migrations()) == 2
      refute log =~ "Running 9 Ecto.MigrationTest.S9_test_ninth_migration.up"
      refute log =~ "Running 10 Ecto.MigrationTest.S10_test_tenth_migration.up"
      refute log =~ "Migrations finished"
      assert log =~ "Migrations already up"
    end

    test "does not show 'Migration already up' if any migration is executed and logs 'Migrations finshed'" do
      in_tmp(fn _path ->
        create_migration("11_test_eleventh_migration.exs", "Teste11")
        create_migration("12_test_twelfth_migration.exs", "Teste12")
      end)

      Migrator.run()
      assert length(schema_migrations()) == 2

      in_tmp(fn _path ->
        create_migration("11_test_eleventh_migration.exs", "Teste11")
        create_migration("12_test_twelfth_migration.exs", "Teste12")
        create_migration("13_test_thirteenth_migration.exs", "Teste3")
      end)

      log = capture_log(&Migrator.run/0)

      assert length(schema_migrations()) == 3
      refute log =~ "Running 11 Ecto.MigrationTest.S11_test_eleventh_migration.up"
      refute log =~ "Running 12 Ecto.MigrationTest.S12_test_twelfth_migration.up"
      refute log =~ "Migrations already up"

      assert log =~ "Running 13 Ecto.MigrationTest.S13_test_thirteenth_migration.up"
      assert log =~ "Migrations finished"
    end
  end

  describe "run/:down" do
    setup do
      on_exit(fn ->
        File.rm_rf!("./priv")
        :ok
      end)
    end

    test "deletes migrations and schema version when runs 'down'" do
      in_tmp(fn _path ->
        create_migration("14_test_fourteenth_migration.exs", "Teste14")
        create_migration("15_test_fifteenth_migration.exs", "Teste15")
      end)

      Migrator.run()
      assert length(schema_migrations()) == 2

      log = capture_log(fn -> Migrator.run(:down) end)

      refute log =~ "Running 14 Ecto.MigrationTest.S14_test_fourteenth_migration.up"
      refute log =~ "Running 15 Ecto.MigrationTest.S15_test_fifteenth_migration.up"

      assert log =~ "Running 14 Ecto.MigrationTest.S14_test_fourteenth_migration.down"
      assert log =~ "Running 15 Ecto.MigrationTest.S15_test_fifteenth_migration.down"
      assert log =~ "Migrations finished"
      assert length(schema_migrations()) == 0
    end
  end
end
