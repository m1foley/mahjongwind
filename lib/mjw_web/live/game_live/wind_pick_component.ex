defmodule MjwWeb.GameLive.WindPickComponent do
  use MjwWeb, :live_component
  require Logger

  @impl true
  def update(%{game: game} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(:return_to, Routes.game_show_path(socket, :show, game.id))

    {:ok, socket}
  end

  @impl true
  def handle_event("windpick", %{"windno" => windno}, socket) do
    socket =
      socket
      |> persist_wind_choice()
      |> push_redirect(to: socket.assigns.return_to)

    {:noreply, socket}
  end

  defp persist_wind_choice(socket) do
    sitting_at = socket.assigns.current_user_sitting_at

    socket.assigns.game
    |> Mjw.Game.pick_random_available_wind(sitting_at)
    |> MjwWeb.GameStore.update()

    socket
  end
end
