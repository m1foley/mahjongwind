defmodule MjwWeb.GameLive.Show do
  use MjwWeb, :live_view

  alias Mjw.Games.{Game, GameState, Seat}

  @impl true
  def mount(%{"id" => uuid}, _session, socket) do
    game = MjwWeb.GameStore.get_by_uuid(uuid)

    socket =
      if game do
        socket =
          socket
          |> assign_event(:initial)
          |> assign_game_info(game)

        if game_joinable?(socket) do
          subscribe_to_game_updates(socket)
        else
          unjoinable_game_redirect(socket)
        end
      else
        game_not_found_redirect(socket)
      end

    {:ok, socket}
  end

  # Player booted
  @impl true
  def handle_info(
        {%Game{} = _game, :booted, %{booted_seat: booted_seat} = _event_details},
        socket
      )
      when booted_seat.seatno == socket.assigns.current_user_seatno do
    socket =
      socket
      |> put_flash(:error, "You have been booted from the game.")
      |> push_navigate(to: ~p"/")

    {:noreply, socket}
  end

  # A game update initiated by the current player: ignore because the local
  # assigns should have already been taken care of (usually by update_game/4)
  @impl true
  def handle_info({%Game{} = _game, _event, %{seat: seat} = _event_details}, socket)
      when seat.seatno == socket.assigns.current_user_seatno do
    {:noreply, socket}
  end

  # Another player updates the game: update the local assigns and redraw
  @impl true
  def handle_info({%Game{} = game, event, event_details}, socket) do
    game = merge_updated_game(game, socket, event)

    socket =
      socket
      |> assign_event(event, event_details)
      |> assign_game_info(game)

    {:noreply, socket}
  end

  # Add bot player
  @impl true
  def handle_event("addbot", _params, socket) do
    game =
      socket.assigns.game
      |> Game.seat_bot()
      # might be necessary if a bot joins mid-game
      |> optionally_enqueue_all_bot_actions()

    MjwWeb.GameStore.update_with_lobby_change(game, :bot_added, %{seat: socket.assigns.current_user_seat})

    socket =
      socket
      |> assign_event(:bot_added)
      |> assign_game_info(game)

    {:noreply, socket}
  end

  # Open game menu
  @impl true
  def handle_event("opengamemenu", _params, socket) do
    socket = assign_event(socket, :opened_game_menu)

    {:noreply, socket}
  end

  # Close game menu
  @impl true
  def handle_event("closegamemenu", _params, socket) do
    socket = assign_event(socket, :closed_game_menu)

    {:noreply, socket}
  end

  # Peek next deck tile, which actually draws it and moves it to their hand
  @impl true
  def handle_event("peek", _params, socket) do
    current_user_seatno = socket.assigns.current_user_seatno
    game = Game.peek_deck_tile(socket.assigns.game, current_user_seatno)
    socket = update_game(socket, game, :drew_from_deck)

    {:noreply, socket}
  end

  # Pause bots
  @impl true
  def handle_event("pausebots", _params, socket) do
    game = Game.pause_bots(socket.assigns.game)
    socket = update_game(socket, game, :bots_paused)

    {:noreply, socket}
  end

  # Resume bots
  @impl true
  def handle_event("resumebots", _params, socket) do
    game =
      socket.assigns.game
      |> Game.resume_bots()
      |> optionally_enqueue_all_bot_actions(socket)

    socket = update_game(socket, game, :bots_resumed)

    {:noreply, socket}
  end

  # Undo
  @impl true
  def handle_event("undo", _params, socket)
      when socket.assigns.current_user_can_undo do
    game =
      socket.assigns.game
      |> Game.undo(socket.assigns.current_user_seatno)
      |> optionally_enqueue_all_bot_actions

    socket = update_game(socket, game, :undo)

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

    game = Game.update_concealed(socket.assigns.game, current_user_seat.seatno, new_concealed)
    local_only = game_state != :win_declared || !Seat.win_expose?(current_user_seat)
    socket = update_game(socket, game, :concealed_sorted, %{local_only: local_only})

    {:noreply, socket}
  end

  # Sorting one's own exposed tiles
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
    game = Game.update_exposed(socket.assigns.game, current_user_seatno, new_exposed)
    socket = update_game(socket, game, :exposed_sorted)

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
    socket =
      case Game.discard(
             socket.assigns.game,
             socket.assigns.current_user_seatno,
             discarded_tile
           ) do
        {:ok, game} ->
          game
          |> optionally_enqueue_bot_try_win_out_of_turn(socket)
          |> optionally_enqueue_bot_draw(socket)

          update_game(socket, game, :discarded)

        # Discarding with an empty deck results in a draw game
        {:declared_draw, game} ->
          optionally_enqueue_bot_roll(game, socket)
          update_game(socket, game, :draw)
      end

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

    game = Game.draw_discard(game, current_user_seatno, new_exposed, tile)

    socket = update_game(socket, game, :drew_discard, %{tile: tile})

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
    game = Game.pong(socket.assigns.game, current_user_seatno, new_exposed, tile)
    socket = update_game(socket, game, :ponged, %{tile: tile})

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
      |> Game.update_concealed(current_user_seatno, new_concealed)
      |> Game.clear_peektile(current_user_seatno)

    socket = update_game(socket, game, :kept_peektile, %{local_only: true})

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
      |> Game.update_hiddengongs(current_user_seatno, new_hiddengongs)
      |> Game.clear_peektile(current_user_seatno)

    socket = update_game(socket, game, :hiddengonged_tile)

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
      |> Game.update_concealed(current_user_seatno, new_concealed)
      |> Game.update_exposed(current_user_seatno, new_exposed)

    socket = update_game(socket, game, :exposed_tile, %{tile: tile})

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
      |> Game.update_concealed(current_user_seatno, new_concealed)
      |> Game.update_exposed(current_user_seatno, new_exposed)

    socket = update_game(socket, game, :unexposed_tile)

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
      |> Game.update_hiddengongs(current_user_seatno, new_hiddengongs)
      |> Game.update_concealed(current_user_seatno, new_concealed)

    socket = update_game(socket, game, :hiddengonged_tile)

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
      Game.update_hiddengongs(socket.assigns.game, current_user_seat.seatno, new_hiddengongs)

    local_only = game_state != :win_declared || !Seat.win_expose?(current_user_seat)
    socket = update_game(socket, game, :hiddengongs_sorted, %{local_only: local_only})

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
      |> Game.update_concealed(current_user_seatno, new_concealed)
      |> Game.update_hiddengongs(current_user_seatno, new_hiddengongs)

    socket = update_game(socket, game, :unhiddengonged_tile)

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
      |> Game.update_hiddengongs(current_user_seatno, new_hiddengongs)
      |> Game.update_exposed(current_user_seatno, new_exposed)

    socket = update_game(socket, game, :exposed_hiddengong_tile)

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
      |> Game.update_exposed(current_user_seatno, new_exposed)
      |> Game.update_hiddengongs(current_user_seatno, new_hiddengongs)

    socket = update_game(socket, game, :hiddengonged_exposed_tile)

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
    current_user_seatno = socket.assigns.current_user_seatno

    {game, tile} =
      Game.draw_correction_tile(socket.assigns.game, current_user_seatno, new_concealed)

    socket = update_game(socket, game, :drew_correction_tile, %{tile: tile})

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
    game = Game.declare_win_from_hand(socket.assigns.game, current_user_seatno, tile)
    socket = update_game(socket, game, :declared_win, %{tile: tile})

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
    game = Game.declare_win_from_discards(socket.assigns.game, current_user_seatno, tile)
    socket = update_game(socket, game, :declared_win, %{tile: tile})

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
    game_uuid = socket.assigns.game.uuid
    path = ~p"/games/#{game_uuid}"
    socket = push_navigate(socket, to: path)

    {:noreply, socket}
  end

  # DQ declared winner
  @impl true
  def handle_event("dqdeclared", _params, socket) do
    dqseatno = socket.assigns.win_declared_seatno
    dqseat = socket.assigns.game.seats |> Enum.at(dqseatno)

    game =
      socket.assigns.game
      |> Game.dq(dqseatno)
      |> optionally_enqueue_bot_roll(socket)

    socket = update_game(socket, game, :dq, %{dqseat: dqseat})

    {:noreply, socket}
  end

  # Confirm another player's declared win
  @impl true
  def handle_event("confirm_win", _params, socket) do
    current_user_seatno = socket.assigns.current_user_seatno

    game =
      socket.assigns.game
      |> Game.confirm_win(current_user_seatno)
      |> optionally_enqueue_bot_roll(socket)

    socket = update_game(socket, game, :confirmed_win)

    {:noreply, socket}
  end

  # Expose loser hand
  @impl true
  def handle_event("expose", _params, socket) do
    game = Game.expose_loser_hand(socket.assigns.game, socket.assigns.current_user_seatno)
    socket = update_game(socket, game, :exposed_loser_hand)

    {:noreply, socket}
  end

  # Reset game
  @impl true
  def handle_event("reset", _params, socket) do
    game =
      socket.assigns.game
      |> Game.reset()
      |> optionally_enqueue_bot_roll(socket)

    socket = update_game(socket, game, :reset)

    {:noreply, socket}
  end

  # Declare draw game
  @impl true
  def handle_event("draw", _params, socket) do
    game =
      socket.assigns.game
      |> Game.draw()
      |> optionally_enqueue_bot_roll(socket)

    socket = update_game(socket, game, :draw)

    {:noreply, socket}
  end

  # DQ a player
  @impl true
  def handle_event("dq", %{"seatno" => dqseatno}, socket) do
    dqseatno = String.to_integer(dqseatno)
    dqseat = Enum.at(socket.assigns.game.seats, dqseatno)

    game =
      socket.assigns.game
      |> Game.dq(dqseatno)
      |> optionally_enqueue_bot_roll(socket)

    socket = update_game(socket, game, :dq, %{dqseat: dqseat})

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
      |> Game.boot(booted_seatno)

    if Game.has_human_players?(game) do
      game = MjwWeb.GameStore.update_with_lobby_change(game, :booted, event_details)

      socket =
        socket
        |> assign_event(:booted, event_details)
        |> assign_game_info(game)

      {:noreply, socket}
    else
      MjwWeb.GameStore.remove(game)
      {:noreply, push_navigate(socket, to: ~p"/")}
    end
  end

  # Sit down
  @impl true
  def handle_event(
        "accept_seat_offering",
        %{"player_name" => player_name},
        socket
      ) do
    player_id = socket.assigns.current_user_id
    game = Game.seat_player(socket.assigns.game, player_id, player_name)
    seat = Game.seat(game, player_id)
    MjwWeb.GameStore.update_with_lobby_change(game, :player_seated, %{seat: seat})

    socket =
      socket
      |> assign_event(:player_seated, %{seat: seat})
      |> assign_game_info(game)

    # A player joining mid-game might trigger bot actions
    optionally_enqueue_all_bot_actions(game, socket)

    {:noreply, socket}
  end

  # Pick a wind tile
  @impl true
  def handle_event("windpick", %{"picked-wind-idx" => picked_wind_idx}, socket) do
    picked_wind_idx = String.to_integer(picked_wind_idx)

    game =
      socket.assigns.game
      |> Game.pick_random_available_wind(socket.assigns.current_user_seatno, picked_wind_idx)
      |> optionally_enqueue_bot_roll(socket)

    socket = update_game(socket, game, :picked_wind)

    {:noreply, socket}
  end

  @impl true
  def handle_event("roll", _params, socket)
      when socket.assigns.game_state == :rolling_for_first_dealer do
    game =
      socket.assigns.game
      |> Game.roll_dice_and_reseat_players()
      |> optionally_enqueue_bot_roll(socket)

    socket = update_game(socket, game, :rolled_for_first_dealer)
    {:noreply, socket}
  end

  @impl true
  def handle_event("roll", _params, socket)
      when socket.assigns.game_state == :rolling_for_deal do
    game =
      socket.assigns.game
      |> Game.roll_dice_and_deal()
      |> optionally_enqueue_bot_draw(socket)

    socket = update_game(socket, game, :rolled_for_deal)
    {:noreply, socket}
  end

  defp optionally_enqueue_all_bot_actions(%Mjw.Games.Game{} = game, socket)
       when socket.assigns.bots_present do
    optionally_enqueue_all_bot_actions(game)
  end

  defp optionally_enqueue_all_bot_actions(%Mjw.Games.Game{} = game, _socket), do: game

  defp optionally_enqueue_all_bot_actions(%Mjw.Games.Game{} = game) do
    game
    |> optionally_enqueue_bot_roll()
    |> optionally_enqueue_bot_try_win_out_of_turn()
    |> optionally_enqueue_bot_draw()
    |> optionally_enqueue_bot_discard()
  end

  defp optionally_enqueue_bot_draw(%Mjw.Games.Game{} = game, socket)
       when socket.assigns.bots_present do
    optionally_enqueue_bot_draw(game)
  end

  defp optionally_enqueue_bot_draw(%Mjw.Games.Game{} = game, _socket), do: game

  defp optionally_enqueue_bot_draw(%Mjw.Games.Game{} = game) do
    MjwWeb.BotService.optionally_enqueue_draw(game)
  end

  defp optionally_enqueue_bot_try_win_out_of_turn(%Mjw.Games.Game{} = game, socket)
       when socket.assigns.bots_present do
    optionally_enqueue_bot_try_win_out_of_turn(game)
  end

  defp optionally_enqueue_bot_try_win_out_of_turn(%Mjw.Games.Game{} = game, _socket), do: game

  defp optionally_enqueue_bot_try_win_out_of_turn(%Mjw.Games.Game{} = game) do
    MjwWeb.BotService.optionally_enqueue_try_win_out_of_turn(game)
  end

  defp optionally_enqueue_bot_discard(%Mjw.Games.Game{} = game) do
    MjwWeb.BotService.optionally_enqueue_discard(game)
  end

  defp optionally_enqueue_bot_roll(%Mjw.Games.Game{} = game, socket)
       when socket.assigns.bots_present do
    optionally_enqueue_bot_roll(game)
  end

  defp optionally_enqueue_bot_roll(%Mjw.Games.Game{} = game, _socket), do: game

  defp optionally_enqueue_bot_roll(%Mjw.Games.Game{} = game) do
    MjwWeb.BotService.optionally_enqueue_roll(game)
  end

  defp game_not_found_redirect(socket) do
    socket
    |> put_flash(:error, "That game ID does not exist.")
    |> push_navigate(to: ~p"/")
  end

  defp subscribe_to_game_updates(socket) do
    if connected?(socket), do: MjwWeb.GameStore.subscribe_to_game_updates(socket.assigns.game)
    socket
  end

  defp assign_game_info(socket, %Mjw.Games.Game{} = game) do
    current_user_id = socket.assigns.current_user_id
    event = socket.assigns.event
    event_details = socket.assigns.event_details
    show_wind_picking_was = socket.assigns[:show_wind_picking]

    current_user_seatno = Game.sitting_at(game, current_user_id)
    game_state = GameState.state(game)
    last_discarded_seatno = Game.last_discarded_seatno(game)

    win_declared_seatno =
      if game_state == :win_declared, do: game |> Game.win_declared_seatno()

    # seats ordered by their position to the current player (0 = self, etc.).
    # Extra attributes added for convenience or LiveView diff optimization:
    # seatno (get original index in seats), win_expose
    relative_game_seats =
      0..3
      |> Enum.map(fn i ->
        Game.seat_with_relative_position(game, i, current_user_seatno || 0)
      end)
      |> Enum.with_index()
      |> Enum.sort_by(fn {{_seat, relative_position}, _i} -> relative_position end)
      |> Enum.map(fn {{seat, _relative_position}, i} ->
        Map.merge(seat, %{
          seatno: i,
          win_expose: win_declared_seatno && Seat.win_expose?(seat)
        })
      end)

    current_user_seat = Enum.at(relative_game_seats, 0)

    winds_have_been_picked = game_state not in [:waiting_for_players, :picking_winds]

    show_wind_picking =
      game_state in [:picking_winds, :rolling_for_first_dealer] ||
        (game_state in [:rolling_for_deal, :discarding] && show_wind_picking_was)

    rolling_dice = game_state in [:rolling_for_first_dealer, :rolling_for_deal]

    show_wall = !winds_have_been_picked || rolling_dice

    rolled_dice = event in [:rolled_for_first_dealer, :rolled_for_deal]

    player_seats_finalized = winds_have_been_picked && game_state != :rolling_for_first_dealer

    dq_confetti = event == :dq
    win_confetti = !dq_confetti && win_declared_seatno

    current_user_drawing =
      !win_declared_seatno && game_state == :drawing &&
        game.turn_seatno == current_user_seatno

    discarded_by_relative_seatno =
      if last_discarded_seatno && !win_declared_seatno && game_state == :drawing do
        Enum.find_index(relative_game_seats, &(&1.seatno == last_discarded_seatno))
      end

    # because of pongs, discards are available to everyone except the player
    # who discarded
    available_discard_tile =
      if discarded_by_relative_seatno && discarded_by_relative_seatno != 0 do
        Enum.at(game.discards, 0)
      end

    current_user_discarding =
      !win_declared_seatno &&
        game_state == :discarding && game.turn_seatno == current_user_seatno

    show_correction_tile =
      player_seats_finalized && !win_declared_seatno &&
        !current_user_drawing && might_have_gongs?(current_user_seat)

    non_discard_glow_tile = non_discard_glow_tile(event, event_details, current_user_seatno)

    drew_from_discards_tile = drew_from_discards_tile(event, event_details, current_user_seatno)

    exposed_tile = exposed_tile(event, event_details, current_user_seatno)

    drew_from_deck_relative_seatno =
      relative_seatno_for_event(:drew_from_deck, event, event_details, relative_game_seats)

    zimo_relative_seatno =
      relative_seatno_for_event(:zimo, event, event_details, relative_game_seats)

    turn_glow_seatno = unless win_declared_seatno, do: game.turn_seatno

    socket
    |> assign(%{
      game: game,
      current_user_seatno: current_user_seatno,
      game_state: game_state,
      relative_game_seats: relative_game_seats,
      current_user_seat: current_user_seat,
      winds_have_been_picked: winds_have_been_picked,
      show_wind_picking: show_wind_picking,
      rolling_dice: rolling_dice,
      show_wall: show_wall,
      rolled_dice: rolled_dice,
      player_seats_finalized: player_seats_finalized,
      win_declared_seatno: win_declared_seatno,
      dq_confetti: dq_confetti,
      win_confetti: win_confetti,
      current_user_drawing: current_user_drawing,
      available_discard_tile: available_discard_tile,
      discarded_by_relative_seatno: discarded_by_relative_seatno,
      current_user_discarding: current_user_discarding,
      show_correction_tile: show_correction_tile,
      non_discard_glow_tile: non_discard_glow_tile,
      drew_from_discards_tile: drew_from_discards_tile,
      exposed_tile: exposed_tile,
      drew_from_deck_relative_seatno: drew_from_deck_relative_seatno,
      zimo_relative_seatno: zimo_relative_seatno,
      turn_glow_seatno: turn_glow_seatno,
      deck_remaining: length(game.deck),
      empty_seats_count: Game.empty_seats_count(game),
      turn_player_name: Game.turn_player_name(game),
      current_user_can_undo: Game.can_undo?(game, current_user_seatno),
      bots_present: Game.bots_present?(game)
    })
  end

  defp unjoinable_game_redirect(socket) do
    socket
    |> put_flash(:error, "Sorry, that game is full.")
    |> push_navigate(to: ~p"/")
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

  defp might_have_gongs?(%Mjw.Games.Seat{exposed: exposed, hiddengongs: hiddengongs}) do
    length(exposed) >= 4 || length(hiddengongs) >= 4
  end

  defp might_have_gongs?(_empty_seat), do: false

  # :local_only is used to update the local assigns without persisting the
  # game. This avoids sending private events like sorting one's own concealed
  # tiles to other players, which reduces network traffic and avoids race
  # conditions when everyone is sorting their tiles at the same time.
  defp update_game(socket, game, event, event_details \\ %{}) do
    current_user_seat = socket.assigns.current_user_seat
    local_only = Map.get(event_details, :local_only)

    event_details =
      event_details
      |> Map.delete(:local_only)
      |> Map.merge(%{seat: current_user_seat})

    unless local_only, do: MjwWeb.GameStore.update(game, event, event_details)

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
  defp merge_updated_game(%Mjw.Games.Game{} = game, _socket, event)
       when event in @events_that_change_other_players_seats,
       do: game

  # No player can update another player's seat, aside for the exceptions noted
  # above. Therefore, when merging any game changes from other players we can
  # typically keep the current_user_seat as-is. This allows players to sort
  # their concealed tiles independently of other players' actions.
  defp merge_updated_game(%Mjw.Games.Game{} = game, socket, _event) do
    # current_user_seat on the client
    client_seat = socket.assigns.current_user_seat
    seatno = client_seat.seatno
    # current_user_seat on the server, the authoritive source
    server_seat = Enum.at(game.seats, seatno)
    merged_seat = Seat.merge_server_client_seats(server_seat, client_seat)

    Game.replace_seat(game, seatno, merged_seat)
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

  defp non_discard_glow_tile(event, %{seat: seat, tile: event_tile}, current_user_seatno) do
    event_seatno = Map.get(seat, :seatno)

    if (event_seatno == current_user_seatno && event in @current_player_glow_tile_events) ||
         (event_seatno != current_user_seatno && event in @other_player_glow_tile_events) do
      event_tile
    end
  end

  defp non_discard_glow_tile(_event, _event_details, _current_user_seatno), do: nil

  defp drew_from_discards_tile(
         event,
         %{seat: seat, tile: event_tile},
         current_user_seatno
       )
       when event in [:drew_from_discards_tile, :ponged] do
    event_seatno = Map.get(seat, :seatno)
    if event_seatno != current_user_seatno, do: event_tile
  end

  defp drew_from_discards_tile(_event, _event_details, _current_user_seatno), do: nil

  defp exposed_tile(
         :exposed_tile,
         %{seat: seat, tile: event_tile},
         current_user_seatno
       ) do
    event_seatno = Map.get(seat, :seatno)
    if event_seatno != current_user_seatno, do: event_tile
  end

  defp exposed_tile(_event, _event_details, _current_user_seatno), do: nil

  defp relative_seatno_for_event(
         event,
         event,
         %{seat: event_seat},
         relative_game_seats
       ) do
    event_seatno = Map.get(event_seat, :seatno)

    if event_seatno do
      Enum.find_index(relative_game_seats, &(&1.seatno == event_seatno))
    end
  end

  defp relative_seatno_for_event(_for_event, _event, _event_details, _relative_game_seats),
    do: nil
end
