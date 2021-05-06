defmodule Schema.TestUser do
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
