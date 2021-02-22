defmodule MjwWeb.GameLive.Show do
  use MjwWeb, :live_view

  @impl true
  def mount(%{"id" => id}, session, socket) do
    socket = socket |> assign_defaults(session)
    game = MjwWeb.GameStore.get(id)

    socket =
      if game do
        socket =
          socket
          |> assign_event(:initial)
          |> assign_game_info(game)

        if game_joinable?(socket) do
          socket |> subscribe_to_game_updates()
        else
          socket |> unjoinable_game_redirect()
        end
      else
        socket |> game_not_found_redirect()
      end

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket), do: {:noreply, socket}

  # Ignore game updates initiated by the current player because the local
  # assigns should have already been taken care of (usually by update_game/4)
  @impl true
  def handle_info({%Mjw.Game{} = _game, _event, %{seat: seat} = _event_details}, socket)
      when seat.seatno == socket.assigns.current_user_seatno do
    {:noreply, socket}
  end

  # When another player updates the game, update the local assigns and redraw
  @impl true
  def handle_info({%Mjw.Game{} = game, event, event_details}, socket) do
    game = game |> merge_updated_game(socket, event)

    socket =
      socket
      |> assign_event(event, event_details)
      |> assign_game_info(game)

    {:noreply, socket}
  end

  @impl true
  def handle_event("opengamemenu", _params, socket) do
    socket =
      socket
      |> assign_event(:opened_game_menu)

    {:noreply, socket}
  end

  @impl true
  def handle_event("closegamemenu", _params, socket) do
    socket =
      socket
      |> assign_event(:closed_game_menu)

    {:noreply, socket}
  end

  # Sorting one's own concealed tiles
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
    current_user_seat = socket.assigns.current_user_seat
    game_state = socket.assigns.game_state

    game =
      socket.assigns.game
      |> Mjw.Game.update_concealed(current_user_seat.seatno, new_concealed)

    local_only = game_state != :win_declared || !Mjw.Seat.win_expose?(current_user_seat)
    socket = socket |> update_game(game, :concealed_sorted, %{local_only: local_only})

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
    current_user_seatno = socket.assigns.current_user_seatno

    game =
      socket.assigns.game
      |> Mjw.Game.update_exposed(current_user_seatno, new_exposed)

    socket = socket |> update_game(game, :exposed_sorted)

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
    current_user_seatno = socket.assigns.current_user_seatno

    game =
      socket.assigns.game
      |> Mjw.Game.discard(current_user_seatno, discarded_tile)

    socket = socket |> update_game(game, :discarded)

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
    current_user_seatno = socket.assigns.current_user_seatno
    game = socket.assigns.game

    # event is :drew_discard or :ponged, depending on if it's the player's turn
    {event, game} =
      game
      |> Mjw.Game.draw_discard(current_user_seatno, new_exposed)

    socket = socket |> update_game(game, event, %{tile: tile})

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
    current_user_seatno = socket.assigns.current_user_seatno
    game = socket.assigns.game

    {game, tile} = game |> Mjw.Game.draw_from_deck(current_user_seatno, new_concealed)
    socket = socket |> update_game(game, :drew_from_deck, %{tile: tile})

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
    current_user_seatno = socket.assigns.current_user_seatno

    game =
      socket.assigns.game
      |> Mjw.Game.update_concealed(current_user_seatno, new_concealed)
      |> Mjw.Game.update_exposed(current_user_seatno, new_exposed)

    socket = socket |> update_game(game, :exposed_tile, %{tile: tile})

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
    current_user_seatno = socket.assigns.current_user_seatno

    game =
      socket.assigns.game
      |> Mjw.Game.update_concealed(current_user_seatno, new_concealed)
      |> Mjw.Game.update_exposed(current_user_seatno, new_exposed)

    socket = socket |> update_game(game, :unexposed_tile)

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
    current_user_seatno = socket.assigns.current_user_seatno

    game =
      socket.assigns.game
      |> Mjw.Game.update_hiddengongs(current_user_seatno, new_hiddengongs)
      |> Mjw.Game.update_concealed(current_user_seatno, new_concealed)

    socket = socket |> update_game(game, :hiddengonged_tile)

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
    current_user_seat = socket.assigns.current_user_seat
    game_state = socket.assigns.game_state

    game =
      socket.assigns.game
      |> Mjw.Game.update_hiddengongs(current_user_seat.seatno, new_hiddengongs)

    local_only = game_state != :win_declared || !Mjw.Seat.win_expose?(current_user_seat)
    socket = socket |> update_game(game, :hiddengongs_sorted, %{local_only: local_only})

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
    current_user_seatno = socket.assigns.current_user_seatno

    game =
      socket.assigns.game
      |> Mjw.Game.update_concealed(current_user_seatno, new_concealed)
      |> Mjw.Game.update_hiddengongs(current_user_seatno, new_hiddengongs)

    socket = socket |> update_game(game, :unhiddengonged_tile)

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
    current_user_seatno = socket.assigns.current_user_seatno

    game =
      socket.assigns.game
      |> Mjw.Game.update_hiddengongs(current_user_seatno, new_hiddengongs)
      |> Mjw.Game.update_exposed(current_user_seatno, new_exposed)

    socket = socket |> update_game(game, :exposed_hiddengong_tile)

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
    current_user_seatno = socket.assigns.current_user_seatno

    game =
      socket.assigns.game
      |> Mjw.Game.update_exposed(current_user_seatno, new_exposed)
      |> Mjw.Game.update_hiddengongs(current_user_seatno, new_hiddengongs)

    socket = socket |> update_game(game, :hiddengonged_exposed_tile)

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
    game = socket.assigns.game
    current_user_seatno = socket.assigns.current_user_seatno

    {game, tile} = game |> Mjw.Game.draw_correction_tile(current_user_seatno, new_concealed)

    socket = socket |> update_game(game, :drew_correction_tile, %{tile: tile})

    {:noreply, socket}
  end

  # concealed -> wintile: declaring a win
  @impl true
  def handle_event(
        "dropped",
        %{
          "draggedFromId" => "concealed-0",
          "draggedToId" => "wintile-0",
          "draggedFromList" => new_concealed,
          "draggedId" => tile
        },
        socket
      ) do
    current_user_seatno = socket.assigns.current_user_seatno

    game =
      socket.assigns.game
      |> Mjw.Game.update_concealed(current_user_seatno, new_concealed)
      |> Mjw.Game.update_wintile(current_user_seatno, tile)

    socket = socket |> update_game(game, :declared_win)

    {:noreply, socket}
  end

  # discards -> wintile: declaring a win from a discard
  @impl true
  def handle_event(
        "dropped",
        %{
          "draggedFromId" => "discards",
          "draggedToId" => "wintile-0",
          "draggedId" => tile
        },
        socket
      ) do
    current_user_seatno = socket.assigns.current_user_seatno

    game =
      socket.assigns.game
      |> Mjw.Game.update_wintile_from_discards(current_user_seatno, tile)

    socket = socket |> update_game(game, :declared_win)

    {:noreply, socket}
  end

  # exposed -> wintile: declaring a win clumsily
  @impl true
  def handle_event(
        "dropped",
        %{
          "draggedFromId" => "exposed-0",
          "draggedToId" => "wintile-0",
          "draggedFromList" => new_exposed,
          "draggedId" => tile
        },
        socket
      ) do
    current_user_seatno = socket.assigns.current_user_seatno

    game =
      socket.assigns.game
      |> Mjw.Game.update_exposed(current_user_seatno, new_exposed)
      |> Mjw.Game.update_wintile(current_user_seatno, tile)

    socket = socket |> update_game(game, :declared_win)

    {:noreply, socket}
  end

  # wintile -> concealed: undoing a win
  @impl true
  def handle_event(
        "dropped",
        %{
          "draggedFromId" => "wintile-0",
          "draggedToId" => "concealed-0",
          "draggedToList" => new_concealed
        },
        socket
      ) do
    current_user_seatno = socket.assigns.current_user_seatno

    game =
      socket.assigns.game
      |> Mjw.Game.update_concealed(current_user_seatno, new_concealed)
      |> Mjw.Game.update_wintile(current_user_seatno, nil)

    socket = socket |> update_game(game, :undid_win)

    {:noreply, socket}
  end

  # wintile -> exposed: undoing a win
  @impl true
  def handle_event(
        "dropped",
        %{
          "draggedFromId" => "wintile-0",
          "draggedToId" => "exposed-0",
          "draggedToList" => new_exposed
        },
        socket
      ) do
    current_user_seatno = socket.assigns.current_user_seatno

    game =
      socket.assigns.game
      |> Mjw.Game.update_exposed(current_user_seatno, new_exposed)
      |> Mjw.Game.update_wintile(current_user_seatno, nil)

    socket = socket |> update_game(game, :undid_win)

    {:noreply, socket}
  end

  # DQ declared winner
  @impl true
  def handle_event("dqdeclared", _params, socket) do
    dqseatno = socket.assigns.win_declared_seatno
    dqseat = socket.assigns.game.seats |> Enum.at(dqseatno)

    game = socket.assigns.game |> Mjw.Game.dq(dqseatno)

    socket = socket |> update_game(game, :dq, %{dqseat: dqseat})

    {:noreply, socket}
  end

  # Confirm another player's declared win
  @impl true
  def handle_event("confirm_win", _params, socket) do
    current_user_seatno = socket.assigns.current_user_seatno

    game =
      socket.assigns.game
      |> Mjw.Game.confirm_win(current_user_seatno)

    socket = socket |> update_game(game, :confirmed_win)

    {:noreply, socket}
  end

  # Expose loser hand
  @impl true
  def handle_event("expose", _params, socket) do
    current_user_seatno = socket.assigns.current_user_seatno

    game =
      socket.assigns.game
      |> Mjw.Game.expose_loser_hand(current_user_seatno)

    socket = socket |> update_game(game, :exposed_loser_hand)

    {:noreply, socket}
  end

  # Reset game
  @impl true
  def handle_event("reset", _params, socket) do
    game = socket.assigns.game |> Mjw.Game.reset()
    socket = socket |> update_game(game, :reset)

    {:noreply, socket}
  end

  # Declare draw game
  @impl true
  def handle_event("draw", _params, socket) do
    game = socket.assigns.game |> Mjw.Game.draw()
    socket = socket |> update_game(game, :draw)

    {:noreply, socket}
  end

  # DQ a player
  @impl true
  def handle_event("dq", %{"seatno" => dqseatno}, socket) do
    dqseatno = String.to_integer(dqseatno)
    dqseat = socket.assigns.game.seats |> Enum.at(dqseatno)
    game = socket.assigns.game |> Mjw.Game.dq(dqseatno)
    socket = socket |> update_game(game, :dq, %{dqseat: dqseat})

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "accept_seat_offering",
        %{"seat_offering" => %{"player_name" => player_name}},
        socket
      ) do
    player_id = socket.assigns.current_user_id

    game =
      socket.assigns.game
      |> Mjw.Game.seat_player(player_id, player_name)

    seat = game |> Mjw.Game.seat(player_id)

    MjwWeb.GameStore.update_with_lobby_change(game, :player_seated, %{seat: seat})

    socket =
      socket
      |> assign_event(:player_seated, %{seat: seat})
      |> assign_game_info(game)

    {:noreply, socket}
  end

  # Pick a wind before sitting down
  @impl true
  def handle_event("windpick", %{"picked-wind-idx" => picked_wind_idx}, socket) do
    picked_wind_idx = String.to_integer(picked_wind_idx)
    current_user_id = socket.assigns.current_user_id

    game =
      socket.assigns.game
      |> Mjw.Game.pick_random_available_wind(current_user_id, picked_wind_idx)

    socket = socket |> update_game(game, :picked_wind)

    {:noreply, socket}
  end

  # Roll dice
  @impl true
  def handle_event("roll", _params, socket) do
    game_state = socket.assigns.game_state

    socket =
      socket
      |> persist_roll(game_state)

    {:noreply, socket}
  end

  defp persist_roll(socket, :rolling_for_first_dealer) do
    game =
      socket.assigns.game
      |> Mjw.Game.roll_dice()
      |> Mjw.Game.reseat_players()

    socket |> update_game(game, :rolled_for_first_dealer)
  end

  defp persist_roll(socket, :rolling_for_deal) do
    game =
      socket.assigns.game
      |> Mjw.Game.roll_dice()
      |> Mjw.Game.deal()

    socket |> update_game(game, :rolled_for_deal)
  end

  defp game_not_found_redirect(socket) do
    socket
    |> put_flash(:error, "That game ID does not exist.")
    |> push_redirect(to: Routes.game_index_path(socket, :index))
  end

  defp subscribe_to_game_updates(socket) do
    if connected?(socket) do
      socket.assigns.game
      |> MjwWeb.GameStore.subscribe_to_game_updates()
    end

    socket
  end

  defp assign_game_info(socket, %Mjw.Game{} = game) do
    current_user_id = socket.assigns.current_user_id
    show_wind_picking_was = socket.assigns[:show_wind_picking]

    empty_seats_count = Mjw.Game.empty_seats_count(game)
    current_user_seatno = Mjw.Game.sitting_at(game, current_user_id)
    game_state = Mjw.Game.state(game)
    turn_player_name = Mjw.Game.turn_player_name(game)
    win_declared_seatno = game_state == :win_declared && game |> Mjw.Game.win_declared_seatno()

    # seats ordered by their position to the current player (0 = self, etc.).
    # A seatno attribute is added as a convenience to get the original index.
    relative_game_seats =
      0..3
      |> Enum.map(fn i ->
        Mjw.Game.seat_with_relative_position(game, i, current_user_seatno || 0)
      end)
      |> Enum.with_index()
      |> Enum.sort_by(fn {{_seat, relative_position}, _i} -> relative_position end)
      |> Enum.map(fn {{seat, _relative_position}, i} -> Map.merge(seat, %{seatno: i}) end)

    current_user_seat = relative_game_seats |> Enum.at(0)

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

    rolling_dice = game_state in [:rolling_for_first_dealer, :rolling_for_deal]
    rolled_dice = socket.assigns.event in [:rolled_for_first_dealer, :rolled_for_deal]

    player_seats_finalized =
      game_state not in [:waiting_for_players, :picking_winds, :rolling_for_first_dealer]

    current_user_drawing =
      !win_declared_seatno && game_state == :drawing &&
        game.turn_seatno == current_user_seatno

    # not limited to turn_seatno because of pongs
    enable_pull_from_discards =
      !win_declared_seatno &&
        game_state == :drawing && game.prev_turn_seatno != current_user_seatno

    discarded_by_relative_seatno =
      if enable_pull_from_discards do
        relative_game_seats |> Enum.find_index(&(&1.seatno == game.prev_turn_seatno))
      end

    current_user_discarding =
      !win_declared_seatno &&
        game_state == :discarding && game.turn_seatno == current_user_seatno

    show_correction_tile =
      !win_declared_seatno && !current_user_drawing && might_have_gongs?(current_user_seat)

    socket
    |> assign(:game, game)
    |> assign(:empty_seats_count, empty_seats_count)
    |> assign(:current_user_seatno, current_user_seatno)
    |> assign(:game_state, game_state)
    |> assign(:turn_player_name, turn_player_name)
    |> assign(:relative_game_seats, relative_game_seats)
    |> assign(:current_user_seat, current_user_seat)
    |> assign(:show_stick, show_stick)
    |> assign(:show_wind_picking, show_wind_picking)
    |> assign(:show_wall, show_wall)
    |> assign(:rolling_dice, rolling_dice)
    |> assign(:rolled_dice, rolled_dice)
    |> assign(:player_seats_finalized, player_seats_finalized)
    |> assign(:current_user_drawing, current_user_drawing)
    |> assign(:enable_pull_from_discards, enable_pull_from_discards)
    |> assign(:discarded_by_relative_seatno, discarded_by_relative_seatno)
    |> assign(:current_user_discarding, current_user_discarding)
    |> assign(:show_correction_tile, show_correction_tile)
    |> assign(:win_declared_seatno, win_declared_seatno)
  end

  defp unjoinable_game_redirect(socket) do
    socket
    |> put_flash(:error, "Sorry, that game is full.")
    |> push_redirect(to: Routes.game_index_path(socket, :index))
  end

  defp game_joinable?(socket) do
    socket.assigns.empty_seats_count > 0 || socket.assigns.current_user_seatno
  end

  @ignored_events [
    # A player sorting their own hand is not considered a significant event to
    # other players, so restore the previous event for business logic (it's
    # still assigned to raw_event if needed).
    :concealed_sorted,
    :exposed_sorted,
    :hiddengongs_sorted,
    # opened_game_menu/closed_game_menu don't get sent to other players, but
    # they are nonetheless ignored by business logic; without these here, CSS
    # animations get replayed when opening/closing the game menu.
    :opened_game_menu,
    :closed_game_menu
  ]

  defp assign_event(socket, event), do: assign_event(socket, event, nil)

  defp assign_event(socket, event, _event_details)
       when event in @ignored_events do
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

  defp might_have_gongs?(nil = _seat), do: false

  # Show the gong correction tile if it's possible the user has a gong
  defp might_have_gongs?(%Mjw.Seat{} = seat) do
    length(seat.exposed) + length(seat.hidden_gongs) > 3
  end

  # :local_only is used to update the local assigns without persisting the
  # game. This avoids sending private events like sorting one's own concealed
  # tiles to other players, which reduces network traffic and avoids race
  # conditions when everyone is sorting their tiles at the same time.
  defp update_game(socket, game, event, event_details \\ %{}) do
    current_user_seat = socket.assigns.current_user_seat
    local_only = event_details |> Map.get(:local_only)

    event_details =
      event_details
      |> Map.delete(:local_only)
      |> Map.merge(%{seat: current_user_seat})

    unless local_only do
      MjwWeb.GameStore.update(game, event, event_details)
    end

    socket
    |> assign_event(event, event_details)
    |> assign_game_info(game)
  end

  @events_that_change_other_players_seats [
    :rolled_for_first_dealer,
    :rolled_for_deal,
    :confirmed_win,
    :undid_win,
    :draw,
    :dq
  ]

  # There are only a few events from other players that can change the current
  # player's seat. Overwrite the game instead of trying to merge it.
  defp merge_updated_game(%Mjw.Game{} = game, _socket, event)
       when event in @events_that_change_other_players_seats,
       do: game

  # No player can update another player's seat (aside for the exceptions noted
  # above). Therefore, we can merge any game changes from other players with
  # the locally assigned seat. This allows players to sort their concealed
  # tiles independently of the other players.
  defp merge_updated_game(%Mjw.Game{} = game, socket, _event) do
    current_user_seat = socket.assigns.current_user_seat
    game |> Mjw.Game.replace_seat(current_user_seat.seatno, current_user_seat)
  end
end
