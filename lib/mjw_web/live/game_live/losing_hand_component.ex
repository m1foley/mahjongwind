defmodule MjwWeb.GameLive.LosingHandComponent do
  use MjwWeb, :live_component

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("dq", _params, socket) do
    seatno = socket.assigns.win_declared_seatno
    seat = socket.assigns.game.seats |> Enum.at(seatno)

    socket.assigns.game
    |> Mjw.Game.dq(seatno)
    |> MjwWeb.GameStore.update(:dq, %{seat: seat})

    {:noreply, socket}
  end
end
