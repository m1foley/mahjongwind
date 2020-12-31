defmodule MjwWeb.GameLive.SeatOfferingComponent do
  use MjwWeb, :live_component

  @impl true
  def update(%{game: game} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(:return_to, Routes.game_show_path(socket, :show, game.id))

    {:ok, socket}
  end

  @impl true
  def handle_event("save", %{"seat_offering" => %{"player_name" => player_name}}, socket) do
    socket =
      socket
      |> seat_current_user(player_name)
      |> push_redirect(to: socket.assigns.return_to)

    {:noreply, socket}
  end

  defp seat_current_user(socket, player_name) do
    player_id = socket.assigns.current_user_id

    socket.assigns.game
    |> Mjw.Game.seat_player(player_id, player_name)
    |> MjwWeb.GameStore.update()

    socket
  end
end
