defmodule MjwWeb.GameLive.Index do
  use MjwWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div class="lobby">
      <img src="/images/cursive.png" alt="Mahjong Wind" class="lobbytitle" />
      <.form for={%{}} action={~p"/games"}>
        <.button type="submit" class="new-game">Start a game</.button>
      </.form>

      <div class="lobbygames">
        <%= unless Enum.empty?(@games) do %>
          <div class="pt-12 pb-10 text-xl font-semibold">or join a game in progress:</div>
          <%= for game <- @games do %>
            <.lobby_game game={game} />
          <% end %>
        <% end %>
      </div>
    </div>

    <div class="footer">
      <span>Email:</span>
      <span class="pl-1">hello&#64;<span class="hidden">REMOVE</span>mahjongwind.com</span>
      <span class="pl-4">Twitter:</span>
      <span class="pl-1"><a href="https://www.twitter.com/m1foley">@m1foley</a></span>
    </div>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    socket =
      socket
      |> assign_defaults(session)
      |> subscribe_to_lobby_updates
      |> fetch_games

    {:ok, socket}
  end

  # Simply reload all data on any type of change we're subscribed to. It would
  # be more elegant to update a particular row when someone joins a game.
  @impl true
  def handle_info({_game, _event}, socket) do
    {:noreply, fetch_games(socket)}
  end

  defp subscribe_to_lobby_updates(socket) do
    if connected?(socket), do: MjwWeb.GameStore.subscribe_to_lobby_updates()
    socket
  end

  defp fetch_games(socket) do
    seated_games = MjwWeb.GameStore.all() |> Enum.reject(&Mjw.Game.empty?/1)

    assign(socket, :games, seated_games)
  end
end
