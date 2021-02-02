defmodule MjwWeb.GameLive.TilesComponent do
  use MjwWeb, :live_component

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)

    {:ok, socket}
  end

  @impl true
  def handle_event("sort", %{"list" => [_ | _] = list}, socket) do
    # %{"id" => "n4-2", "list_id" => "concealed-0", "sort_order" => 13}
    sorted_ids = list |> Enum.map(& &1["id"])

    socket =
      socket
      |> assign(:tiles, sorted_ids)

    {:noreply, socket}
  end
end
