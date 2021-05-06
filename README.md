# Neo4Ecto

Neo4Ecto is an Ecto adapter that sits on top of [Bolt.Sips](https://github.com/florinpatrascu/bolt_sips) driver.

It allows you to deal with a [Neo4j](http://neo4j.com) database through Ecto.

## Installation

Add the lib to your `mix.exs`
```elixir
def deps do
  [
    {:neo4_ecto, "~> 0.1.0"}
  ]
end
```

run: `mix dep.get`

setup your database config:

```elixir
# config/dev.exs

config :my_app, ecto_repos: [MyApp.Repo]

config :my_app, MyApp.Repo,
  hostname: "localhost",
  basic_auth: [username: "neo4j", password: "neo4j"],
  pool_size: 5

# lib/my_app/repo.ex
defmodule MyApp.Repo do
  use Ecto.Repo, otp_app: :my_app, adapter: Neo4Ecto
end
```


## Usage

It's currently available the following Ecto modules: [Schema, Changeset, Repo]

For example:

```elixir
# lib/my_app/accounts/user.ex
defmodule Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user" do
    field :name, :string
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name])
  end
end

# lib/my_app/accounts.ex
defmodule Accounts do
  alias Accounts.User
  alias MyApp.Repo

  def create_user(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end
end
```


## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License
[MIT](https://raw.githubusercontent.com/betrybe/neo4_ecto/main/LICENSE)
