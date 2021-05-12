defmodule Neo4Ecto.StorageTest do
  use ExUnit.Case

  alias Neo4Ecto.Storage

  def params do
    [database: :neo4jtest]
  end

  describe "storage_up/1" do
    test "creates database" do
      assert Storage.storage_up(params()) == :ok
    after
      Storage.storage_down(params())
    end

    test "returns error if database already up " do
      Storage.storage_up(params())
      assert Storage.storage_up(params()) == {:error, :already_up}
    after
      Storage.storage_down(params())
    end

    test "raise error if :database key missing" do
      assert_raise KeyError, fn -> Storage.storage_up(notDatabase: :toot) end
    end
  end

  describe "storage_down/1" do
    test "drops database" do
      Storage.storage_up(params())
      assert Storage.storage_down(params()) == :ok
    end

    test "return error if database already down" do
      assert Storage.storage_down(params()) == {:error, :already_down}
    end
  end

  describe "storage_status/1" do
    test "return up if database is created" do
      Storage.storage_up(params())
      assert Storage.storage_status(params()) == :up
    after
      Storage.storage_down(params())
    end

    test "sreturn down when database is not created" do
      Storage.storage_up(params())
      Storage.storage_down(params())
      assert Storage.storage_status(params()) == :down
    end
  end
end
