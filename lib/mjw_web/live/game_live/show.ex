defmodule MjwWeb.GameLive.Show do
  use MjwWeb, :live_view

  @impl true
  def mount(%{"id" => id}, session, socket) do
    socket =
      socket
      |> assign_defaults(session)
      |> fetch_game(id)
      |> ensure_game_exists()

    if socket.assigns.game do
      socket =
        socket
        |> subscribe_to_game_updates()
        |> assign_game_info()
        |> ensure_game_joinable()

      {:ok, socket}
    else
      {:ok, socket}
    end
  end

  @impl true
  def handle_params(_params, _url, socket), do: {:noreply, socket}

  @impl true
  def handle_info({:game_updated, game}, socket) do
    socket =
      socket
      |> assign(:game, game)
      |> assign_game_info()

    {:noreply, socket}
  end

  defp fetch_game(socket, id) do
    game = MjwWeb.GameStore.get(id)
    socket |> assign(:game, game)
  end

  defp ensure_game_exists(socket) do
    if !socket.assigns.game do
      socket
      |> put_flash(:error, "That game ID does not exist.")
      |> push_redirect(to: Routes.game_index_path(socket, :index))
    else
      socket
    end
  end

  defp subscribe_to_game_updates(socket) do
    if connected?(socket) do
      socket.assigns.game
      |> MjwWeb.GameStore.subscribe_to_game_updates()
    end

    socket
  end

  defp assign_game_info(socket) do
    game = socket.assigns.game
    current_user_id = socket.assigns.current_user_id

    empty_seats_count = Mjw.Game.empty_seats_count(game)
    current_user_sitting_at = Mjw.Game.sitting_at(game, current_user_id)
    game_state = Mjw.Game.state(game)
    remaining_winds_to_pick = Mjw.Game.remaining_winds_to_pick(game)
    picked_wind = Mjw.Game.picked_wind(game, current_user_id)
    picked_wind_idx = Mjw.Game.picked_wind_idx(game, current_user_id)

    socket
    |> assign(:empty_seats_count, empty_seats_count)
    |> assign(:current_user_sitting_at, current_user_sitting_at)
    |> assign(:game_state, game_state)
    |> assign(:remaining_winds_to_pick, remaining_winds_to_pick)
    |> assign(:picked_wind, picked_wind)
    |> assign(:picked_wind_idx, picked_wind_idx)
  end

  defp ensure_game_joinable(socket) do
    if socket.assigns.empty_seats_count <= 0 &&
         !socket.assigns.current_user_sitting_at do
      socket
      |> put_flash(:error, "Sorry, that game is full.")
      |> push_redirect(to: Routes.game_index_path(socket, :index))
    else
      socket
    end
  end
end
