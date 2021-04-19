defmodule Neo4EctoTest do
  use ExUnit.Case

  doctest Neo4Ecto

  defmodule Repo do
    use Ecto.Repo, otp_app: :neo4_ecto, adapter: Neo4Ecto
  end

  defmodule User do
    use Ecto.Schema

    import Ecto.Changeset

    schema "user" do
      field(:name, :string)
    end

    def changeset(attrs) do
      %__MODULE__{}
      |> cast(attrs, [:name])
      |> validate_required([:name])
    end
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

  describe "insert/1" do
    test "fails with changeset error when invalid name" do
      assert {:error, %Ecto.Changeset{errors: errors}} =
               %{}
               |> User.changeset()
               |> Repo.insert()

      assert [name: {"can't be blank", _}] = errors
    end

    test "creates a new user" do
      assert {:ok, _} =
               %{name: "John Doe"}
               |> User.changeset()
               |> Repo.insert()
    end
  end
end
