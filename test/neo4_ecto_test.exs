defmodule Ecto.Adapters.Neo4EctoTest do
  use ExUnit.Case

  alias Bolt.Sips
  alias Neo4Ecto.TestRepo, as: Repo
  doctest Ecto.Adapters.Neo4Ecto

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

  setup do
    Application.ensure_started(:bolt_sips)
    conn = Bolt.Sips.conn()

    on_exit(fn ->
      Bolt.Sips.query!(conn, "MATCH (n) DELETE n")
    end)

    {:ok, conn: conn}
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

      assert %{records: []} = Sips.query!(conn, "MATCH (n) WHERE id(n) = #{user.id} RETURN n")
    end
  end

  describe "query/2" do
    test "returns tuple with success" do
      {:ok, %Sips.Response{results: results}} = Repo.query("RETURN 1 as N;")
      assert results == [%{"N" => 1}]
    end

    test "returns tuple with error" do
      {:ok, %Sips.Response{results: results}} = Repo.query("RETURN 1 as N;")
      assert results == [%{"N" => 1}]
    end

    test "executes query with params" do
      {:ok, %Sips.Response{results: results}} = Repo.query("RETURN $number as N;", %{number: 1})
      assert results == [%{"N" => 1}]
    end
  end

  describe "query!/2" do
    test "returns directly response" do
      %Sips.Response{results: results} = Repo.query!("RETURN 1 as N;")
      assert results == [%{"N" => 1}]
    end

    test "raises error on invalid querie" do
      assert_raise Sips.Exception, fn -> Repo.query!("INVALID 1;") end
    end

    test "executes query with params" do
      %Sips.Response{results: results} = Repo.query!("RETURN $number as N;", %{number: 1})
      assert results == [%{"N" => 1}]
    end
  end

  defp retrieve_conn(_opts), do: {:ok, conn: Sips.conn()}

  defp clear_conn(%{conn: conn}) do
    Sips.query!(conn, "MATCH (n) DELETE n")
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
    |> Sips.query!(query)
    |> Sips.Response.first()
    |> Map.get("n")
  end
end
