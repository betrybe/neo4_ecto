
setup-elixir:
    ARG ELIXIR_BASE=1.12.0-rc.1-erlang-24.0-alpine-3.13.3
    FROM hexpm/elixir:$ELIXIR_BASE
    RUN apk add --no-progress --update git build-base
    ENV ELIXIR_ASSERT_TIMEOUT=10000
    RUN apk add --no-progress --update docker docker-compose
 

setup-base:
    FROM +setup-elixir
    COPY mix.exs .
    COPY mix.lock .
    COPY .formatter.exs .
    RUN mix local.rebar --force
    RUN mix local.hex --force
    RUN mix deps.get

setup-code-check:
    FROM +setup-base
    RUN mix compile --warnings-as-errors
    RUN mix format --check-formatted

test-setup:
    FROM +setup-base
    COPY --dir lib test ./
    RUN MIX_ENV=test mix deps.compile
    RUN mix deps.get --only test
    RUN mix deps.compile


test-neo4ecto:
    FROM +test-setup
    ARG NEO4J="neo4j/neo4j-arm64-experimental:4.2.5-arm64"
    WITH DOCKER \
        --pull "$NEO4J"
         RUN docker run --name neo4j --network=host -d -p 7687:7687 --env NEO4J_AUTH=none "$NEO4J"; \
        while ! docker exec neo4j bash -c "cypher-shell -u neo4j -p test 'RETURN 1'"; do \
            echo "waiting for neo4j"; \
            sleep 1; \
        done; \
        mix test --trace --raise;
    END
