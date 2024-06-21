# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Configures the endpoint
config :mjw, MjwWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "NGNyFN6CX0NHhfTvUdX55LusARQu+s+aao+g3XeKcbZkvat3Cf2tWwGGg+KciUjS",
  render_errors: [view: MjwWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Mjw.PubSub,
  live_view: [signing_salt: "TMykxRdF"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
