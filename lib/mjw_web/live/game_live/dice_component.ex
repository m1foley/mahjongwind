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

  @impl true
  def handle_event("roll", _params, socket) do
    game_state = socket.assigns.game_state

    socket =
      socket
      |> persist_roll(game_state)

    {:noreply, socket}
  end

  defp persist_roll(socket, :rolling_for_first_dealer) do
    socket.assigns.game
    |> Mjw.Game.roll_dice()
    |> Mjw.Game.reseat_players()
    |> MjwWeb.GameStore.update()

    socket
  end

  defp persist_roll(socket, :rolling_for_deal) do
    socket.assigns.game
    |> Mjw.Game.roll_dice()
    |> Mjw.Game.deal()
    |> MjwWeb.GameStore.update()

    socket
  end

  defp assign_game_info(socket) do
    game = socket.assigns.game
    current_user_id = socket.assigns.current_user_id
    game_state = socket.assigns.game_state

    roller_seat =
      if game_state == :rolling_for_first_dealer do
        game |> Mjw.Game.find_picked_wind_seat("we")
      else
        socket.assigns.turn_seat
      end

    current_user_is_roller = roller_seat.player_id == current_user_id
    roller_name = roller_seat.player_name
    dice = game.dice

    socket
    |> assign(:current_user_is_roller, current_user_is_roller)
    |> assign(:roller_name, roller_name)
    |> assign(:dice, dice)
  end
end
