defmodule MjwWeb.GameLive.WinMenuComponent do
  use MjwWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id}>
      <div id="winmenu-inner" phx-hook="Simpledrag">
        <%= if Mjw.Seat.confirmed_win?(@current_user_seat) do %>
          <div class="opacity-30 bg-white text-gray-800 font-semibold py-1 px-8 border border-gray-400 rounded shadow cursor-default my-4">
            Waiting for everyone to shuffle... 👋
          </div>
        <% else %>
          <div
            class="bg-white hover:bg-gray-100 text-gray-800 font-semibold py-1 px-8 border border-gray-400 rounded shadow cursor-pointer my-4"
            phx-target="#game"
            phx-click="confirm_win"
          >
            Okay, let's start shuffling... 👋
          </div>
        <% end %>

        <%= if Mjw.Seat.win_expose?(@current_user_seat) do %>
          <div class="bg-white text-gray-800 font-semibold py-1 px-8 border border-gray-400 rounded shadow my-4 cursor-default opacity-30">
            Expose hand
          </div>
        <% else %>
          <div
            class="bg-white text-gray-800 font-semibold py-1 px-8 border border-gray-400 rounded shadow my-4 cursor-pointer hover:bg-gray-100"
            phx-target="#game"
            phx-click="expose"
          >
            Expose hand
          </div>
        <% end %>

        <%= if @showdeck do %>
          <div
            class="bg-white hover:bg-gray-100 text-gray-800 font-semibold py-1 px-8 border border-gray-400 rounded shadow cursor-pointer my-4"
            phx-target={@myself}
            phx-click="hidedeck"
          >
            Hide remaining deck
          </div>

          <div class="flex flex-row flex-wrap text-left justify-start justify-items-start">
            <span class="pr-1 cursor-default" title="Next tile in the deck">&#8594;</span>
            <%= for tile <- @game.deck do %>
              <.tile id={tile} tile={tile} />
            <% end %>
          </div>
        <% else %>
          <div
            class="bg-white hover:bg-gray-100 text-gray-800 font-semibold py-1 px-8 border border-gray-400 rounded shadow cursor-pointer my-4"
            phx-target={@myself}
            phx-click="showdeck"
          >
            View remaining deck
          </div>
        <% end %>

        <%= unless Mjw.Seat.declared_win?(@current_user_seat) do %>
          <div
            class="bg-white hover:bg-gray-100 text-gray-800 font-semibold py-1 px-8 border border-gray-400 rounded shadow cursor-pointer my-4"
            phx-target="#game"
            phx-click="dqdeclared"
          >
            Declare DQ 🙅🏻‍♀️
          </div>
        <% end %>
      </div>
    </div>
    """
  end

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
