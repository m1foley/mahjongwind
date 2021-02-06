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
             |> Enum.map(fn w -> Enum.map(0..3, fn i -> "#{w}-#{i}" end) end)
             |> List.flatten()

  @four_empty_seats 0..3 |> Enum.map(fn _ -> %Mjw.Seat{} end)

  defstruct id: nil,
            deck: [],
            discards: [],
            wind: "we",
            # Seats sorted in standard wind order going counter-clockwise.
            # Index 0 = first dealer, possessor of the special stick.
            seats: @four_empty_seats,
            dice: [],
            # rolling/drawing/discarding. Different from state/1.
            turn_state: :rolling,
            turn_seat_idx: 0

  @doc """
  Initialize a game with a random ID and a shuffled deck
  """
  def new do
    %__MODULE__{
      id: UUID.uuid4(),
      deck: Enum.shuffle(@all_tiles)
    }
  end

  def empty?(%__MODULE__{seats: seats}) do
    seats |> Enum.all?(&Mjw.Seat.empty?/1)
  end

  def empty_seats_count(%__MODULE__{seats: seats}) do
    seats |> Enum.count(&Mjw.Seat.empty?/1)
  end

  @doc """
  Seat number of the given player_id, or nil if not found.
  """
  def sitting_at(%__MODULE__{seats: seats}, player_id) do
    seats
    |> Enum.find_index(&(&1.player_id == player_id))
  end

  @doc """
  Seat of the given player_id, or nil if not found.
  """
  def seat(%__MODULE__{seats: seats}, player_id) do
    seats
    |> Enum.find(&(&1.player_id == player_id))
  end

  @doc """
  Add a player to the first empty seat
  """
  def seat_player(%__MODULE__{} = game, player_id, player_name) do
    empty_seat_idx = game.seats |> Enum.find_index(&Mjw.Seat.empty?/1)

    update_seat(game, empty_seat_idx, fn seat ->
      seat
      |> Mjw.Seat.seat_player(player_id, player_name)
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
    @wind_tiles
    |> Map.new(fn wind ->
      player_name =
        seats
        |> Enum.find_value(fn seat ->
          if seat.picked_wind == wind, do: seat.player_name
        end)

      {wind, player_name}
    end)
  end

  defp remaining_winds_to_pick(%__MODULE__{seats: seats}) do
    @wind_tiles -- Enum.map(seats, & &1.picked_wind)
  end

  @doc """
  Pick a random available wind tile and assign it to the player's seat
  """
  def pick_random_available_wind(game, player_id, picked_wind_idx) do
    remaining_winds = game |> remaining_winds_to_pick()
    pick_random_wind(game, player_id, picked_wind_idx, remaining_winds)
  end

  defp pick_random_wind(game, _player_id, _picked_wind_idx, []), do: game

  defp pick_random_wind(game, player_id, picked_wind_idx, winds) do
    wind = winds |> Enum.random()
    seatno = game |> sitting_at(player_id)

    update_seat(game, seatno, fn seat ->
      seat
      |> Mjw.Seat.pick_wind(wind, picked_wind_idx)
    end)
  end

  defp update_seat(game, seatno, update_function) do
    Map.update!(game, :seats, fn seats ->
      seats
      |> List.update_at(seatno, update_function)
    end)
  end

  @doc """
  Return the wind tile picked by the player. nil if player not found or their
  wind was not picked yet.
  """
  def picked_wind(game, player_id) do
    game.seats
    |> Enum.find_value(fn seat ->
      if seat.player_id == player_id, do: seat.picked_wind
    end)
  end

  @doc """
  The picked wind index for the player, which represents the placement of the
  tiles when they were picked. It's only used trivially for display purposes.
  """
  def picked_wind_idx(game, player_id) do
    game.seats
    |> Enum.find_value(fn seat ->
      if seat.player_id == player_id, do: seat.picked_wind_idx
    end)
  end

  def roll_dice(game) do
    # 1..3
    # |> Enum.map(fn _ -> 1..6 |> Enum.random() end)

    # TODO temporarily hardcoded
    dice = [[3, 6, 4], [6, 3, 4], [3, 3, 3], [1, 2, 2]] |> Enum.random()

    %{game | dice: dice}
  end

  @doc """
  Reseat the players according to the first dealer roll and the picked winds.
  The first dealer (possessor of the special stick) will be in seat index 0.
  """
  def reseat_players(game) do
    first_dealer_picked_wind =
      game
      |> dice_total()
      |> dealer_roll_cardinal_destination()

    new_seats =
      Enum.map(0..3, fn i ->
        picked_wind =
          first_dealer_picked_wind
          |> cycle_wind(i)

        game |> find_picked_wind_seat(picked_wind)
      end)

    %{game | seats: new_seats}
  end

  # The cardinal direction the seat represents upon rolling for first dealer.
  # The player rolling for first dealer (who picked East) is temporarily in the
  # first dealer seat (index 0) and this roll determines who will be in the
  # "real" first dealer seat once the players are reseated.
  defp dealer_roll_cardinal_destination(roll_total) do
    @wind_tiles
    |> Enum.at(rem(roll_total - 1, 4))
  end

  @doc """
  The seat that has the given picked_wind
  """
  def find_picked_wind_seat(%__MODULE__{seats: seats}, wind) do
    seats
    |> Enum.find(&(&1.picked_wind == wind))
  end

  defp find_picked_wind_seat_index(%__MODULE__{seats: seats}, wind) do
    seats
    |> Enum.find_index(&(&1.picked_wind == wind))
  end

  defp dice_total(%__MODULE__{dice: dice}) do
    dice |> Enum.sum()
  end

  # Cycle through the wind order (E, S, W, N) a given number of times starting
  # at the given wind
  defp cycle_wind(wind, 0), do: wind

  defp cycle_wind(wind, count) do
    start_idx =
      @wind_tiles
      |> Enum.find_index(&(&1 == wind))

    @wind_tiles
    |> Enum.at(rem(start_idx + count, 4))
  end

  @doc """
  Deal the deck. The dealer will have 14 tiles and others will have 13.
  Change turn_state to discarding.
  """
  def deal(%__MODULE__{} = game) do
    new_seats =
      game.seats
      |> Enum.with_index()
      |> Enum.map(fn {seat, seatno} ->
        tiles_start = 13 * seatno
        tiles = game.deck |> Enum.slice(tiles_start, 13)

        tiles =
          if seatno == game.turn_seat_idx do
            extra_dealer_tile = game.deck |> Enum.at(52)
            [extra_dealer_tile | tiles]
          else
            tiles
          end

        %{seat | concealed: tiles}
      end)

    new_deck = game.deck |> Enum.slice(53..-1)

    %{
      game
      | seats: new_seats,
        deck: new_deck,
        turn_state: :discarding
    }
  end

  @doc """
  The seat of the person currently rolling the dice, and their relative seat
  position to the current player
  """
  def roller_seat_with_relative_position(%__MODULE__{} = game, game_state, relative_to_seat_idx) do
    roller_seat_idx = roller_seat_idx(game, game_state)
    seat_with_relative_position(game, roller_seat_idx, relative_to_seat_idx)
  end

  defp roller_seat_idx(%__MODULE__{} = game, :rolling_for_first_dealer) do
    game |> find_picked_wind_seat_index("we")
  end

  defp roller_seat_idx(%__MODULE__{turn_seat_idx: turn_seat_idx}, _game_state) do
    turn_seat_idx
  end

  @doc """
  The seat at the given index, and its relative position to the current player
  (see relative_position/2)
  """
  def seat_with_relative_position(%__MODULE__{seats: seats}, seat_idx, relative_to_seat_idx) do
    seat = seats |> Enum.at(seat_idx)
    relative_position = relative_position(seat_idx, relative_to_seat_idx)
    {seat, relative_position}
  end

  # Where a seat appears relative to the player:
  # 0 = self, 1 = right, 2 = across, 3 = left
  defp relative_position(seat_idx, relative_to_seat_idx) do
    rem(rem(4 - relative_to_seat_idx, 4) + seat_idx, 4)
  end

  @doc """
  A player discards a tile: add to discards, remove from player's hand,
  increment turn_seat_idx & turn_state.
  """
  def discard(%__MODULE__{turn_state: :discarding} = game, seatno, tile) do
    new_discards = [tile | game.discards]
    new_turn_seat_idx = increment_turn_seat_idx(game.turn_seat_idx)

    new_concealed =
      game.seats
      |> Enum.at(seatno)
      |> Map.get(:concealed)
      |> List.delete(tile)

    game
    |> update_concealed(seatno, new_concealed)
    |> Map.merge(%{
      discards: new_discards,
      turn_state: :drawing,
      turn_seat_idx: new_turn_seat_idx
    })
  end

  defp increment_turn_seat_idx(turn_seat_idx) do
    rem(turn_seat_idx + 1, 4)
  end

  @doc """
  Update the given player's concealed tiles
  """
  def update_concealed(%__MODULE__{} = game, seatno, concealed) do
    update_seat(game, seatno, fn seat ->
      %{seat | concealed: concealed}
    end)
  end

  @doc """
  A player draws from the discards: remove from the discards, update the
  player's concealed tiles (already calculated on frontend), update turn_state
  """
  def draw_discard(%__MODULE__{turn_state: :drawing} = game, seatno, new_concealed) do
    new_discards = game.discards |> Enum.slice(1..-1)

    game
    |> update_concealed(seatno, new_concealed)
    |> Map.merge(%{discards: new_discards, turn_state: :discarding})
  end

  @doc """
  The name of the player whose turn it is
  """
  def turn_player_name(%__MODULE__{} = game) do
    player_name_at(game, game.turn_seat_idx)
  end

  defp player_name_at(%__MODULE__{seats: seats}, seatno) do
    seats |> Enum.at(seatno) |> Map.get(:player_name) || ""
  end

  @doc """
  Calculate the state of a game
  """
  def state(%__MODULE__{} = game) do
    {game, :tbd}
    |> state_waiting_for_players
    |> state_picking_winds
    |> state_rolling_for_first_dealer
    |> state_rolling_for_deal
    |> state_drawing
    |> state_discarding
    # |> state_win
    # |> state_draw
    # |> state_dq
    |> state_invalid
  end

  defp state_waiting_for_players({game, :tbd}) do
    if empty_seats_count(game) > 0 do
      {game, :waiting_for_players}
    else
      {game, :tbd}
    end
  end

  defp state_waiting_for_players({game, state}), do: {game, state}

  defp state_picking_winds({game, :tbd}) do
    if !Enum.empty?(remaining_winds_to_pick(game)) do
      {game, :picking_winds}
    else
      {game, :tbd}
    end
  end

  defp state_picking_winds({game, state}), do: {game, state}

  defp state_rolling_for_first_dealer({game, :tbd}) do
    if Enum.empty?(game.dice) do
      {game, :rolling_for_first_dealer}
    else
      {game, :tbd}
    end
  end

  defp state_rolling_for_first_dealer({game, state}), do: {game, state}

  defp state_rolling_for_deal({game, :tbd}) do
    if game.turn_state == :rolling do
      {game, :rolling_for_deal}
    else
      {game, :tbd}
    end
  end

  defp state_rolling_for_deal({game, state}), do: {game, state}

  defp state_drawing({game, :tbd}) do
    if game.turn_state == :drawing do
      {game, :drawing}
    else
      {game, :tbd}
    end
  end

  defp state_drawing({game, state}), do: {game, state}

  defp state_discarding({game, :tbd}) do
    if game.turn_state == :discarding do
      {game, :discarding}
    else
      {game, :tbd}
    end
  end

  defp state_discarding({game, state}), do: {game, state}

  defp state_invalid({_game, :tbd}), do: :invalid
  defp state_invalid({_game, state}), do: state
end
