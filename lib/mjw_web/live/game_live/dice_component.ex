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

  @doc """
  Special handler for the very first deal roll, so the wind tiles don't
  disappear too quickly
  """
  @impl true
  def handle_event("roll-first-deal", _params, socket) do
    game_state = socket.assigns.game_state

    socket =
      socket
      |> persist_roll(game_state, :rolled_for_first_deal)

    {:noreply, socket}
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
    |> MjwWeb.GameStore.update(:rolled_for_first_dealer)

    socket
  end

  defp persist_roll(socket, :rolling_for_deal, event) do
    socket.assigns.game
    |> Mjw.Game.roll_dice()
    |> Mjw.Game.deal()
    |> MjwWeb.GameStore.update(event)

    socket
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
