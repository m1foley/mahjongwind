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
  def handle_info({%Mjw.Game{} = game, event, event_details}, socket) do
    socket =
      socket
      |> assign(:game, game)
      |> assign_event(event, event_details)
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

    socket.assigns.game
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
    |> MjwWeb.GameStore.update(event, %{tile: tile})

    {:noreply, socket}
  end

  # drew from the deck offer
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
    game |> MjwWeb.GameStore.update(:drew_from_deck, %{tile: tile})

    {:noreply, socket}
  end

  # concealed -> exposed: exposing a tile
  @impl true
  def handle_event(
        "dropped",
        %{
          "draggedFromId" => "concealed-0",
          "draggedToId" => "exposed-0",
          "draggedFromList" => new_concealed,
          "draggedToList" => new_exposed,
          "draggedId" => tile
        },
        socket
      ) do
    current_user_sitting_at = socket.assigns.current_user_sitting_at

    socket.assigns.game
    |> Mjw.Game.update_concealed(current_user_sitting_at, new_concealed)
    |> Mjw.Game.update_exposed(current_user_sitting_at, new_exposed)
    |> MjwWeb.GameStore.update(:exposed_tile, %{tile: tile})

    {:noreply, socket}
  end

  # exposed -> concealed: fixing accidental exposure
  @impl true
  def handle_event(
        "dropped",
        %{
          "draggedFromId" => "exposed-0",
          "draggedToId" => "concealed-0",
          "draggedFromList" => new_exposed,
          "draggedToList" => new_concealed
        },
        socket
      ) do
    current_user_sitting_at = socket.assigns.current_user_sitting_at

    socket.assigns.game
    |> Mjw.Game.update_concealed(current_user_sitting_at, new_concealed)
    |> Mjw.Game.update_exposed(current_user_sitting_at, new_exposed)
    |> MjwWeb.GameStore.update(:unexposed_tile)

    {:noreply, socket}
  end

  # concealed -> hiddengongs
  @impl true
  def handle_event(
        "dropped",
        %{
          "draggedFromId" => "concealed-0",
          "draggedToId" => "hiddengongs-0",
          "draggedFromList" => new_concealed,
          "draggedToList" => new_hiddengongs
        },
        socket
      ) do
    current_user_sitting_at = socket.assigns.current_user_sitting_at

    socket.assigns.game
    |> Mjw.Game.update_hiddengongs(current_user_sitting_at, new_hiddengongs)
    |> Mjw.Game.update_concealed(current_user_sitting_at, new_concealed)
    |> MjwWeb.GameStore.update(:hiddengonged_tile)

    {:noreply, socket}
  end

  # sorting one's own hidden gongs
  @impl true
  def handle_event(
        "dropped",
        %{
          "draggedFromId" => "hiddengongs-0",
          "draggedToId" => "hiddengongs-0",
          "draggedToList" => new_hiddengongs
        },
        socket
      ) do
    current_user_sitting_at = socket.assigns.current_user_sitting_at

    socket.assigns.game
    |> Mjw.Game.update_hiddengongs(current_user_sitting_at, new_hiddengongs)
    |> MjwWeb.GameStore.update(:hiddengongs_sorted)

    {:noreply, socket}
  end

  # hiddengongs -> concealed: fixing accidental hidden gongs
  @impl true
  def handle_event(
        "dropped",
        %{
          "draggedFromId" => "hiddengongs-0",
          "draggedToId" => "concealed-0",
          "draggedFromList" => new_hiddengongs,
          "draggedToList" => new_concealed
        },
        socket
      ) do
    current_user_sitting_at = socket.assigns.current_user_sitting_at

    socket.assigns.game
    |> Mjw.Game.update_concealed(current_user_sitting_at, new_concealed)
    |> Mjw.Game.update_hiddengongs(current_user_sitting_at, new_hiddengongs)
    |> MjwWeb.GameStore.update(:unhiddengonged_tile)

    {:noreply, socket}
  end

  # hiddengongs -> exposed: exposing a hidden gong tile
  @impl true
  def handle_event(
        "dropped",
        %{
          "draggedFromId" => "hiddengongs-0",
          "draggedToId" => "exposed-0",
          "draggedFromList" => new_hiddengongs,
          "draggedToList" => new_exposed
        },
        socket
      ) do
    current_user_sitting_at = socket.assigns.current_user_sitting_at

    socket.assigns.game
    |> Mjw.Game.update_hiddengongs(current_user_sitting_at, new_hiddengongs)
    |> Mjw.Game.update_exposed(current_user_sitting_at, new_exposed)
    |> MjwWeb.GameStore.update(:exposed_hiddengong_tile)

    {:noreply, socket}
  end

  # exposed -> hiddengongs: hiding an exposed gong
  @impl true
  def handle_event(
        "dropped",
        %{
          "draggedFromId" => "exposed-0",
          "draggedToId" => "hiddengongs-0",
          "draggedFromList" => new_exposed,
          "draggedToList" => new_hiddengongs
        },
        socket
      ) do
    current_user_sitting_at = socket.assigns.current_user_sitting_at

    socket.assigns.game
    |> Mjw.Game.update_exposed(current_user_sitting_at, new_exposed)
    |> Mjw.Game.update_hiddengongs(current_user_sitting_at, new_hiddengongs)
    |> MjwWeb.GameStore.update(:hiddengonged_exposed_tile)

    {:noreply, socket}
  end

  # drew a gong correction tile
  @impl true
  def handle_event(
        "dropped",
        %{
          "draggedFromId" => "correctiontiles",
          "draggedToId" => "concealed-0",
          "draggedToList" => new_concealed
        },
        socket
      ) do
    current_user_sitting_at = socket.assigns.current_user_sitting_at
    game = socket.assigns.game
    player_seat = socket.assigns.relative_game_seats |> Enum.at(0)

    {game, tile} = game |> Mjw.Game.draw_correction_tile(current_user_sitting_at, new_concealed)
    game |> MjwWeb.GameStore.update(:drew_correction_tile, %{tile: tile, seat: player_seat})

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

    show_stick = game_state in [:waiting_for_players, :picking_winds]

    show_wind_picking =
      game_state in [:picking_winds, :rolling_for_first_dealer] ||
        (game_state in [:rolling_for_deal, :discarding] && show_wind_picking_was)

    show_wall =
      game_state in [
        :waiting_for_players,
        :picking_winds,
        :rolling_for_first_dealer,
        :rolling_for_deal
      ]

    show_dice =
      game_state in [:rolling_for_first_dealer, :rolling_for_deal] ||
        (game_state == :discarding && show_wind_picking_was)

    show_player_names =
      game_state not in [:waiting_for_players, :picking_winds, :rolling_for_first_dealer]

    current_user_drawing = game_state == :drawing && game.turn_seatno == current_user_sitting_at

    # not limited to turn_seatno because of pongs
    enable_pull_from_discards =
      game_state == :drawing && game.prev_turn_seatno != current_user_sitting_at

    current_user_discarding =
      game_state == :discarding && game.turn_seatno == current_user_sitting_at

    player_seat = relative_game_seats |> Enum.at(0)
    crowded_exposed_row = crowded_exposed_row?(player_seat)
    show_correction_tile = !current_user_drawing && might_have_gongs?(player_seat)

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
    |> assign(:crowded_exposed_row, crowded_exposed_row)
    |> assign(:show_correction_tile, show_correction_tile)
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

  # A player sorting their own hand is not considered a significant event to
  # other players, so restore the previous event for business logic (it's still
  # assigned to raw_event if needed)
  defp assign_event(socket, event, _event_details)
       when event in [:concealed_sorted, :exposed_sorted, :hiddengongs_sorted] do
    socket
    |> assign(:raw_event, event)
    |> assign(:event, socket.assigns[:event])
    |> assign(:event_details, socket.assigns[:event_details])
  end

  defp assign_event(socket, event, event_details) do
    socket
    |> assign(:raw_event, event)
    |> assign(:event, event)
    |> assign(:event_details, event_details)
  end

  defp crowded_exposed_row?(nil = _seat), do: false

  # No room for hidden gongs & wintile areas if there are too many exposed
  defp crowded_exposed_row?(%Mjw.Seat{} = seat) do
    length(seat.exposed) + length(seat.hidden_gongs) > 10
  end

  defp might_have_gongs?(nil = _seat), do: false

  # Show the gong correction tile if it's possible the user has a gong
  defp might_have_gongs?(%Mjw.Seat{} = seat) do
    length(seat.exposed) + length(seat.hidden_gongs) > 3
  end
end
