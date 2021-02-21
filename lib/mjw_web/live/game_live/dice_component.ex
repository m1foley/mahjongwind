defmodule MjwWeb.GameLive.DiceComponent do
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
    game_state = socket.assigns.game_state
    current_user_sitting_at = socket.assigns.current_user_sitting_at

    {roller_seat, roller_relative_position} =
      Mjw.Game.roller_seat_with_relative_position(game, game_state, current_user_sitting_at)

    roller_name = roller_seat.player_name
    dice = game.dice

    socket
    |> assign(:roller_relative_position, roller_relative_position)
    |> assign(:roller_name, roller_name)
    |> assign(:dice, dice)
  end
end
