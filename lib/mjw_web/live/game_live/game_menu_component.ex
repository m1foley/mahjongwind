defmodule MjwWeb.GameLive.GameMenuComponent do
  use MjwWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} class="phx-modal relative" phx-target="#game" phx-click="closegamemenu">
      <div class="gamemenu-content">
        <%= if @player_seats_finalized do %>
          <div
            phx-target="#game"
            phx-click="draw"
            class="bg-white hover:bg-gray-100 text-gray-800 font-semibold py-2 px-4 border border-gray-400 rounded shadow cursor-pointer my-4"
          >
            Declare draw 🤝
          </div>

          <div id="dqs" phx-hook="DeclareDq" phx-click="">
            <div
              id="declare-dq-btn"
              class="bg-white hover:bg-gray-100 text-gray-800 font-semibold py-2 px-4 border border-gray-400 rounded shadow cursor-pointer my-4"
            >
              Declare DQ 🙅🏻‍♀️
            </div>

            <div class="dqplayer opacity-30 bg-white text-gray-800 font-semibold py-2 px-4 border border-gray-400 rounded shadow cursor-default my-4 hidden">
              Declare DQ 🙅🏻‍♀️
            </div>

            <%= for seat <- @relative_game_seats |> Enum.drop(1) do %>
              <div
                class="dqplayer bg-red-600 hover:bg-red-500 text-gray-200 font-semibold py-2 px-4 border border-gray-400 rounded shadow cursor-pointer my-4 hidden"
                phx-target="#game"
                phx-click="dq"
                phx-value-seatno={seat.seatno}
              >
                <%= seat.player_name %>
              </div>
            <% end %>
          </div>
        <% end %>

        <%= if length(@relative_game_seats_with_players) > 1 do %>
          <div id="bootplayers" phx-hook="BootPlayer" phx-click="">
            <div
              id="boot-player-btn"
              class="bg-white hover:bg-gray-100 text-gray-800 font-semibold py-2 px-4 border border-gray-400 rounded shadow cursor-pointer my-4"
            >
              Boot player 🥾
            </div>

            <div class="bootplayer opacity-30 bg-white text-gray-800 font-semibold py-2 px-4 border border-gray-400 rounded shadow cursor-default my-4 hidden">
              Boot player 🥾
            </div>

            <%= for seat <- @relative_game_seats_with_players |> Enum.drop(1) do %>
              <div
                class="bootplayer bg-red-600 hover:bg-red-500 text-gray-200 font-semibold py-2 px-4 border border-gray-400 rounded shadow cursor-pointer my-4 hidden"
                phx-target="#game"
                phx-click="bootplayer"
                phx-value-seatno={seat.seatno}
              >
                <%= seat.player_name %>
              </div>
            <% end %>
          </div>
        <% end %>

        <div
          phx-target={@myself}
          class="bg-white hover:bg-gray-100 text-gray-800 font-semibold py-2 px-4 border border-gray-400 rounded shadow cursor-pointer my-4"
          phx-click="quit"
        >
          Leave game
        </div>

        <div
          phx-target="#game"
          phx-click="reset"
          class="bg-white hover:bg-gray-100 text-gray-800 font-semibold py-2 px-4 border border-gray-400 rounded shadow cursor-pointer my-4"
        >
          <div phx-target="#game" phx-click="reset">
            Reset game
          </div>
        </div>

        <div phx-click="">
          <.invite_link id="invite-link-gamemenu" game_id={@game.id} game_state={@game_state} />
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    relative_game_seats_with_players =
      assigns.relative_game_seats |> Enum.reject(&Mjw.Seat.empty?/1)

    socket =
      assign(socket, assigns)
      |> assign(:relative_game_seats_with_players, relative_game_seats_with_players)

    {:ok, socket}
  end

  @impl true
  def handle_event("quit", _params, socket) do
    current_user_seat = socket.assigns.relative_game_seats |> Enum.at(0)

    socket.assigns.game
    |> Mjw.Game.evacuate_seat(current_user_seat.seatno)
    |> MjwWeb.GameStore.update_with_lobby_change(:left_game, %{seat: current_user_seat})

    socket = socket |> push_navigate(to: ~p"/")

    {:noreply, socket}
  end
end
