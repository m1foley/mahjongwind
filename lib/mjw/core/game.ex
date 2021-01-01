defmodule Mjw.Game do
  @all_tiles ~w(
    🀀 🀁 🀂 🀃 🀄 🀅 🀆 🀇 🀈 🀉 🀊 🀋 🀌 🀍 🀎 🀏 🀐 🀑 🀒 🀓 🀔 🀕 🀖 🀗 🀘 🀙 🀚 🀛 🀜 🀝 🀞 🀟 🀠 🀡
    🀀 🀁 🀂 🀃 🀄 🀅 🀆 🀇 🀈 🀉 🀊 🀋 🀌 🀍 🀎 🀏 🀐 🀑 🀒 🀓 🀔 🀕 🀖 🀗 🀘 🀙 🀚 🀛 🀜 🀝 🀞 🀟 🀠 🀡
    🀀 🀁 🀂 🀃 🀄 🀅 🀆 🀇 🀈 🀉 🀊 🀋 🀌 🀍 🀎 🀏 🀐 🀑 🀒 🀓 🀔 🀕 🀖 🀗 🀘 🀙 🀚 🀛 🀜 🀝 🀞 🀟 🀠 🀡
    🀀 🀁 🀂 🀃 🀄 🀅 🀆 🀇 🀈 🀉 🀊 🀋 🀌 🀍 🀎 🀏 🀐 🀑 🀒 🀓 🀔 🀕 🀖 🀗 🀘 🀙 🀚 🀛 🀜 🀝 🀞 🀟 🀠 🀡
  )
  @four_empty_seats 0..3 |> Enum.map(fn _ -> %Mjw.Seat{} end)
  @wind_tiles ~w(🀀 🀁 🀂 🀃)

  defstruct id: nil, deck: [], discards: [], wind: "🀀", seats: @four_empty_seats

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
    seats |> Enum.find_index(&(&1.player_id == player_id))
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
  The wind tiles that have not yet been picked by players to start a game
  """
  def remaining_winds_to_pick(%__MODULE__{seats: seats}) do
    @wind_tiles -- Enum.map(seats, & &1.picked_wind)
  end

  @doc """
  Pick a random available wind tile and assign it to the player's seat
  """
  def pick_random_available_wind(game, seatno) do
    remaining_winds = game |> remaining_winds_to_pick()
    pick_random_wind(game, seatno, remaining_winds)
  end

  defp pick_random_wind(game, _seatno, []), do: game

  defp pick_random_wind(game, seatno, winds) do
    wind = winds |> Enum.random()

    update_seat(game, seatno, fn seat ->
      seat
      |> Map.merge(%{picked_wind: wind})
    end)
  end

  defp update_seat(game, seatno, update_function) do
    Map.update!(game, :seats, fn seats ->
      seats
      |> List.update_at(seatno, update_function)
    end)
  end

  @doc """
  Calculate the state of a game
  """
  def state(game) do
    {game, :tbd}
    |> state_waiting_for_players
    |> state_picking_winds
    # |> state_rolling_for_first_dealer
    # |> state_rolling_for_deal
    # |> state_dealer_discarding
    # |> state_player_turn
    # |> state_draw
    # |> state_win
    # |> state_dq
    |> state_or_invalid
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

  defp state_or_invalid({_game, :tbd}), do: :invalid
  defp state_or_invalid({_game, state}), do: state
end
