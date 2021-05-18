defmodule MjwWeb.GameLive.GameMenuComponent do
  use MjwWeb, :live_component

  @impl true
  def update(assigns, socket) do
    relative_game_seats_with_players =
      assigns.relative_game_seats |> Enum.reject(&Mjw.Seat.empty?/1)

    socket =
      assign(socket, assigns)
      |> assign(:relative_game_seats_with_players, relative_game_seats_with_players)

    {:ok, socket}
  end

  @impl true
  def handle_event("quit", _params, socket) do
    current_user_seat = socket.assigns.relative_game_seats |> Enum.at(0)

    socket.assigns.game
    |> Mjw.Game.evacuate_seat(current_user_seat.seatno)
    |> MjwWeb.GameStore.update_with_lobby_change(:left_game, %{seat: current_user_seat})

    socket =
      socket
      |> push_redirect(to: Routes.game_index_path(socket, :index))

    {:noreply, socket}
  end
end
