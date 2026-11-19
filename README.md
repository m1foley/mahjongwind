# Mahjong Wind

Play mahjong with your friends online!

## Quick setup

- Install dependencies, create DB, run migrations, and build assets: `mix setup`
- Create and migrate the test database: `MIX_ENV=test mix ecto.setup`
- Run tests: `mix test`
- Start server: `mix phx.server`
- Visit <http://localhost:4000>

## Install dependencies and other setup tasks

```sh
mix setup
MIX_ENV=test mix ecto.setup
```

## Run server

```sh
mix phx.server
# with pry
iex -S mix phx.server
```

## Console

```sh
iex -S mix
```

## Connect to remote SQL database

```sh
fly pg connect -a mahjongwind-db -d mahjongwind
```

Format game state:
```sql
SELECT jsonb_pretty(state) FROM games WHERE id = 1;
```
## Run tests

```sh
mix test
# with pry
iex -S mix test <file>
```

## Deployment

The `main` branch is configured to automatically deploy to Fly.io. For details see `.github/workflows/fly.yml`.

To deploy manually:
```sh
flyctl deploy --remote-only
```

## Maintain dependencies

- List outdated packages: `mix hex.outdated`
- Package info: `mix hex.info <package>`
- Find security issues: `mix hex.audit`
  - Should be taken care of by Dependabot
- Update a package: `mix deps.update <package>`

## Credo for static analysis

```sh
mix credo
```
