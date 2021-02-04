defmodule MjwWeb.GameLive.WindPickComponent do
  use MjwWeb, :live_component

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_game_info()

    {:ok, socket}
  end

  @impl true
  def handle_event("windpick", %{"picked-wind-idx" => picked_wind_idx}, socket) do
    picked_wind_idx = String.to_integer(picked_wind_idx)

    socket =
      socket
      |> persist_wind_choice(picked_wind_idx)

    {:noreply, socket}
  end

  defp assign_game_info(socket) do
    game = socket.assigns.game
    current_user_id = socket.assigns.current_user_id
    picked_wind = Mjw.Game.picked_wind(game, current_user_id)
    picked_wind_idx = Mjw.Game.picked_wind_idx(game, current_user_id)
    picked_winds_player_names = Mjw.Game.picked_winds_player_names(game)
    all_winds = ~w(we ws ww wn)

    picked_winds =
      Enum.with_index(all_winds)
      |> Enum.map(fn {wind, i} ->
        if picked_wind do
          # we always display the picked tile in the picked_wind_idx, so swap
          # with the tile that's really at that index
          wind =
            if picked_wind_idx == i do
              picked_wind
            else
              if wind == picked_wind do
                Enum.at(all_winds, picked_wind_idx)
              else
                wind
              end
            end

          %{wind: wind, picked_by_name: picked_winds_player_names[wind]}
        else
          %{picked_wind_idx: i}
        end
      end)

    socket
    |> assign(:picked_wind, picked_wind)
    |> assign(:picked_winds, picked_winds)
  end

  defp persist_wind_choice(socket, picked_wind_idx) do
    current_user_id = socket.assigns.current_user_id

    socket.assigns.game
    |> Mjw.Game.pick_random_available_wind(current_user_id, picked_wind_idx)
    |> MjwWeb.GameStore.update()

    socket
  end
end
