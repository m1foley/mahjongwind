defmodule Mjw.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MjwWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:mjw, :dns_cluster_query) || :ignore},
      # Start the PubSub system, used by GameStore for persistence
      {Phoenix.PubSub, name: Mjw.PubSub},
      # Start the Finch HTTP client for sending emails
      # {Finch, name: Mjw.Finch},
      # Service to handle game data persistence
      MjwWeb.GameStore,
      # Service that handles bot moves
      MjwWeb.BotService,

      # Start a worker by calling: Mjw.Worker.start_link(arg)
      # {Mjw.Worker, arg}

      # Start to serve requests, typically the last entry
      MjwWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Mjw.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MjwWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
