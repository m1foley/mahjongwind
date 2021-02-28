defmodule MjwWeb.GameLive.WinMenuComponent do
  use MjwWeb, :live_component

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_game_info()

    {:ok, socket}
  end

  defp assign_game_info(socket) do
    current_user_seat = socket.assigns.current_user_seat
    showdeck = socket.assigns[:showdeck]
    confirmed_win = Mjw.Seat.confirmed_win?(current_user_seat)

    socket
    |> assign(:showdeck, showdeck)
    |> assign(:confirmed_win, confirmed_win)
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
