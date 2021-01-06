defmodule MjwWeb.GameLive.HandComponent do
  use MjwWeb, :live_component

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_game_info()

    {:ok, socket}
  end

  defp assign_game_info(socket) do
    game = socket.assigns.game
    current_user_id = socket.assigns.current_user_id
    turn_seat = socket.assigns.turn_seat
    current_user_seat = game |> Mjw.Game.seat(current_user_id)
    current_user_turn = turn_seat.player_id == current_user_id

    socket
    |> assign(:turn_seat, turn_seat)
    |> assign(:current_user_seat, current_user_seat)
    |> assign(:current_user_turn, current_user_turn)
  end
end
