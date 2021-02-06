defmodule MjwWeb.GameLive.SeatOfferingComponent do
  use MjwWeb, :live_component

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("save", %{"seat_offering" => %{"player_name" => player_name}}, socket) do
    socket =
      socket
      |> seat_current_user(player_name)

    {:noreply, socket}
  end

  defp seat_current_user(socket, player_name) do
    player_id = socket.assigns.current_user_id

    socket.assigns.game
    |> Mjw.Game.seat_player(player_id, player_name)
    |> MjwWeb.GameStore.update_with_lobby_change(:player_seated)

    socket
  end
end
