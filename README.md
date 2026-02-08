# Mahjong Wind

Play mahjong with your friends online!

## Quick setup

- Install dependencies: `mix setup`
- Run tests: `mix test`
- Start server: `mix phx.server`
- Visit <http://localhost:4000>

## Install dependencies and other setup tasks

```sh
mix setup
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

## Credo for static analysis

```sh
mix credo
```
