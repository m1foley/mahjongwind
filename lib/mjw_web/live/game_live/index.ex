defmodule MjwWeb.GameLive.Index do
  use MjwWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> subscribe_to_lobby_updates()
      |> initialize_games_stream()

    {:ok, socket}
  end

  @impl true
  def handle_info({game, :game_created}, socket),
    do: {:noreply, stream_insert(socket, :games, game)}

  @impl true
  def handle_info({game, :game_removed}, socket),
    do: {:noreply, stream_delete(socket, :games, game)}

  @impl true
  def handle_info({game, _event}, socket) do
    if Mjw.Games.Game.empty?(game) do
      {:noreply, stream_delete(socket, :games, game)}
    else
      {:noreply, stream_insert(socket, :games, game)}
    end
  end

  defp subscribe_to_lobby_updates(socket) do
    if connected?(socket), do: MjwWeb.GameStore.subscribe_to_lobby_updates()
    socket
  end

  defp initialize_games_stream(socket) do
    seated_games = MjwWeb.GameStore.all() |> Enum.reject(&Mjw.Games.Game.empty?/1)

    socket
    |> stream(:games, seated_games, dom_id: &"join-#{&1.uuid}")
    |> assign(:has_games, length(seated_games) > 0)
  end
end
