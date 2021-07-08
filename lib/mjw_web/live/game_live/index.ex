defmodule MjwWeb.GameLive.Index do
  use MjwWeb, :live_view

  @impl true
  def mount(_params, session, socket) do
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
    seated_games = Enum.reject(MjwWeb.GameStore.all(), &Mjw.Game.empty?/1)
    assign(socket, :games, seated_games)
  end
end
