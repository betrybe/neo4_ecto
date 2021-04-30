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

    @fields ~w(name)a

    def changeset(attrs) do
      %__MODULE__{}
      |> cast(attrs, @fields)
      |> validate_required(@fields)
    end

    def update_changeset(%__MODULE__{} = user, attrs) do
      user
      |> cast(attrs, @fields)
      |> validate_required(@fields)
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

      assert %{labels: ["User"], properties: %{"name" => "John Doe"}} =
        match_response(conn, "MATCH (n) WHERE n.name='John Doe' RETURN n")
    end
  end

  describe "update/1" do
    setup [:retrieve_conn, :clear_conn, :create_user]

    test "updates an existent user", %{conn: conn, user: user} do
      update_attrs = %{name: "Joao Don"}

      assert {:ok, user} =
               user
               |> User.update_changeset(update_attrs)
               |> Repo.update()

      assert %User{name: "Joao Don", id: _id} = user

      assert %{labels: ["User"], properties: %{"name" => "Joao Don"}} =
        match_response(conn, "MATCH (n) WHERE n.name='Joao Don' RETURN n")
    end
  end

  describe "delete/1" do
    setup [:retrieve_conn, :clear_conn, :create_user]

    test "deletes an existent user", %{conn: conn, user: user} do
      assert {:ok, %{__meta__: info}} = Repo.delete(user)
      assert info.state == :deleted

      assert %{records: []} =
               Bolt.Sips.query!(conn, "MATCH (n) WHERE id(n) = #{user.id} RETURN n")
    end
  end

  defp retrieve_conn(_opts), do: {:ok, conn: Bolt.Sips.conn()}

  defp clear_conn(%{conn: conn}) do
    Bolt.Sips.query!(conn, "MATCH (n) DELETE n")
    {:ok, conn: conn}
  end

  defp create_user(%{conn: conn}) do
    {:ok, user} =
      %{name: "John Doe"}
      |> User.changeset()
      |> Repo.insert()

    {:ok, conn: conn, user: user}
  end

  defp match_response(conn, query) do
    conn
    |> Bolt.Sips.query!(query)
    |> Bolt.Sips.Response.first()
    |> Map.get("n")
  end
end
