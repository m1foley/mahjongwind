defmodule MjwWeb.GameLive.LoserHandComponent do
  use MjwWeb, :live_component

  @impl true
  def update(assigns, socket) do
    socket =
      assign(socket, assigns)
      |> assign(:showdeck, socket.assigns[:showdeck])

    {:ok, socket}
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

  @impl true
  def handle_event("expose", _params, socket) do
    seatno = socket.assigns.player_seat.seatno

    socket.assigns.game
    |> Mjw.Game.update_winreaction(seatno, :expose)
    |> MjwWeb.GameStore.update(:winreaction_expose)

    {:noreply, socket}
  end

  @impl true
  def handle_event("showdeck", _params, socket) do
    socket = socket |> assign(:showdeck, true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("hidedeck", _params, socket) do
    socket = socket |> assign(:showdeck, false)

    {:noreply, socket}
  end
end
