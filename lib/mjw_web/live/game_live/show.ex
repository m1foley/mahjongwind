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

  @impl true
  def handle_info(
        {%Mjw.Game{} = _game, :booted, %{booted_seat: booted_seat} = _event_details},
        socket
      )
      when booted_seat.seatno == socket.assigns.current_user_seatno do
    socket =
      socket
      |> put_flash(:error, "You have been booted from the game.")
      |> push_redirect(to: Routes.game_index_path(socket, :index))

    {:noreply, socket}
  end

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

  # Add bot player
  @impl true
  def handle_event("addbot", _params, socket) do
    game = socket.assigns.game |> Mjw.Game.seat_bot()
    socket = socket |> update_game(game, :bot_added)

    {:noreply, socket}
  end

  # Open game menu
  @impl true
  def handle_event("opengamemenu", _params, socket) do
    socket =
      socket
      |> assign_event(:opened_game_menu)

    {:noreply, socket}
  end

  # Close game menu
  @impl true
  def handle_event("closegamemenu", _params, socket) do
    socket =
      socket
      |> assign_event(:closed_game_menu)

    {:noreply, socket}
  end

  # Peek next deck tile, which actually draws it and moves it to their hand
  @impl true
  def handle_event("peek", _params, socket) do
    current_user_seatno = socket.assigns.current_user_seatno
    game = socket.assigns.game |> Mjw.Game.peek_deck_tile(current_user_seatno)

    socket = socket |> update_game(game, :drew_from_deck)

    {:noreply, socket}
  end

  @impl true
  def handle_event("undo", _params, socket)
      when socket.assigns.current_user_can_undo do
    game = socket.assigns.game |> Mjw.Game.undo()
    socket = socket |> update_game(game, :undo)

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
      )
      when length(new_concealed) == length(socket.assigns.current_user_seat.concealed) do
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
      )
      when length(new_exposed) == length(socket.assigns.current_user_seat.exposed) do
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
          "draggedFromId" => dragged_from,
          "draggedToId" => "discards",
          "draggedId" => discarded_tile
        },
        socket
      )
      when dragged_from in ["concealed-0", "exposed-0", "peektile-0"] do
    current_user_seatno = socket.assigns.current_user_seatno

    game =
      socket.assigns.game
      |> Mjw.Game.discard(current_user_seatno, discarded_tile)

    socket = socket |> update_game(game, :discarded)

    {:noreply, socket}
  end

  # drew from the discards when it's the player's turn
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
      )
      when socket.assigns.current_user_drawing and
             length(new_exposed) == length(socket.assigns.current_user_seat.exposed) + 1 do
    current_user_seatno = socket.assigns.current_user_seatno
    game = socket.assigns.game

    game = game |> Mjw.Game.draw_discard(current_user_seatno, new_exposed, tile)

    socket = socket |> update_game(game, :drew_discard, %{tile: tile})

    {:noreply, socket}
  end

  # pong
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
      )
      when not socket.assigns.current_user_drawing and
             length(new_exposed) == length(socket.assigns.current_user_seat.exposed) + 1 do
    current_user_seatno = socket.assigns.current_user_seatno
    game = socket.assigns.game

    game = game |> Mjw.Game.pong(current_user_seatno, new_exposed, tile)

    socket = socket |> update_game(game, :ponged, %{tile: tile})

    {:noreply, socket}
  end

  # peektile -> concealed
  @impl true
  def handle_event(
        "dropped",
        %{
          "draggedFromId" => "peektile-0",
          "draggedToId" => "concealed-0",
          "draggedToList" => new_concealed
        },
        socket
      )
      when length(new_concealed) == length(socket.assigns.current_user_seat.concealed) + 1 do
    current_user_seatno = socket.assigns.current_user_seatno

    game =
      socket.assigns.game
      |> Mjw.Game.update_concealed(current_user_seatno, new_concealed)
      |> Mjw.Game.clear_peektile(current_user_seatno)

    socket = socket |> update_game(game, :kept_peektile, %{local_only: true})

    {:noreply, socket}
  end

  # peektile -> hiddengongs
  @impl true
  def handle_event(
        "dropped",
        %{
          "draggedFromId" => "peektile-0",
          "draggedToId" => "hiddengongs-0",
          "draggedToList" => new_hiddengongs
        },
        socket
      )
      when length(new_hiddengongs) == length(socket.assigns.current_user_seat.hiddengongs) + 1 do
    current_user_seatno = socket.assigns.current_user_seatno

    game =
      socket.assigns.game
      |> Mjw.Game.update_hiddengongs(current_user_seatno, new_hiddengongs)
      |> Mjw.Game.clear_peektile(current_user_seatno)

    socket = socket |> update_game(game, :hiddengonged_tile)

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
      )
      when length(new_exposed) == length(socket.assigns.current_user_seat.exposed) + 1 and
             length(new_concealed) == length(socket.assigns.current_user_seat.concealed) - 1 do
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
      )
      when length(new_exposed) == length(socket.assigns.current_user_seat.exposed) - 1 and
             length(new_concealed) == length(socket.assigns.current_user_seat.concealed) + 1 do
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
      )
      when length(new_concealed) == length(socket.assigns.current_user_seat.concealed) - 1 and
             length(new_hiddengongs) == length(socket.assigns.current_user_seat.hiddengongs) + 1 do
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
      )
      when length(new_hiddengongs) == length(socket.assigns.current_user_seat.hiddengongs) do
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
      )
      when length(new_hiddengongs) == length(socket.assigns.current_user_seat.hiddengongs) - 1 and
             length(new_concealed) == length(socket.assigns.current_user_seat.concealed) + 1 do
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
      )
      when length(new_hiddengongs) == length(socket.assigns.current_user_seat.hiddengongs) - 1 and
             length(new_exposed) == length(socket.assigns.current_user_seat.exposed) + 1 do
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
      )
      when length(new_exposed) == length(socket.assigns.current_user_seat.exposed) - 1 and
             length(new_hiddengongs) == length(socket.assigns.current_user_seat.hiddengongs) + 1 do
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
      )
      when length(new_concealed) == length(socket.assigns.current_user_seat.concealed) + 1 do
    game = socket.assigns.game
    current_user_seatno = socket.assigns.current_user_seatno

    {game, tile} = game |> Mjw.Game.draw_correction_tile(current_user_seatno, new_concealed)

    socket = socket |> update_game(game, :drew_correction_tile, %{tile: tile})

    {:noreply, socket}
  end

  # peektile/concealed/exposed -> wintile: declaring a win
  @impl true
  def handle_event(
        "dropped",
        %{
          "draggedFromId" => dragged_from,
          "draggedToId" => "wintile-0",
          "draggedId" => tile
        },
        socket
      )
      when dragged_from in ["peektile-0", "concealed-0", "exposed-0"] do
    current_user_seatno = socket.assigns.current_user_seatno
    game = socket.assigns.game

    game = game |> Mjw.Game.declare_win_from_hand(current_user_seatno, tile)

    socket = socket |> update_game(game, :declared_win, %{tile: tile})

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
      |> Mjw.Game.declare_win_from_discards(current_user_seatno, tile)

    socket = socket |> update_game(game, :declared_win, %{tile: tile})

    {:noreply, socket}
  end

  # If a drag & drop event doesn't pattern match the above, it probably hit a
  # "length" sanity check in a method guard. Reload the page to get the
  # frontend back in sync and let the user try the action again.
  # Game reload is done via HTTP redirect: it would be preferable to just
  # reload the game from persistence and re-render, but that doesn't fix the
  # JavaScript if it got out of sync.
  @impl true
  def handle_event("dropped", _params, socket) do
    game_id = socket.assigns.game.id
    socket = socket |> push_redirect(to: Routes.game_show_path(socket, :show, game_id))

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

  # Boot a player
  @impl true
  def handle_event("bootplayer", %{"seatno" => booted_seatno}, socket) do
    booted_seatno = String.to_integer(booted_seatno)

    booted_seat =
      socket.assigns.game.seats
      |> Enum.at(booted_seatno)
      |> Map.merge(%{seatno: booted_seatno})

    event_details = %{seat: socket.assigns.current_user_seat, booted_seat: booted_seat}

    game =
      socket.assigns.game
      |> Mjw.Game.boot(booted_seatno)
      |> MjwWeb.GameStore.update_with_lobby_change(:booted, event_details)

    socket =
      socket
      |> assign_event(:booted, event_details)
      |> assign_game_info(game)

    {:noreply, socket}
  end

  # Sit down
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

  # Pick a wind tile
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
    event = socket.assigns.event
    event_details = socket.assigns.event_details
    show_wind_picking_was = socket.assigns[:show_wind_picking]

    empty_seats_count = Mjw.Game.empty_seats_count(game)
    current_user_seatno = Mjw.Game.sitting_at(game, current_user_id)
    game_state = Mjw.Game.state(game)
    turn_player_name = Mjw.Game.turn_player_name(game)
    last_discarded_seatno = Mjw.Game.last_discarded_seatno(game)
    current_user_can_undo = game.undo_seatno == current_user_seatno

    # seats ordered by their position to the current player (0 = self, etc.).
    # Extra attributes added for convenience or LiveView diff optimization:
    # seatno (get original index in seats), win_expose
    relative_game_seats =
      0..3
      |> Enum.map(fn i ->
        Mjw.Game.seat_with_relative_position(game, i, current_user_seatno || 0)
      end)
      |> Enum.with_index()
      |> Enum.sort_by(fn {{_seat, relative_position}, _i} -> relative_position end)
      |> Enum.map(fn {{seat, _relative_position}, i} ->
        Map.merge(seat, %{seatno: i, win_expose: Mjw.Seat.win_expose?(seat)})
      end)

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
    rolled_dice = event in [:rolled_for_first_dealer, :rolled_for_deal]

    player_seats_finalized =
      game_state not in [:waiting_for_players, :picking_winds, :rolling_for_first_dealer]

    win_declared_seatno =
      if game_state == :win_declared, do: game |> Mjw.Game.win_declared_seatno()

    dq_confetti = event == :dq
    win_confetti = !dq_confetti && win_declared_seatno

    current_user_drawing =
      !win_declared_seatno && game_state == :drawing &&
        game.turn_seatno == current_user_seatno

    # because of pongs, discards are available to everyone except
    # last_discarded_seatno
    available_discard_tile =
      if !win_declared_seatno && game_state == :drawing &&
           last_discarded_seatno != current_user_seatno do
        game.discards |> Enum.at(0)
      end

    discarded_by_relative_seatno =
      if available_discard_tile do
        relative_game_seats |> Enum.find_index(&(&1.seatno == last_discarded_seatno))
      end

    current_user_discarding =
      !win_declared_seatno &&
        game_state == :discarding && game.turn_seatno == current_user_seatno

    show_correction_tile =
      player_seats_finalized && !win_declared_seatno &&
        !current_user_drawing && might_have_gongs?(current_user_seat)

    non_discard_glow_tile = non_discard_glow_tile(event, event_details, current_user_seatno)

    turn_glow_seatno = unless win_declared_seatno, do: game.turn_seatno

    deck_remaining = length(game.deck)

    socket
    |> assign(:game, game)
    |> assign(:empty_seats_count, empty_seats_count)
    |> assign(:current_user_seatno, current_user_seatno)
    |> assign(:game_state, game_state)
    |> assign(:turn_player_name, turn_player_name)
    |> assign(:current_user_can_undo, current_user_can_undo)
    |> assign(:relative_game_seats, relative_game_seats)
    |> assign(:current_user_seat, current_user_seat)
    |> assign(:show_stick, show_stick)
    |> assign(:show_wind_picking, show_wind_picking)
    |> assign(:show_wall, show_wall)
    |> assign(:rolling_dice, rolling_dice)
    |> assign(:rolled_dice, rolled_dice)
    |> assign(:player_seats_finalized, player_seats_finalized)
    |> assign(:win_declared_seatno, win_declared_seatno)
    |> assign(:dq_confetti, dq_confetti)
    |> assign(:win_confetti, win_confetti)
    |> assign(:current_user_drawing, current_user_drawing)
    |> assign(:available_discard_tile, available_discard_tile)
    |> assign(:discarded_by_relative_seatno, discarded_by_relative_seatno)
    |> assign(:current_user_discarding, current_user_discarding)
    |> assign(:show_correction_tile, show_correction_tile)
    |> assign(:non_discard_glow_tile, non_discard_glow_tile)
    |> assign(:turn_glow_seatno, turn_glow_seatno)
    |> assign(:deck_remaining, deck_remaining)
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
    :kept_peektile,
    # opened_game_menu/closed_game_menu don't get sent to other players, but
    # they are nonetheless ignored by business logic; without these here, CSS
    # animations get replayed when opening/closing the game menu.
    :opened_game_menu,
    :closed_game_menu
  ]

  defp assign_event(socket, event, event_details \\ %{})

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

  defp might_have_gongs?(%Mjw.Seat{exposed: exposed, hiddengongs: hiddengongs}) do
    length(exposed) > 3 || length(hiddengongs) > 3
  end

  defp might_have_gongs?(_empty_seat), do: false

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
    :undo,
    :draw,
    :dq,
    :reset
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

  @current_player_glow_tile_events [
    :drew_discard,
    :ponged,
    :drew_correction_tile
  ]

  @other_player_glow_tile_events [
    :exposed_tile,
    :drew_discard,
    :ponged,
    :declared_win
  ]

  defp non_discard_glow_tile(event, %{seat: event_seatno, tile: event_tile}, current_user_seatno)
       when (event_seatno == current_user_seatno and event in @current_player_glow_tile_events) or
              (event_seatno != current_user_seatno and event in @other_player_glow_tile_events) do
    event_tile
  end

  defp non_discard_glow_tile(_event, _event_details, _current_user_seatno), do: nil
end
