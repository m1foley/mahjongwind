import Config

# Note we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the `mix assets.deploy` task,
# which you should run after static files are built and
# before starting your production server.
config :mjw, MjwWeb.Endpoint,
  url: [host: "mahjongwind.com", port: 443, scheme: "https"],
  cache_static_manifest: "priv/static/cache_manifest.json",
  check_origin: ["//mahjongwind.com"],
  force_ssl: [
    host: nil,
    rewrite_on: [:x_forwarded_port, :x_forwarded_proto],
    hsts: true
  ]

# Configures Swoosh API Client
config :swoosh, api_client: Swoosh.ApiClient.Finch, finch_name: Mjw.Finch

# Disable Swoosh Local Memory Storage
config :swoosh, local: false

# Do not print debug messages in production
config :logger, level: :info
