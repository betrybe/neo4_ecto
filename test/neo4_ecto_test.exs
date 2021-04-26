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

  setup_all do
    repo = Repo.start_link()

    on_exit(fn ->
      repo
      |> elem(1)
      |> Process.exit(:kill)
    end)

    :ok
  end

  describe "adapter link" do
    test "starts as smoothly as a bowed violin" do
      assert _pid = Repo.checkout(fn -> :all_good end)
    end

    test "fails when duplicated" do
      assert {:error, {:already_started, _}} = Repo.start_link()
    end
  end

  describe "insert/1" do
    setup [:retrieve_conn, :clear_conn]

    test "fails with changeset error when invalid name" do
      assert {:error, %Ecto.Changeset{errors: errors}} =
               %{}
               |> User.changeset()
               |> Repo.insert()

      assert [name: {"can't be blank", _}] = errors
    end

    test "creates a new user", %{conn: conn} do
      assert {:ok, _} =
               %{name: "John Doe"}
               |> User.changeset()
               |> Repo.insert()

      assert %{records: [[node]]} =
               Bolt.Sips.query!(conn, "MATCH (n) WHERE n.name='John Doe' RETURN n")

      assert %{labels: ["User"], properties: %{"name" => "John Doe"}} = node
    end
  end

  defp retrieve_conn(_opts), do: {:ok, conn: Bolt.Sips.conn()}

  defp clear_conn(%{conn: conn}) do
    Bolt.Sips.query!(conn, "MATCH (n) DELETE n")
    {:ok, conn: conn}
  end
end
