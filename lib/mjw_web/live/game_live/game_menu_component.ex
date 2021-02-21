defmodule MjwWeb.GameLive.GameMenuComponent do
  use MjwWeb, :live_component

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("quit", _params, socket) do
    player_seat = socket.assigns.relative_game_seats |> Enum.at(0)

    socket.assigns.game
    |> Mjw.Game.evacuate_seat(player_seat.seatno)
    |> MjwWeb.GameStore.update_with_lobby_change(:left_game, %{seat: player_seat})

    socket =
      socket
      |> push_redirect(to: Routes.game_index_path(socket, :index))

    {:noreply, socket}
  end
end
