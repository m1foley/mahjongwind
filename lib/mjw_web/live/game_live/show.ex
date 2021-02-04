defmodule MjwWeb.GameLive.Show do
  use MjwWeb, :live_view

  @impl true
  def mount(%{"id" => id}, session, socket) do
    socket =
      socket
      |> assign_defaults(session)
      |> fetch_game(id)
      |> ensure_game_exists()

    if socket.assigns.game do
      socket =
        socket
        |> assign_event(:initial)
        |> assign_game_info()
        |> ensure_game_joinable()
        |> subscribe_to_game_updates()

      {:ok, socket}
    else
      {:ok, socket}
    end
  end

  @impl true
  def handle_params(_params, _url, socket), do: {:noreply, socket}

  @impl true
  def handle_info({event, %Mjw.Game{} = game}, socket) do
    socket =
      socket
      |> assign(:game, game)
      |> assign_event(event)
      |> assign_game_info()

    {:noreply, socket}
  end

  # sorting one's own concealed tiles
  @impl true
  def handle_event(
        "dropped",
        %{
          "draggedFromId" => "concealed-0",
          "draggedToId" => "concealed-0",
          "draggedToList" => new_concealed
        },
        socket
      ) do
    current_user_sitting_at = socket.assigns.current_user_sitting_at

    socket.assigns.game
    |> Mjw.Game.update_concealed(current_user_sitting_at, new_concealed)
    |> MjwWeb.GameStore.update(:concealed_sorted)

    {:noreply, socket}
  end

  # discarding a tile
  @impl true
  def handle_event(
        "dropped",
        %{
          "draggedFromId" => "concealed-0",
          "draggedToId" => "discards",
          "draggedId" => discarded_tile
        },
        socket
      ) do
    socket.assigns.game
    |> Mjw.Game.discard(discarded_tile)
    |> MjwWeb.GameStore.update(:discarded_tile)

    {:noreply, socket}
  end

  # grabbing a discard
  @impl true
  def handle_event(
        "dropped",
        %{
          "draggedFromId" => "discards",
          "draggedToId" => "concealed-0",
          "draggedId" => _tile
        },
        socket
      ) do
    socket = socket |> put_flash(:error, "Grabbing a discard unimplemented.")

    {:noreply, socket}
  end

  defp fetch_game(socket, id) do
    game = MjwWeb.GameStore.get(id)
    socket |> assign(:game, game)
  end

  defp ensure_game_exists(socket) do
    if !socket.assigns.game do
      socket
      |> put_flash(:error, "That game ID does not exist.")
      |> push_redirect(to: Routes.game_index_path(socket, :index))
    else
      socket
    end
  end

  defp subscribe_to_game_updates(socket) do
    if connected?(socket) && game_joinable?(socket) do
      socket.assigns.game
      |> MjwWeb.GameStore.subscribe_to_game_updates()
    end

    socket
  end

  defp assign_game_info(socket) do
    game = socket.assigns.game
    current_user_id = socket.assigns.current_user_id

    empty_seats_count = Mjw.Game.empty_seats_count(game)
    current_user_sitting_at = Mjw.Game.sitting_at(game, current_user_id)
    game_state = Mjw.Game.state(game)
    turn_seat = Mjw.Game.turn_seat(game)
    picked_winds_player_names = Mjw.Game.picked_winds_player_names(game)

    # seats ordered by their position to the current player (0 = self, etc.)
    relative_game_seats =
      if empty_seats_count > 0 || !current_user_sitting_at do
        []
      else
        0..3
        |> Enum.map(fn i ->
          Mjw.Game.seat_with_relative_position(game, i, current_user_sitting_at)
        end)
        |> Enum.sort_by(fn {_seat, relative_position} -> relative_position end)
        |> Enum.map(fn {seat, _relative_position} -> seat end)
      end

    show_stick =
      [:waiting_for_players, :picking_winds]
      |> Enum.member?(game_state)

    show_wind_picking =
      [:picking_winds, :rolling_for_first_dealer, :rolling_for_deal, :discarding]
      |> Enum.member?(game_state) &&
        game.wind == "we" && game.discards == []

    show_wall =
      [:waiting_for_players, :picking_winds, :rolling_for_first_dealer, :rolling_for_deal]
      |> Enum.member?(game_state)

    show_dice =
      [:rolling_for_first_dealer, :rolling_for_deal, :discarding]
      |> Enum.member?(game_state)

    show_player_names =
      !([:waiting_for_players, :picking_winds, :rolling_for_first_dealer]
        |> Enum.member?(game_state))

    socket
    |> assign(:empty_seats_count, empty_seats_count)
    |> assign(:current_user_sitting_at, current_user_sitting_at)
    |> assign(:game_state, game_state)
    |> assign(:turn_seat, turn_seat)
    |> assign(:picked_winds_player_names, picked_winds_player_names)
    |> assign(:relative_game_seats, relative_game_seats)
    |> assign(:show_stick, show_stick)
    |> assign(:show_wind_picking, show_wind_picking)
    |> assign(:show_wall, show_wall)
    |> assign(:show_player_names, show_player_names)
    |> assign(:show_dice, show_dice)
  end

  defp ensure_game_joinable(socket) do
    if !game_joinable?(socket) do
      socket
      |> put_flash(:error, "Sorry, that game is full.")
      |> push_redirect(to: Routes.game_index_path(socket, :index))
    else
      socket
    end
  end

  defp game_joinable?(socket) do
    socket.assigns.empty_seats_count > 0 || socket.assigns.current_user_sitting_at
  end

  defp assign_event(socket, event) do
    socket
    |> assign(:event, event)
  end
end
