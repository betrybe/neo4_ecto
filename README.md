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

## Copyright and License

The source code is under the Apache 2 License.

Copyright (c) 2021 Trybe

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
