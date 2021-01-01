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
    |> MjwWeb.GameStore.update()

    socket
  end

  defp assign_game_info(socket) do
    current_user_is_roller = socket.assigns.picked_wind == "🀀"
    roller_name = socket.assigns.picked_winds_player_names["🀀"]

    socket
    |> assign(:current_user_is_roller, current_user_is_roller)
    |> assign(:roller_name, roller_name)
  end
end
