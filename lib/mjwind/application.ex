defmodule Mjwind.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      MjwindWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Mjwind.PubSub},
      # Start the Endpoint (http/https)
      MjwindWeb.Endpoint,
      # Persist game data
      MjwindWeb.GameStore

      # Start a worker by calling: Mjwind.Worker.start_link(arg)
      # {Mjwind.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Mjwind.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    MjwindWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
