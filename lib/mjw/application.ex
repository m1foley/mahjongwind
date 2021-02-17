defmodule Mjw.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      MjwWeb.Telemetry,
      # Start the PubSub system, used by GameStore for persistence
      {Phoenix.PubSub, name: Mjw.PubSub},
      # Start the Endpoint (http/https)
      MjwWeb.Endpoint,
      # Service to handle game data persistence
      MjwWeb.GameStore

      # Start a worker by calling: Mjw.Worker.start_link(arg)
      # {Mjw.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Mjw.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    MjwWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
