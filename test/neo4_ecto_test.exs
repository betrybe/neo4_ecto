defmodule Neo4EctoTest do
  use ExUnit.Case
  doctest Neo4Ecto

  defmodule Repo do
    use Ecto.Repo, otp_app: :neo4_ecto, adapter: Neo4Ecto
  end

  describe "adapter link" do
    test "starts as smoothly as a bowed violin" do
      assert {:ok, _} = Repo.start_link()
    end

    test "fails when duplicated" do
      assert {:ok, _} = Repo.start_link()
      assert {:error, {:already_started, _}} = Repo.start_link()
    end
  end
end
