defmodule Neo4EctoTest do
  use ExUnit.Case
  doctest Neo4Ecto

  defmodule Repo do
    use Ecto.Repo, otp_app: :neo4_ecto, adapter: Neo4Ecto
  end

  setup do
    repo = Repo.start_link()

    on_exit(fn ->
      repo
      |> elem(1)
      |> Process.exit(:kill)
    end)

    %{repo: repo}
  end

  describe "adapter link" do
    test "starts as smoothly as a bowed violin", %{repo: repo} do
      assert {:ok, _} = repo
    end

    test "fails when duplicated", %{repo: repo} do
      assert {:ok, _} = repo
      assert {:error, {:already_started, _}} = Repo.start_link()
    end
  end
end
