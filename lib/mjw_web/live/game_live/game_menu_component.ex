defmodule MjwWeb.GameLive.GameMenuComponent do
  use MjwWeb, :live_component

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("quit", _params, socket) do
    seat = socket.assigns.relative_game_seats |> Enum.at(0)

    socket.assigns.game
    |> Mjw.Game.evacuate_seat(seat.seatno)
    |> MjwWeb.GameStore.update(:left_game, %{seat: seat})

    socket =
      socket
      |> push_redirect(to: Routes.game_index_path(socket, :index))

    {:noreply, socket}
  end

  @impl true
  def handle_event("reset", _params, socket) do
    player_seat = socket.assigns.relative_game_seats |> Enum.at(0)

    socket.assigns.game
    |> Mjw.Game.reset()
    |> MjwWeb.GameStore.update(:reset, %{seat: player_seat})

    {:noreply, socket}
  end
end
