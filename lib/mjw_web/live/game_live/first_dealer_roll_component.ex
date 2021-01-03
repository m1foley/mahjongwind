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
    |> Mjw.Game.reseat_players()
    |> MjwWeb.GameStore.update()

    socket
  end

  defp assign_game_info(socket) do
    game = socket.assigns.game
    current_user_id = socket.assigns.current_user_id
    picked_winds_player_names = socket.assigns.picked_winds_player_names

    picked_wind = Mjw.Game.picked_wind(game, current_user_id)
    current_user_is_roller = picked_wind == "🀀"
    roller_name = picked_winds_player_names["🀀"]
    first_dealer_roll = game.first_dealer_roll

    socket
    |> assign(:current_user_is_roller, current_user_is_roller)
    |> assign(:roller_name, roller_name)
    |> assign(:first_dealer_roll, first_dealer_roll)
  end
end
