defmodule MjwWeb.GameLive.OpponentSeatComponent do
  use MjwWeb, :live_component

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)

    {:ok, socket}
  end
end
