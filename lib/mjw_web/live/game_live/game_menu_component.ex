defmodule MjwWeb.GameLive.GameMenuComponent do
  use MjwWeb, :live_component

  alias Mjw.Games.{Game, Seat}

  @impl true
  def update(assigns, socket) do
    relative_game_seats_with_players =
      assigns.relative_game_seats |> Enum.reject(&Seat.empty?/1)

    socket =
      assign(socket, assigns)
      |> assign(:relative_game_seats_with_players, relative_game_seats_with_players)

    {:ok, socket}
  end

  @impl true
  def handle_event("quit", _params, socket) do
    current_user_seat = socket.assigns.relative_game_seats |> Enum.at(0)

    game =
      socket.assigns.game
      |> Game.evacuate_seat(current_user_seat.seatno)

    if Game.has_human_players?(game) do
      MjwWeb.GameStore.update_with_lobby_change(game, :left_game, %{seat: current_user_seat})
    else
      MjwWeb.GameStore.remove(game)
    end

    socket = socket |> push_navigate(to: ~p"/")

    {:noreply, socket}
  end
end
