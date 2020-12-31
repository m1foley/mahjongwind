defmodule Mjw.Game do
  @all_tiles ~w(
    🀀 🀁 🀂 🀃 🀄 🀅 🀆 🀇 🀈 🀉 🀊 🀋 🀌 🀍 🀎 🀏 🀐 🀑 🀒 🀓 🀔 🀕 🀖 🀗 🀘 🀙 🀚 🀛 🀜 🀝 🀞 🀟 🀠 🀡
    🀀 🀁 🀂 🀃 🀄 🀅 🀆 🀇 🀈 🀉 🀊 🀋 🀌 🀍 🀎 🀏 🀐 🀑 🀒 🀓 🀔 🀕 🀖 🀗 🀘 🀙 🀚 🀛 🀜 🀝 🀞 🀟 🀠 🀡
    🀀 🀁 🀂 🀃 🀄 🀅 🀆 🀇 🀈 🀉 🀊 🀋 🀌 🀍 🀎 🀏 🀐 🀑 🀒 🀓 🀔 🀕 🀖 🀗 🀘 🀙 🀚 🀛 🀜 🀝 🀞 🀟 🀠 🀡
    🀀 🀁 🀂 🀃 🀄 🀅 🀆 🀇 🀈 🀉 🀊 🀋 🀌 🀍 🀎 🀏 🀐 🀑 🀒 🀓 🀔 🀕 🀖 🀗 🀘 🀙 🀚 🀛 🀜 🀝 🀞 🀟 🀠 🀡
  )
  @four_empty_seats 0..3 |> Enum.map(fn _ -> %Mjw.Seat{} end)

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
    Map.update!(game, :seats, fn seats ->
      empty_seat_idx = seats |> Enum.find_index(&Mjw.Seat.empty?/1)

      seats
      |> List.update_at(empty_seat_idx, fn seat ->
        seat |> Mjw.Seat.seat_player(player_id, player_name)
      end)
    end)
  end

  @doc """
  Calculate the state of a game
  """
  def state(%__MODULE__{} = game) do
    {_game, state} =
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
      |> state_invalid

    state
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
    if !Enum.all?(game.seats, & &1.picked_wind) do
      {game, :picking_winds}
    else
      {game, :tbd}
    end
  end

  defp state_picking_winds({game, state}), do: {game, state}

  defp state_invalid({game, :tbd}) do
    {game, :invalid}
  end

  defp state_invalid({game, state}), do: {game, state}
end
