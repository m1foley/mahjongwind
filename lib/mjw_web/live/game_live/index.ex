defmodule MjwWeb.GameLive.Index do
  use MjwWeb, :live_view

  @impl true
  def mount(params, session, socket) do
    if params["test"], do: seed_test_game()

    socket =
      socket
      |> assign_defaults(session)
      |> subscribe_to_lobby_updates
      |> fetch_games

    {:ok, socket}
  end

  # Simply reload all data on any type of change we're subscribed to. It would
  # be more elegant to update a particular row when someone joins a game.
  @impl true
  def handle_info({_game, _event}, socket) do
    {:noreply, fetch_games(socket)}
  end

  defp subscribe_to_lobby_updates(socket) do
    if connected?(socket), do: MjwWeb.GameStore.subscribe_to_lobby_updates()
    socket
  end

  defp fetch_games(socket) do
    seated_games =
      MjwWeb.GameStore.all()
      |> Enum.reject(&Mjw.Game.empty?/1)

    assign(socket, :games, seated_games)
  end

  def seed_test_game() do
    test_game = Mjw.Game.new() |> Map.merge(%{id: "test1"})

    unless MjwWeb.GameStore.get("test1") do
      test_game
      |> Map.merge(%{
        seats: [
          %Mjw.Seat{player_id: "snoop", player_name: "Snoop Dogg", picked_wind: "ww"},
          %Mjw.Seat{player_id: "dre", player_name: "Dr. Dre", picked_wind: "wn"},
          %Mjw.Seat{},
          %Mjw.Seat{}
        ]
      })
      |> MjwWeb.GameStore.update(:test_init)
    end
  end
end
