defmodule MjwWeb.GameLive.WinMenuComponent do
  use MjwWeb, :live_component

  @impl true
  def update(assigns, socket) do
    socket =
      assign(socket, assigns)
      |> assign(:showdeck, socket.assigns[:showdeck])

    {:ok, socket}
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
