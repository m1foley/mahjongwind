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

  @impl true
  def handle_info({:game_created, _game}, socket) do
    {:noreply, fetch_games(socket)}
  end

  @impl true
  def handle_info({:game_removed, _game}, socket) do
    {:noreply, fetch_games(socket)}
  end

  defp subscribe_to_lobby_updates(socket) do
    if connected?(socket), do: MjwWeb.GameStore.subscribe_to_lobby_updates()
    socket
  end

  defp fetch_games(socket) do
    assign(socket, :games, MjwWeb.GameStore.all())
  end
end
