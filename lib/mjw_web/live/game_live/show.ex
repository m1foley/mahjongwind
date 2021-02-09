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
        |> assign_event(:initial, nil)
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

  # respond to game updates
  @impl true
  def handle_info({%Mjw.Game{} = game, event, event_detail}, socket) do
    socket =
      socket
      |> assign(:game, game)
      |> assign_event(event, event_detail)
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

  # sorting one's own exposed tiles
  @impl true
  def handle_event(
        "dropped",
        %{
          "draggedFromId" => "exposed-0",
          "draggedToId" => "exposed-0",
          "draggedToList" => new_exposed
        },
        socket
      ) do
    current_user_sitting_at = socket.assigns.current_user_sitting_at

    socket.assigns.game
    |> Mjw.Game.update_exposed(current_user_sitting_at, new_exposed)
    |> MjwWeb.GameStore.update(:exposed_sorted)

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
    current_user_sitting_at = socket.assigns.current_user_sitting_at
    game = socket.assigns.game

    game
    |> Mjw.Game.discard(current_user_sitting_at, discarded_tile)
    |> MjwWeb.GameStore.update(:discarded)

    {:noreply, socket}
  end

  # drew a discard, or ponged
  @impl true
  def handle_event(
        "dropped",
        %{
          "draggedFromId" => "discards",
          "draggedToId" => "exposed-0",
          "draggedId" => tile,
          "draggedToList" => new_exposed
        },
        socket
      ) do
    current_user_sitting_at = socket.assigns.current_user_sitting_at
    game = socket.assigns.game

    # event is :drew_discard or :ponged, depending on if it's the player's turn
    {event, game} =
      game
      |> Mjw.Game.draw_discard(current_user_sitting_at, new_exposed)

    game
    |> MjwWeb.GameStore.update(event, tile)

    {:noreply, socket}
  end

  # drew from the deck
  @impl true
  def handle_event(
        "dropped",
        %{
          "draggedFromId" => "deckoffer",
          "draggedToId" => "concealed-0",
          "draggedToList" => new_concealed
        },
        socket
      ) do
    current_user_sitting_at = socket.assigns.current_user_sitting_at
    game = socket.assigns.game

    {game, tile} = game |> Mjw.Game.draw_from_deck(current_user_sitting_at, new_concealed)
    game |> MjwWeb.GameStore.update(:drew_from_deck, tile)

    {:noreply, socket}
  end

  # concealed -> exposed: exposing a tile
  @impl true
  def handle_event(
        "dropped",
        %{
          "draggedFromId" => "concealed-0",
          "draggedToId" => "exposed-0",
          "draggedToList" => new_exposed,
          "draggedFromList" => new_concealed,
          "draggedId" => tile
        },
        socket
      ) do
    current_user_sitting_at = socket.assigns.current_user_sitting_at

    socket.assigns.game
    |> Mjw.Game.update_concealed(current_user_sitting_at, new_concealed)
    |> Mjw.Game.update_exposed(current_user_sitting_at, new_exposed)
    |> MjwWeb.GameStore.update(:exposed_tile, tile)

    {:noreply, socket}
  end

  # exposed -> concealed: fixing accidental exposure
  @impl true
  def handle_event(
        "dropped",
        %{
          "draggedFromId" => "exposed-0",
          "draggedToId" => "concealed-0",
          "draggedToList" => new_concealed,
          "draggedFromList" => new_exposed
        },
        socket
      ) do
    current_user_sitting_at = socket.assigns.current_user_sitting_at
    game = socket.assigns.game

    game
    |> Mjw.Game.update_concealed(current_user_sitting_at, new_concealed)
    |> Mjw.Game.update_exposed(current_user_sitting_at, new_exposed)
    |> MjwWeb.GameStore.update(:unexposed_tile)

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
    show_wind_picking_was = socket.assigns[:show_wind_picking]

    empty_seats_count = Mjw.Game.empty_seats_count(game)
    current_user_sitting_at = Mjw.Game.sitting_at(game, current_user_id)
    game_state = Mjw.Game.state(game)
    turn_player_name = Mjw.Game.turn_player_name(game)

    # seats ordered by their position to the current player (0 = self, etc.)
    relative_game_seats =
      if empty_seats_count > 0 || !current_user_sitting_at do
        []
      else
        0..3
        |> Enum.map(fn i ->
          Mjw.Game.seat_with_relative_position(game, i, current_user_sitting_at)
        end)
        |> Enum.with_index()
        |> Enum.sort_by(fn {{_seat, relative_position}, _i} -> relative_position end)
        |> Enum.map(fn {{seat, _relative_position}, i} -> Map.merge(seat, %{seatno: i}) end)
      end

    show_stick =
      [:waiting_for_players, :picking_winds]
      |> Enum.member?(game_state)

    show_wind_picking =
      [:picking_winds, :rolling_for_first_dealer] |> Enum.member?(game_state) ||
        ([:rolling_for_deal, :discarding] |> Enum.member?(game_state) && show_wind_picking_was)

    show_wall =
      [:waiting_for_players, :picking_winds, :rolling_for_first_dealer, :rolling_for_deal]
      |> Enum.member?(game_state)

    show_dice =
      [:rolling_for_first_dealer, :rolling_for_deal] |> Enum.member?(game_state) ||
        (game_state == :discarding && show_wind_picking_was)

    show_player_names =
      !([:waiting_for_players, :picking_winds, :rolling_for_first_dealer]
        |> Enum.member?(game_state))

    current_user_drawing = game_state == :drawing && game.turn_seatno == current_user_sitting_at

    # not limited to turn_seatno because of pongs
    enable_pull_from_discards =
      game_state == :drawing && game.prev_turn_seatno != current_user_sitting_at

    current_user_discarding =
      game_state == :discarding && game.turn_seatno == current_user_sitting_at

    player_seat = relative_game_seats |> Enum.at(0)
    show_hidden_gongs_zone = player_seat && show_hidden_gongs_zone?(player_seat)

    socket
    |> assign(:empty_seats_count, empty_seats_count)
    |> assign(:current_user_sitting_at, current_user_sitting_at)
    |> assign(:game_state, game_state)
    |> assign(:turn_player_name, turn_player_name)
    |> assign(:relative_game_seats, relative_game_seats)
    |> assign(:show_stick, show_stick)
    |> assign(:show_wind_picking, show_wind_picking)
    |> assign(:show_wall, show_wall)
    |> assign(:show_dice, show_dice)
    |> assign(:show_player_names, show_player_names)
    |> assign(:current_user_drawing, current_user_drawing)
    |> assign(:enable_pull_from_discards, enable_pull_from_discards)
    |> assign(:current_user_discarding, current_user_discarding)
    |> assign(:show_hidden_gongs_zone, show_hidden_gongs_zone)
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

  # A player sorting their own hand is an event we typically ignore in terms of
  # changing the UI, so restore the previous event for business logic (it's
  # still assigned to raw_event if needed)
  defp assign_event(socket, :concealed_sorted = event, _event_detail) do
    socket
    |> assign(:raw_event, event)
    |> assign(:event, socket.assigns[:event])
    |> assign(:event_detail, socket.assigns[:event_detail])
  end

  defp assign_event(socket, event, event_detail) do
    socket
    |> assign(:raw_event, event)
    |> assign(:event, event)
    |> assign(:event_detail, event_detail)
  end

  # This means it's impossible for the player to achieve a hidden gong.
  # Hide the dropzone to make room in the UI.
  defp show_hidden_gongs_zone?(%Mjw.Seat{} = seat) do
    seat.hidden_gongs == [] && length(seat.concealed) > 3
  end
end
