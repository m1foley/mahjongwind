defmodule Mjw.Game do
  @bamboo_tiles ~w(b1 b2 b3 b4 b5 b6 b7 b8 b9)
  @circle_tiles ~w(c1 c2 c3 c4 c5 c6 c7 c8 c9)
  @number_tiles ~w(n1 n2 n3 n4 n5 n6 n7 n8 n9)
  # fa, plate, zhong
  @dragon_tiles ~w(df dp dz)
  # winds sorted in standard wind order
  @wind_tiles ~w(we ws ww wn)
  # numbered suffixes are added to give each tile in the deck a unique ID.
  # e.g., the four plate tiles are: dp-0, dp-1, dp-2, dp-3
  @all_tiles (@bamboo_tiles ++ @circle_tiles ++ @number_tiles ++ @dragon_tiles ++ @wind_tiles)
             |> Enum.map(fn base -> Enum.map(0..3, fn i -> "#{base}-#{i}" end) end)
             |> List.flatten()
  @four_empty_seats 0..3 |> Enum.map(fn _ -> %Mjw.Seat{} end)
  @bot_names [
    "Dragonfruit 🤖",
    "Goji 🤖",
    "Guava 🤖",
    "Lian Wu 🤖",
    "Lychee 🤖",
    "Papaya 🤖",
    "Passionfruit 🤖",
    "Persimmon 🤖",
    "Pomelo 🤖",
    "Taro 🤖"
  ]

  defstruct id: nil,
            deck: [],
            discards: [],
            wind: "we",
            # Seats sorted in standard wind order going counter-clockwise.
            # Index 0 = first dealer, possessor of the special stick.
            seats: @four_empty_seats,
            dice: [],
            # The normal game states: rolling/drawing/discarding.
            # Different from state/1, of which this is just one element.
            turn_state: :rolling,
            dealer_seatno: 0,
            turn_seatno: 0,
            # Where the deal picking started from. Might be used to count points.
            dealpick_seatno: 0,
            # Number of times the player has been dealer (draws, etc, also count)
            dealer_win_count: 0,
            event_log: [],
            undo_seatno: nil,
            undo_state: nil,
            pause_bots: false

  @doc """
  Initialize a game, defaulting to a random ID and a shuffled deck
  """
  def new(id \\ Uniq.UUID.uuid4()) do
    %__MODULE__{id: id, deck: shuffled_deck()}
  end

  defp shuffled_deck() do
    Enum.shuffle(@all_tiles)
  end

  def empty?(%__MODULE__{seats: seats}) do
    Enum.all?(seats, &Mjw.Seat.empty?/1)
  end

  def empty_seats_count(%__MODULE__{seats: seats}) do
    Enum.count(seats, &Mjw.Seat.empty?/1)
  end

  @doc """
  Seat number of the given player_id, or nil if not found.
  """
  def sitting_at(%__MODULE__{seats: seats}, player_id) do
    Enum.find_index(seats, &(&1.player_id == player_id))
  end

  @doc """
  Seat of the given player_id, or nil if not found.
  """
  def seat(%__MODULE__{seats: seats}, player_id) do
    Enum.find(seats, &(&1.player_id == player_id))
  end

  @doc """
  Add a player to the first empty seat
  """
  def seat_player(%__MODULE__{} = game, player_id, player_name) do
    empty_seatno = Enum.find_index(game.seats, &Mjw.Seat.empty?/1)

    if empty_seatno do
      game
      |> seat_player_at(player_id, player_name, empty_seatno)
      |> log_player_joined_event(player_name)
    else
      game
    end
  end

  defp seat_player_at(%__MODULE__{} = game, player_id, player_name, seatno) do
    update_seat(game, seatno, fn seat ->
      seat |> Mjw.Seat.seat_player(player_id, player_name)
    end)
  end

  @doc """
  Names of all seated players
  """
  def seated_player_names(%__MODULE__{seats: seats}) do
    seats
    |> Enum.reject(&Mjw.Seat.empty?/1)
    |> Enum.map(& &1.player_name)
  end

  @doc """
  Convenience method that maps all winds to the players who picked them
  """
  def picked_winds_player_names(%__MODULE__{seats: seats}) do
    Map.new(@wind_tiles, fn wind ->
      player_name =
        seats
        |> Enum.find_value(fn seat ->
          if seat.picked_wind == wind, do: seat.player_name
        end)

      {wind, player_name}
    end)
  end

  def remaining_winds_to_pick(%__MODULE__{seats: seats}) do
    @wind_tiles -- Enum.map(seats, & &1.picked_wind)
  end

  @doc """
  Pick a random available wind tile and assign it to the player's seat
  """
  def pick_random_available_wind(%__MODULE__{} = game, seatno, picked_wind_idx \\ 0) do
    remaining_winds = remaining_winds_to_pick(game)

    if Enum.empty?(remaining_winds) do
      game
    else
      wind = remaining_winds |> Enum.random()
      game |> update_seat(seatno, &Mjw.Seat.pick_wind(&1, wind, picked_wind_idx))
    end
  end

  defp update_seat(%__MODULE__{} = game, seatno, update_function) do
    Map.update!(game, :seats, fn seats ->
      seats
      |> List.update_at(seatno, update_function)
    end)
  end

  @doc """
  Return the wind tile picked by the player. nil if player not found or their
  wind was not picked yet.
  """
  def picked_wind(%__MODULE__{seats: seats}, player_id) do
    Enum.find_value(seats, fn seat ->
      if seat.player_id == player_id, do: seat.picked_wind
    end)
  end

  @doc """
  The picked wind index for the player, which represents the placement of the
  tiles when they were picked. It's only used trivially for display purposes.
  """
  def picked_wind_idx(%__MODULE__{seats: seats}, player_id) do
    Enum.find_value(seats, fn seat ->
      if seat.player_id == player_id, do: seat.picked_wind_idx
    end)
  end

  @doc """
  Roll dice and reseat the players according to the first dealer roll and the
  picked winds. Sets first dealer (possessor of the special stick) in seat 0.
  """
  def roll_dice_and_reseat_players(%__MODULE__{dice: []} = game) do
    game
    |> roll_dice()
    |> reseat_players()
    |> log_first_dealer_event()
  end

  @doc """
  Roll dice and deal the deck. The dealer will have 14 tiles and others will
  have 13. Sets dealpick_seatno, changes turn_state to discarding, and sets
  undo_state to an initial value.
  """
  def roll_dice_and_deal(%__MODULE__{turn_state: :rolling} = game) do
    game
    |> roll_dice()
    |> deal()
  end

  defp roll_dice(%__MODULE__{} = game) do
    dice = Enum.map(0..2, fn _ -> Enum.random(1..6) end)
    %{game | dice: dice}
  end

  defp reseat_players(%__MODULE__{} = game) do
    first_dealer_picked_wind =
      game
      |> dice_total()
      |> dealer_roll_cardinal_destination()

    new_seats =
      Enum.map(0..3, fn i ->
        picked_wind =
          first_dealer_picked_wind
          |> cycle_wind(i)

        find_picked_wind_seat(game, picked_wind)
      end)

    %{game | seats: new_seats}
  end

  # The cardinal direction the seat represents upon rolling for first dealer.
  # The player rolling for first dealer (who picked East) is temporarily in the
  # first dealer seat (index 0) and this roll determines who will be in the
  # "real" first dealer seat once the players are reseated.
  defp dealer_roll_cardinal_destination(roll_total) do
    idx = roll_seatno(0, roll_total)
    @wind_tiles |> Enum.at(idx)
  end

  defp roll_seatno(roller_seatno, roll_total) do
    increment_seatno(roller_seatno, roll_total - 1)
  end

  @doc """
  The seat that has the given picked_wind
  """
  def find_picked_wind_seat(%__MODULE__{seats: seats}, wind) do
    Enum.find(seats, &(&1.picked_wind == wind))
  end

  defp find_picked_wind_seatno(%__MODULE__{seats: seats}, wind) do
    Enum.find_index(seats, &(&1.picked_wind == wind))
  end

  defp dice_total(%__MODULE__{dice: dice}) do
    Enum.sum(dice)
  end

  # Cycle through the wind order (E, S, W, N) a given number of times starting
  # at the given wind
  defp cycle_wind(wind, 0), do: wind

  defp cycle_wind(wind, count) do
    start_idx = Enum.find_index(@wind_tiles, &(&1 == wind))
    Enum.at(@wind_tiles, rem(start_idx + count, 4))
  end

  defp deal(%__MODULE__{} = game) do
    new_seats =
      game.seats
      |> Enum.with_index()
      |> Enum.map(fn {seat, seatno} ->
        tiles_start = 13 * seatno
        tiles = game.deck |> Enum.slice(tiles_start, 13)

        tiles =
          if seatno == game.turn_seatno do
            extra_dealer_tile = game.deck |> Enum.at(52)
            [extra_dealer_tile | tiles]
          else
            tiles
          end

        seat = %{seat | concealed: tiles}

        # only sort tiles for bots because humans like sorting their own
        if Mjw.Seat.bot?(seat) do
          Mjw.Seat.sort_concealed(seat)
        else
          seat
        end
      end)

    new_deck = Enum.drop(game.deck, 53)
    dealpick_seatno = roll_seatno(game.dealer_seatno, dice_total(game))

    %{
      game
      | seats: new_seats,
        deck: new_deck,
        turn_state: :discarding,
        dealpick_seatno: dealpick_seatno
    }
  end

  @doc """
  The seat of the person rolling the dice (currently or most recent) and their
  relative seat position to the current player
  """
  def current_or_most_recent_roller_seat_with_relative_position(
        %__MODULE__{} = game,
        game_state,
        relative_to_seatno
      ) do
    roller_seatno = current_or_most_recent_roller_seatno(game, game_state)
    seat_with_relative_position(game, roller_seatno, relative_to_seatno)
  end

  defp current_or_most_recent_roller_seatno(%__MODULE__{} = game, :rolling_for_first_dealer) do
    picked_east_wind_seatno(game)
  end

  # dealer_seatno should always equal turn_seatno when rolling for deal, so
  # either could get used
  defp current_or_most_recent_roller_seatno(
         %__MODULE__{dealer_seatno: dealer_seatno},
         _game_state
       ) do
    dealer_seatno
  end

  @doc """
  The seatno of the currently rolling player, or nil if nobody is rolling
  """
  def current_roller_seatno(%__MODULE__{} = game, game_state)
      when game_state in [:rolling_for_first_dealer, :rolling_for_deal] do
    current_or_most_recent_roller_seatno(game, game_state)
  end

  def current_roller_seatno(%__MODULE__{}, _game_state), do: nil

  # seatno of the player who picked the east wind
  defp picked_east_wind_seatno(%__MODULE__{} = game) do
    find_picked_wind_seatno(game, "we")
  end

  @doc """
  Relative seat position of the player who picked the east wind
  """
  def picked_east_wind_relative_seatno(%__MODULE__{} = game, relative_to_seatno) do
    game
    |> picked_east_wind_seatno()
    |> relative_position(relative_to_seatno)
  end

  @doc """
  The seat at the given index, and its relative position to the current player
  (see relative_position/2)
  """
  def seat_with_relative_position(%__MODULE__{seats: seats}, seatno, relative_to_seatno) do
    seat = Enum.at(seats, seatno)
    relative_position = relative_position(seatno, relative_to_seatno)
    {seat, relative_position}
  end

  # Where a seat appears relative to the player sitting in relative_to_seatno:
  # 0 = self, 1 = right, 2 = across, 3 = left
  defp relative_position(seatno, relative_to_seatno) do
    rem(rem(4 - relative_to_seatno, 4) + seatno, 4)
  end

  @doc """
  A player discards a tile from their hand
  """
  def discard(%__MODULE__{turn_state: :discarding, turn_seatno: seatno} = game, seatno, tile) do
    new_discards = [tile | game.discards]

    game
    |> set_undo_state(seatno)
    |> log_discard_event(seatno, tile)
    |> update_seat(seatno, &Mjw.Seat.remove_from_hand(&1, tile))
    |> update_seat(seatno, &Mjw.Seat.ensure_no_dangling_peektile/1)
    |> Map.merge(%{discards: new_discards, turn_state: :drawing})
    |> advance_turn_seat_or_declare_draw()
  end

  @doc """
  Discard a tile from the bot's hand
  """
  def bot_discard(%__MODULE__{turn_state: :discarding, turn_seatno: seatno} = game) do
    tile = Mjw.BotStrategy.discard(game)

    game
    |> set_undo_state_if_first_discard()
    |> log_discard_event(seatno, tile)
    |> update_seat(seatno, &Mjw.Seat.remove_from_concealed(&1, tile))
    |> Map.merge(%{discards: [tile | game.discards], turn_state: :drawing})
    |> advance_turn_seat_or_declare_draw()
  end

  defp advance_turn_seat_or_declare_draw(%__MODULE__{deck: []} = game) do
    {:declared_draw, draw(game)}
  end

  defp advance_turn_seat_or_declare_draw(%__MODULE__{} = game) do
    game = %{game | turn_seatno: increment_seatno(game.turn_seatno)}
    {:ok, game}
  end

  @doc """
  If someone just discarded, return their seat number. Otherwise nil
  """
  def last_discarded_seatno(%__MODULE__{turn_state: :drawing, turn_seatno: turn_seatno}) do
    decrement_seatno(turn_seatno)
  end

  def last_discarded_seatno(%__MODULE__{} = _game), do: nil

  defp advance_dealer(%__MODULE__{} = game) do
    dealer_seatno = increment_seatno(game.dealer_seatno)

    # the game wind changes when it gets back to the first dealer
    wind =
      if dealer_seatno == 0 do
        game.wind |> cycle_wind(1)
      else
        game.wind
      end

    game
    |> Map.merge(%{
      turn_seatno: dealer_seatno,
      dealer_seatno: dealer_seatno,
      dealer_win_count: 0,
      wind: wind
    })
  end

  defp increment_seatno(seatno, by \\ 1), do: rem(seatno + by, 4)
  defp decrement_seatno(seatno), do: rem(seatno + 3, 4)

  @doc """
  Update the given player's concealed tiles
  """
  def update_concealed(%__MODULE__{} = game, seatno, concealed) do
    update_seat(game, seatno, fn seat ->
      %{seat | concealed: concealed}
    end)
  end

  @doc """
  Update the given player's exposed tiles
  """
  def update_exposed(%__MODULE__{} = game, seatno, exposed) do
    update_seat(game, seatno, fn seat ->
      %{seat | exposed: exposed}
    end)
  end

  @doc """
  Update the given player's hidden gongs
  """
  def update_hiddengongs(%__MODULE__{} = game, seatno, hiddengongs) do
    update_seat(game, seatno, fn seat ->
      %{seat | hiddengongs: hiddengongs}
    end)
  end

  @doc """
  Confirm another player's declared win
  """
  def confirm_win(%__MODULE__{} = game, seatno) do
    game = update_seat(game, seatno, &Mjw.Seat.confirm_win/1)

    # advance the game if all players have confirmed the win
    if confirmed_win?(game) do
      dealer_advancement =
        if win_declared_seatno(game) == game.dealer_seatno do
          :same_dealer
        else
          :advance_dealer
        end

      game
      |> advance_game(dealer_advancement)
      |> log_dealer_event()
    else
      game
    end
  end

  @doc """
  Expose the player's hand to other players after a loss
  """
  def expose_loser_hand(%__MODULE__{} = game, seatno) do
    update_seat(game, seatno, &Mjw.Seat.expose_loser_hand/1)
  end

  @doc """
  Declare a win from a player's hand
  """
  def declare_win_from_hand(%__MODULE__{} = game, seatno, wintile) do
    game
    |> set_undo_state(seatno)
    |> log_declared_win_event(seatno, wintile)
    |> update_seat(seatno, &Mjw.Seat.remove_from_hand(&1, wintile))
    |> update_seat(seatno, &Mjw.Seat.ensure_no_dangling_peektile/1)
    |> Map.merge(%{turn_seatno: seatno, turn_state: :discarding})
    |> update_seat(seatno, &Mjw.Seat.declare_win(&1, wintile))
  end

  @doc """
  Declare a win from the discards
  """
  def declare_win_from_discards(
        %__MODULE__{discards: [wintile | remaining_discards]} = game,
        seatno,
        wintile
      ) do
    game
    |> set_undo_state(seatno)
    |> log_declared_win_event(seatno, wintile)
    |> Map.merge(%{turn_seatno: seatno, turn_state: :discarding, discards: remaining_discards})
    |> update_seat(seatno, &Mjw.Seat.declare_win(&1, wintile))
  end

  def bot_declare_win_from_discards(
        %__MODULE__{discards: [wintile | remaining_discards]} = game,
        seatno
      ) do
    game
    |> log_declared_win_event(seatno, wintile)
    |> Map.merge(%{turn_seatno: seatno, turn_state: :discarding, discards: remaining_discards})
    |> update_seat(seatno, &Mjw.Seat.declare_win(&1, wintile))
  end

  @doc """
  A player draws from the discards (not a pong because it was their turn)
  """
  def draw_discard(
        %__MODULE__{turn_state: :drawing, discards: [tile | remaining_discards]} = game,
        seatno,
        new_exposed,
        tile
      ) do
    game
    |> set_undo_state(seatno)
    |> log_draw_discard_event(seatno, tile)
    |> update_exposed(seatno, new_exposed)
    |> Map.merge(%{turn_state: :discarding, discards: remaining_discards})
  end

  @doc """
  A player draws from the discards when it's not their turn
  """
  def pong(
        %__MODULE__{turn_state: :drawing, discards: [tile | remaining_discards]} = game,
        seatno,
        new_exposed,
        tile
      ) do
    game
    |> set_undo_state(seatno)
    |> log_pong_event(seatno, tile)
    |> update_exposed(seatno, new_exposed)
    |> Map.merge(%{turn_seatno: seatno, turn_state: :discarding, discards: remaining_discards})
  end

  @doc """
  A player draws a gong correction tile: remove from the deck and update the
  player's concealed tiles (already calculated on frontend).
  "decktile" in the player's hand is swapped in-place with the correction tile.
  """
  def draw_correction_tile(%__MODULE__{} = game, seatno, concealed) do
    {new_deck, new_concealed, tile} = swap_concealed_deck_tile(game, concealed)

    game =
      game
      |> set_undo_state(seatno)
      |> log_drew_correction_tile_event(seatno)
      |> update_concealed(seatno, new_concealed)
      |> Map.merge(%{deck: new_deck})

    {game, tile}
  end

  defp swap_concealed_deck_tile(%__MODULE__{deck: deck}, tiles) do
    decktile_idx = Enum.find_index(tiles, &(&1 == "decktile"))

    if decktile_idx do
      # In real life this would grab from the other side of the deck. This way
      # is just more efficient.
      [next_deck_tile | remaining_deck] = deck
      new_tiles = List.replace_at(tiles, decktile_idx, next_deck_tile)
      {remaining_deck, new_tiles, next_deck_tile}
    else
      # no change (unexpected behavior)
      {deck, tiles, nil}
    end
  end

  @doc """
  The name of the player whose turn it is
  """
  def turn_player_name(%__MODULE__{} = game) do
    player_name_at(game, game.turn_seatno)
  end

  defp player_name_at(%__MODULE__{seats: seats}, seatno) do
    Enum.at(seats, seatno).player_name || ""
  end

  @doc """
  Player quits the game
  """
  def evacuate_seat(%__MODULE__{} = game, seatno) do
    player_name = player_name_at(game, seatno)

    game
    |> update_seat(seatno, &Mjw.Seat.evacuate_player/1)
    |> log_quit_event(player_name)
  end

  @doc """
  Forcibly boot player from the game
  """
  def boot(%__MODULE__{} = game, seatno) do
    player_name = player_name_at(game, seatno)

    game
    |> update_seat(seatno, &Mjw.Seat.evacuate_player/1)
    |> log_player_booted_event(player_name)
  end

  @doc """
  Reset the game, preserving only the id and player info
  """
  def reset(%__MODULE__{id: id, seats: seats}) do
    new_game_with_same_id = new(id)

    seats
    |> Enum.with_index()
    |> Enum.reduce(new_game_with_same_id, fn {seat, seatno}, game ->
      if Mjw.Seat.bot?(seat) do
        seat_bot_at(game, seat.player_name, seatno)
      else
        seat_player_at(game, seat.player_id, seat.player_name, seatno)
      end
    end)
    |> log_reset_event()
  end

  @doc """
  Declare a draw game
  """
  def draw(%__MODULE__{} = game) do
    game
    |> advance_game(:same_dealer)
    |> log_draw_event()
  end

  @doc """
  DQ the player in the given seat. Only advance the dealer if the disqualified
  player is the dealer.
  """
  def dq(%__MODULE__{} = game, seatno)
      when seatno == game.dealer_seatno do
    game
    |> advance_game(:advance_dealer)
    |> log_dq_event(seatno)
  end

  def dq(%__MODULE__{} = game, seatno) do
    game
    |> advance_game(:same_dealer)
    |> log_dq_event(seatno)
  end

  defp advance_game(%__MODULE__{} = game, dealer_advancement) do
    game =
      game
      |> clear_all_seat_tiles()
      |> Map.merge(%{
        deck: shuffled_deck(),
        discards: [],
        undo_seatno: nil,
        undo_state: nil,
        event_log: [],
        turn_state: :rolling
      })

    case dealer_advancement do
      :advance_dealer ->
        advance_dealer(game)

      :same_dealer ->
        # dealer_win_count gets incremented even on draws and DQs
        %{game | dealer_win_count: game.dealer_win_count + 1, turn_seatno: game.dealer_seatno}
    end
  end

  defp clear_all_seat_tiles(%__MODULE__{} = game) do
    Map.update!(game, :seats, fn seats ->
      Enum.map(seats, &Mjw.Seat.clear_tiles/1)
    end)
  end

  @doc """
  The seat number of the declared winner. Assumes the caller already checked
  that game state/1 is :win_declared
  """
  def win_declared_seatno(%__MODULE__{seats: seats}) do
    Enum.find_index(seats, &Mjw.Seat.declared_win?/1)
  end

  @doc """
  Return true if all players confirmed someone's declared win
  """
  def confirmed_win?(%__MODULE__{seats: seats}) do
    Enum.all?(seats, &Mjw.Seat.confirmed_win?/1)
  end

  @doc """
  Completely replace the given seatno
  """
  def replace_seat(%__MODULE__{} = game, seatno, %Mjw.Seat{} = seat) do
    update_seat(game, seatno, fn _seat_being_replaced -> seat end)
  end

  def undo(
        %__MODULE__{undo_seatno: undo_seatno, undo_state: %__MODULE__{} = undo_state} = game,
        player_seatno
      ) do
    player_name = player_name_at(game, player_seatno)

    log_event_message =
      if undo_seatno do
        "#{player_name} undid their action."
      else
        "#{player_name} reset the game."
      end

    undo_state
    # event_log is preserved as a singleton at the top-level game
    |> Map.merge(%{event_log: game.event_log})
    |> merge_seats_for_undo(game)
    # just in case undoing a declared win
    |> clear_all_seat_win_attributes()
    |> log_event(log_event_message)
  end

  # The undo player's hand will change after an undo, but try to preserve their
  # preferred tile order
  defp merge_seats_for_undo(%__MODULE__{} = undo_state, %__MODULE__{} = game) do
    seats =
      game.seats
      |> Enum.with_index()
      |> Enum.map(fn {seat, idx} ->
        if idx == game.undo_seatno do
          undo_state_seat = Enum.at(undo_state.seats, idx)
          Mjw.Seat.merge_for_undo(seat, undo_state_seat)
        else
          if Mjw.Seat.bot?(seat) do
            # bot seats can have multiple changes between undos
            Enum.at(undo_state.seats, idx)
          else
            seat
          end
        end
      end)

    %{undo_state | seats: seats}
  end

  defp clear_all_seat_win_attributes(%__MODULE__{} = game) do
    Map.update!(game, :seats, fn seats ->
      Enum.map(seats, &Mjw.Seat.clear_win_attributes/1)
    end)
  end

  @doc """
  A player can undo when they performed the last human action, OR if the
  undo_seatno is nil which indicates it's the beginning of the game and we can
  undo the initial bot discards
  """
  def can_undo?(%__MODULE__{undo_seatno: undo_seatno, undo_state: undo_state}, seatno) do
    undo_state && (!undo_seatno || undo_seatno == seatno)
  end

  @doc """
  Draw a tile from the deck, and temporarily hold it in the seat's peektile
  before deciding whether to keep or discard. Params enforce that this player
  is currently drawing.
  """
  def peek_deck_tile(
        %__MODULE__{turn_seatno: seatno, turn_state: :drawing, deck: [peektile | remaining_deck]} =
          game,
        seatno
      ) do
    game
    |> set_undo_state(seatno)
    |> log_drew_from_deck_event(seatno)
    |> update_seat(seatno, fn seat -> Mjw.Seat.peek(seat, peektile) end)
    |> Map.merge(%{deck: remaining_deck, turn_state: :discarding})
  end

  @doc """
  Keeping a peektile means just moving it to their concealed or hiddengong
  tiles, which must be done before calling clear_peektile. The params enforce
  that this is happening while the player is still discarding.
  """
  def clear_peektile(%__MODULE__{turn_seatno: seatno, turn_state: :discarding} = game, seatno) do
    update_seat(game, seatno, &Mjw.Seat.clear_peektile/1)
  end

  def bots_present?(%__MODULE__{seats: seats}) do
    Enum.any?(seats, &Mjw.Seat.bot?/1)
  end

  @doc """
  Choose & draw a tile for a bot
  """
  def bot_draw(%__MODULE__{turn_state: :drawing, turn_seatno: bot_seatno} = game) do
    case Mjw.BotStrategy.draw(game) do
      :draw_deck_tile ->
        {:draw_deck_tile, bot_draw_deck_tile(game)}

      {:draw_discard, new_concealed, new_exposed} ->
        {:draw_discard, bot_draw_discard(game, new_concealed, new_exposed)}

      :win_with_discard ->
        {:win_with_discard, bot_declare_win_from_discards(game, bot_seatno)}

      :zimo ->
        {:zimo, bot_declare_win_from_zimo(game, bot_seatno)}
    end
  end

  defp bot_draw_discard(
         %__MODULE__{
           turn_seatno: seatno,
           turn_state: :drawing,
           discards: [discarded_tile | remaining_discards]
         } = game,
         new_concealed,
         new_exposed
       ) do
    game
    |> log_draw_discard_event(seatno, discarded_tile)
    |> update_seat(seatno, fn seat ->
      %{seat | concealed: new_concealed, exposed: new_exposed}
    end)
    |> Map.merge(%{turn_state: :discarding, discards: remaining_discards})
  end

  # Draw a tile from the deck into the bot's concealed tiles.
  # Sorts the concealed tiles so it's easier to read at the end of the game.
  defp bot_draw_deck_tile(
         %__MODULE__{turn_seatno: seatno, turn_state: :drawing, deck: [tile | remaining_deck]} =
           game
       ) do
    game
    |> log_drew_from_deck_event(seatno)
    |> update_seat(seatno, fn seat ->
      seat
      |> Mjw.Seat.add_to_concealed(tile)
      |> Mjw.Seat.sort_concealed()
    end)
    |> Map.merge(%{deck: remaining_deck, turn_state: :discarding})
  end

  # Bot picks themselves to win
  defp bot_declare_win_from_zimo(%__MODULE__{deck: [tile | remaining_deck]} = game, seatno) do
    game
    |> log_zimo_event(seatno, tile)
    |> Map.merge(%{turn_seatno: seatno, turn_state: :discarding, deck: remaining_deck})
    |> update_seat(seatno, &Mjw.Seat.declare_win(&1, tile))
  end

  def bots_try_win_out_of_turn(%__MODULE__{turn_state: :drawing} = game) do
    case Mjw.BotStrategy.find_win_out_of_turn(game) do
      {:ok, seatno} -> {:ok, bot_declare_win_from_discards(game, seatno), seatno}
      :no_wins -> :no_wins
    end
  end

  defp log_discard_event(%__MODULE__{} = game, seatno, tile) do
    player_name = player_name_at(game, seatno)
    log_event(game, "#{player_name} discarded.", tile)
  end

  defp log_declared_win_event(%__MODULE__{} = game, seatno, tile) do
    player_name = player_name_at(game, seatno)
    log_event(game, "#{player_name} went out!", tile)
  end

  defp log_zimo_event(%__MODULE__{} = game, seatno, tile) do
    player_name = player_name_at(game, seatno)
    log_event(game, "#{player_name} picked themselves to win!", tile)
  end

  defp log_draw_discard_event(%__MODULE__{} = game, seatno, tile) do
    player_name = player_name_at(game, seatno)
    log_event(game, "#{player_name} drew the discarded tile.", tile)
  end

  defp log_pong_event(%__MODULE__{} = game, seatno, tile) do
    player_name = player_name_at(game, seatno)
    log_event(game, "#{player_name} ponged.", tile)
  end

  defp log_drew_correction_tile_event(%__MODULE__{} = game, seatno) do
    player_name = player_name_at(game, seatno)
    log_event(game, "#{player_name} drew a correction tile.")
  end

  defp log_drew_from_deck_event(%__MODULE__{} = game, seatno) do
    player_name = player_name_at(game, seatno)
    log_event(game, "#{player_name} drew from the deck.")
  end

  defp log_dq_event(%__MODULE__{} = game, seatno) do
    player_name = player_name_at(game, seatno)

    game
    |> log_event("#{player_name} has been disqualified.", "🙅🏻‍♀️")
    |> log_dealer_event()
  end

  defp log_first_dealer_event(%__MODULE__{} = game) do
    dealer_name = turn_player_name(game)
    log_event(game, "#{dealer_name} is the first dealer.")
  end

  defp log_dealer_event(%__MODULE__{} = game) do
    dealer_name = turn_player_name(game)

    event =
      "#{dealer_name} is the dealer" <>
        case game.dealer_win_count do
          0 -> "."
          1 -> " for the second time."
          2 -> " for the third time."
          3 -> " for the fourth time."
          4 -> " for the fifth time."
          5 -> " for the sixth time."
          6 -> " for the seventh time."
          7 -> " for the eighth time."
          8 -> " for the ninth time."
          9 -> " for the tenth time."
          dealer_win_count -> " (x#{dealer_win_count + 1})"
        end

    log_event(game, event)
  end

  defp log_player_joined_event(%__MODULE__{} = game, player_name) do
    log_event(game, "#{player_name} joined the game.")
  end

  defp log_quit_event(%__MODULE__{} = game, player_name) do
    log_event(game, "#{player_name} left the game.")
  end

  defp log_player_booted_event(%__MODULE__{} = game, player_name) do
    log_event(game, "#{player_name} was booted from the game.", "🥾")
  end

  defp log_draw_event(%__MODULE__{} = game) do
    game
    |> log_event("The game was declared a draw.", "🤝")
    |> log_dealer_event()
  end

  defp log_reset_event(%__MODULE__{} = game) do
    log_event(game, "The game was reset.")
  end

  defp log_event(%__MODULE__{} = game, event, tile \\ nil) do
    %{game | event_log: [{event, tile} | game.event_log]}
  end

  # When an undoable change is made, set the undo_state so that the player in
  # undo_seatno can possibly undo it. event_log is not saved in undo states
  # because it exists as a singleton at the top-level game.
  defp set_undo_state(%__MODULE__{} = game, undo_seatno \\ nil) do
    undo_state = game |> Map.delete(:event_log)
    %{game | undo_seatno: undo_seatno, undo_state: undo_state}
  end

  # When a bot discards first, set the initial undo_state so a human can Undo
  # to the beginning of the game to pick up a bot's discard they missed
  defp set_undo_state_if_first_discard(%__MODULE__{} = game) do
    if Enum.empty?(game.discards) do
      set_undo_state(game)
    else
      game
    end
  end

  def seat_bot(%__MODULE__{} = game) do
    empty_seatno = Enum.find_index(game.seats, &Mjw.Seat.empty?/1)

    if empty_seatno do
      bot_name = generate_bot_name(game)

      game
      |> seat_bot_at(bot_name, empty_seatno)
      |> log_player_joined_event(bot_name)
    else
      game
    end
  end

  defp seat_bot_at(%__MODULE__{} = game, bot_name, seatno) do
    game
    |> update_seat(seatno, fn seat -> Mjw.Seat.seat_bot(seat, bot_name) end)
    |> pick_random_available_wind(seatno)
  end

  defp generate_bot_name(%__MODULE__{} = game) do
    Enum.random(@bot_names -- seated_player_names(game))
  end

  def pause_bots(%__MODULE__{} = game) do
    %{game | pause_bots: true}
  end

  def resume_bots(%__MODULE__{} = game) do
    %{game | pause_bots: false}
  end
end
