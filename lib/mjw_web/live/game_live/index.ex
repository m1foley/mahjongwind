defmodule MjwWeb.GameLive.Index do
  use MjwWeb, :live_view

  @impl true
  def mount(_params, session, socket) do
    # seed with test game
    test_game = Mjw.Game.new() |> Map.merge(%{id: "test1"})

    if !MjwWeb.GameStore.get("test1") do
      test_game
      |> Mjw.Game.seat_player("id0", "name0")
      |> Mjw.Game.seat_player("id1", "name1")
      |> Mjw.Game.pick_random_available_wind("id0", 0)
      |> Mjw.Game.pick_random_available_wind("id1", 0)
      |> MjwWeb.GameStore.update()
    end

    socket =
      socket
      |> assign_defaults(session)
      |> subscribe_to_lobby_updates
      |> fetch_games
      |> subscribe_to_all_seating_updates

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

  @impl true
  def handle_info({:seating_updated, _game}, socket) do
    # brute force for now
    {:noreply, fetch_games(socket)}
  end

  defp subscribe_to_lobby_updates(socket) do
    if connected?(socket), do: MjwWeb.GameStore.subscribe_to_lobby_updates()
    socket
  end

  defp subscribe_to_all_seating_updates(socket) do
    if connected?(socket) do
      socket.assigns.games
      |> Enum.each(&MjwWeb.GameStore.subscribe_to_seating_updates/1)
    end

    socket
  end

  defp fetch_games(socket) do
    seated_games =
      MjwWeb.GameStore.all()
      |> Enum.reject(&Mjw.Game.empty?/1)

    assign(socket, :games, seated_games)
  end
end
