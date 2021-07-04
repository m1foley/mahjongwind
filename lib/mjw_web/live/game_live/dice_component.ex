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
    current_user_seatno = socket.assigns.current_user_seatno
    event = socket.assigns.event

    {roller_seat, roller_relative_position} =
      Mjw.Game.current_or_most_recent_roller_seat_with_relative_position(
        game,
        game_state,
        current_user_seatno
      )

    previous_roller_relative_position =
      if event == :rolled_for_first_dealer do
        Mjw.Game.picked_east_wind_relative_seatno(game, current_user_seatno)
      else
        roller_relative_position
      end

    roller_name = roller_seat.player_name
    dice = game.dice

    socket
    |> assign(:roller_relative_position, roller_relative_position)
    |> assign(:previous_roller_relative_position, previous_roller_relative_position)
    |> assign(:roller_name, roller_name)
    |> assign(:dice, dice)
  end
end
