defmodule Mjw.Game do
  @all_tiles ~w(
    🀀 🀁 🀂 🀃 🀄 🀅 🀆 🀇 🀈 🀉 🀊 🀋 🀌 🀍 🀎 🀏 🀐 🀑 🀒 🀓 🀔 🀕 🀖 🀗 🀘 🀙 🀚 🀛 🀜 🀝 🀞 🀟 🀠 🀡
    🀀 🀁 🀂 🀃 🀄 🀅 🀆 🀇 🀈 🀉 🀊 🀋 🀌 🀍 🀎 🀏 🀐 🀑 🀒 🀓 🀔 🀕 🀖 🀗 🀘 🀙 🀚 🀛 🀜 🀝 🀞 🀟 🀠 🀡
    🀀 🀁 🀂 🀃 🀄 🀅 🀆 🀇 🀈 🀉 🀊 🀋 🀌 🀍 🀎 🀏 🀐 🀑 🀒 🀓 🀔 🀕 🀖 🀗 🀘 🀙 🀚 🀛 🀜 🀝 🀞 🀟 🀠 🀡
    🀀 🀁 🀂 🀃 🀄 🀅 🀆 🀇 🀈 🀉 🀊 🀋 🀌 🀍 🀎 🀏 🀐 🀑 🀒 🀓 🀔 🀕 🀖 🀗 🀘 🀙 🀚 🀛 🀜 🀝 🀞 🀟 🀠 🀡
  )
  @four_empty_seats 0..3 |> Enum.map(fn _ -> %Mjw.Seat{} end)
  @wind_tiles ~w(🀀 🀁 🀂 🀃)

  defstruct id: nil,
            deck: [],
            discards: [],
            wind: "🀀",
            # Seats sorted in standard wind order. Index 0 = first dealer,
            # possessor of the special stick.
            seats: @four_empty_seats,
            dice: [],
            # :rolling/:drawing/:discarding
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
    # TODO temporarily hardcoded
    # dice = Mjw.Die.roll_three()
    dice =
      1..3
      |> Enum.map(fn _ -> %Mjw.Die{value: 3, unicode: "⚂"} end)

    game |> Map.merge(%{dice: dice})
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

        game
        |> find_picked_wind_seat(picked_wind)
      end)

    game |> Map.merge(%{seats: new_seats})
  end

  # If the dealer (i.e., the player in the east) rolls dice, the cardinal
  # direction of the seat the roll represents
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

  defp dice_total(%__MODULE__{dice: dice}) do
    dice |> Mjw.Die.sum()
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

  # TODO
  def deal(game) do
    new_seats =
      game.seats
      |> Enum.map(fn seat ->
        seat |> Map.merge(%{covered: [0]})
      end)

    game
    |> Map.merge(%{
      seats: new_seats,
      turn_state: :discarding
    })
  end

  @doc """
  The seat whose turn it is
  """
  def turn_seat(%__MODULE__{seats: seats, turn_seat_idx: turn_seat_idx}) do
    seats |> Enum.at(turn_seat_idx)
  end

  @doc """
  Calculate the state of a game
  """
  def state(game) do
    {game, :tbd}
    |> state_waiting_for_players
    |> state_picking_winds
    |> state_rolling_for_first_dealer
    |> state_rolling_for_deal
    |> state_drawing
    |> state_discarding
    # |> state_draw
    # |> state_win
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
