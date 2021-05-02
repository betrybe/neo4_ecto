defmodule Neo4EctoTest do
  use ExUnit.Case

  alias Bolt.Sips

  doctest Neo4Ecto

  setup_all do
    {:ok, _pid} = Repo.start_link()

    :ok
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
