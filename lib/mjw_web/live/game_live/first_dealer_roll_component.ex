defmodule MjwWeb.GameLive.FirstDealerRollComponent do
  use MjwWeb, :live_component
  require Logger

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
    socket =
      socket
      |> persist_roll()

    {:noreply, socket}
  end

  defp persist_roll(socket) do
    socket.assigns.game
    |> Mjw.Game.roll_for_first_dealer()
    # TODO: Reseat the players according to the roll and the picked winds.
    # The new dealer will be in seat 0. After that the main game loop will have
    # begun, and game state is waiting for them to roll for deal.
    |> MjwWeb.GameStore.update()

    socket
  end

  defp assign_game_info(socket) do
    current_user_is_roller = socket.assigns.picked_wind == "🀀"
    roller_name = socket.assigns.picked_winds_player_names["🀀"]
    first_dealer_roll = socket.assigns.game.first_dealer_roll

    socket
    |> assign(:current_user_is_roller, current_user_is_roller)
    |> assign(:roller_name, roller_name)
    |> assign(:first_dealer_roll, first_dealer_roll)
  end
end
