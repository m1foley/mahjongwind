defmodule MjwWeb.GameLive.WindPickComponent do
  use MjwWeb, :live_component

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("windpick", %{"picked-wind-idx" => picked_wind_idx}, socket) do
    picked_wind_idx = String.to_integer(picked_wind_idx)

    socket =
      socket
      |> persist_wind_choice(picked_wind_idx)

    {:noreply, socket}
  end

  defp persist_wind_choice(socket, picked_wind_idx) do
    current_user_id = socket.assigns.current_user_id

    socket.assigns.game
    |> Mjw.Game.pick_random_available_wind(current_user_id, picked_wind_idx)
    |> MjwWeb.GameStore.update()

    socket
  end
end
