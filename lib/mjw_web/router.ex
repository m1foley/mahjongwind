defmodule MjwWeb.Router do
  use MjwWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {MjwWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :authentication do
    plug MjwWeb.Plugs.Authentication
  end

  scope "/", MjwWeb do
    pipe_through [:browser, :authentication]

    # game lobby
    live "/", GameLive.Index, :index
    # start new game
    post "/games", GameController, :create
    # game view
    live "/games/:id", GameLive.Show, :show
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: MjwWeb.Telemetry
    end
  end
end
