defmodule Mjw.BotStrategy do
  @doc """
  Determine where to draw tile (discards or deck) or declare win from discard
  """
  def draw(
        %Mjw.Game{turn_state: :drawing, discards: [discarded_tile | _], deck: [deck_tile | _]} =
          game
      ) do
    seat = turn_seat(game)

    if wins_with?(seat, discarded_tile) do
      :win_with_discard
    else
      case eat_discard(seat, discarded_tile) do
        {:ok, new_concealed, new_exposed} ->
          {:draw_discard, new_concealed, new_exposed}

        :cannot_eat_discard ->
          if wins_with?(seat, deck_tile) do
            :zimo
          else
            :draw_deck_tile
          end
      end
    end
  end

  defp wins_with?(%Mjw.Seat{concealed: concealed}, tile) do
    winning_hand?([tile | concealed])
  end

  # The sum of a run is always divisible by 3.
  # Adding all the numbers in the hand is 3N + 2M, where M is the pair tile.
  # total % 3 tells us the possibilities of M:
  # total % 3 = 0  -> M = {3,6,9}
  # total % 3 = 1  -> M = {2,5,8}
  # total % 3 = 2  -> M = {1,4,7}
  #
  # For each possible M, try removing those 2 tiles and then remove all runs.
  # If this exhausts all tiles then it's a winning hand.
  # Algorithm adapted from: https://stackoverflow.com/a/4155177/899389
  #
  # For simplicity, only runs are used (no pongs) and only numeric tiles.
  defp winning_hand?(tiles) do
    Enum.all?(tiles, &Mjw.Tile.numeric?/1) &&
      tiles
      |> possible_pairs_for_winning_hand()
      |> Enum.any?(fn possible_pair -> winning_hand?(tiles, possible_pair) end)
  end

  defp possible_pairs_for_winning_hand(tiles) do
    sum_of_tiles = tiles |> Enum.map(&Mjw.Tile.to_integer/1) |> Enum.sum()

    possible_pair_numbers =
      case rem(sum_of_tiles, 3) do
        0 -> ~w(3 6 9)
        1 -> ~w(2 5 8)
        2 -> ~w(1 4 7)
      end

    tiles
    |> Enum.filter(&(Mjw.Tile.number(&1) in possible_pair_numbers))
    |> Mjw.Tile.sort()
    |> Enum.chunk_by(&Mjw.Tile.without_id/1)
    |> Enum.filter(&(length(&1) >= 2))
    |> Enum.map(&Enum.take(&1, 2))
  end

  # Remove the pair and then remove all runs.
  # If this exhausts all tiles then it's a winning hand.
  defp winning_hand?(tiles, pair) do
    (tiles -- pair)
    |> remove_runs()
    |> Enum.empty?()
  end

  defp remove_runs(tiles) do
    tiles
    |> Mjw.Tile.sort()
    |> remove_runs_from_sorted()
  end

  defp remove_runs_from_sorted(tiles) when length(tiles) < 3, do: tiles

  defp remove_runs_from_sorted([first_tile | tail]) do
    middle_tile_idx = Enum.find_index(tail, &Mjw.Tile.contiguous_in_suit?(first_tile, &1))

    if middle_tile_idx do
      middle_tile = Enum.at(tail, middle_tile_idx)
      last_tile_idx = Enum.find_index(tail, &Mjw.Tile.contiguous_in_suit?(middle_tile, &1))

      if last_tile_idx do
        tail
        |> List.delete_at(last_tile_idx)
        |> List.delete_at(middle_tile_idx)
        |> remove_runs_from_sorted()
      else
        [first_tile | remove_runs_from_sorted(tail)]
      end
    else
      [first_tile | remove_runs_from_sorted(tail)]
    end
  end

  defp eat_discard(%Mjw.Seat{concealed: concealed, exposed: exposed}, tile) do
    if Mjw.Tile.numeric?(tile) do
      run_pool = remove_runs(concealed)
      reduced = remove_runs([tile | run_pool])

      if length(reduced) != length(run_pool) + 1 do
        run =
          (run_pool -- reduced)
          |> Enum.sort()
          |> List.insert_at(1, tile)

        {:ok, concealed -- run, exposed ++ run}
      else
        :cannot_eat_discard
      end
    else
      :cannot_eat_discard
    end
  end

  @doc """
  Determine tile to discard
  """
  def discard(%Mjw.Game{turn_state: :discarding} = game) do
    tiles = remove_runs(turn_seat(game).concealed)

    if length(tiles) == 2 do
      most_occurrences_in_viewable_tiles(game, tiles)
    else
      # For simplicity, only keep numeric tiles
      non_numerics = Enum.reject(tiles, &Mjw.Tile.numeric?/1)

      if !Enum.empty?(non_numerics) do
        Enum.random(non_numerics)
      else
        without_contiguous = reject_contiguous(tiles)

        if !Enum.empty?(without_contiguous) do
          without_contiguous
          |> filter_by_rarest_suit()
          |> Enum.random()
        else
          tiles =
            if length(tiles) == 5 do
              # already verified all tiles are contiguous, so keep the pair if
              # one exists so we'll be waiting
              pair =
                tiles
                |> Enum.chunk_by(&Mjw.Tile.without_id/1)
                |> Enum.filter(&(length(&1) >= 2))
                |> Enum.map(&Enum.take(&1, 2))
                |> Enum.at(0)

              if pair do
                reject_contiguous(tiles -- pair)
              else
                tiles
              end
            else
              tiles
            end

          tiles
          |> filter_by_highest_sibling_count()
          |> filter_by_rarest_suit()
          |> Enum.random()
        end
      end
    end
  end

  def most_occurrences_in_viewable_tiles(%Mjw.Game{} = game, tiles) do
    viewable_tiles =
      game.discards ++
        (game.seats
         |> Enum.with_index()
         |> Enum.flat_map(fn {seat, idx} ->
           if idx == game.turn_seatno do
             Mjw.Seat.all_tiles_in_hand(seat)
           else
             seat.exposed
           end
         end))

    Enum.max_by(tiles, fn tile ->
      Enum.count(viewable_tiles, &Mjw.Tile.identical?(&1, tile))
    end)
  end

  # Discard tiles that aren't next to other tiles in their suit.
  # Not sophisticated enough to keep gutshots.
  # TODO: This algorithm can be improved
  defp reject_contiguous(tiles) do
    Enum.reject(tiles, fn tile ->
      Enum.any?(tiles, fn tile2 ->
        Mjw.Tile.contiguous_in_suit?(tile, tile2) || Mjw.Tile.contiguous_in_suit?(tile2, tile)
      end)
    end)
  end

  defp filter_by_highest_sibling_count([tile | []]), do: [tile]

  # filter to contain only tiles with the highest number of identical siblings
  defp filter_by_highest_sibling_count(tiles) do
    sibling_groups =
      tiles
      |> Enum.group_by(&Mjw.Tile.without_id/1)
      |> Enum.map(fn {_, siblings} -> siblings end)

    highest_sibling_count =
      sibling_groups
      |> Enum.map(&Kernel.length/1)
      |> Enum.max()

    sibling_groups
    |> Enum.filter(fn siblings -> length(siblings) == highest_sibling_count end)
    |> List.flatten()
  end

  defp filter_by_rarest_suit([tile | []]), do: [tile]

  # filter to contain only the tiles with the rarest suit
  defp filter_by_rarest_suit(tiles) do
    suit_groups =
      tiles
      |> Enum.group_by(&Mjw.Tile.suit/1)
      |> Enum.map(fn {_, tiles_in_suit} -> tiles_in_suit end)

    rarest_suit_count =
      suit_groups
      |> Enum.map(&Kernel.length/1)
      |> Enum.min()

    suit_groups
    |> Enum.filter(fn tiles_in_suit -> length(tiles_in_suit) == rarest_suit_count end)
    |> List.flatten()
  end

  def find_win_out_of_turn(%Mjw.Game{turn_state: :drawing, discards: [discarded_tile | _]} = game) do
    result =
      game.seats
      |> Enum.with_index()
      |> Enum.filter(fn {seat, idx} -> idx != game.turn_seatno && Mjw.Seat.bot?(seat) end)
      |> Enum.find(fn {seat, _idx} -> wins_with?(seat, discarded_tile) end)

    case result do
      {_seat, idx} -> {:ok, idx}
      nil -> :no_wins
    end
  end

  defp turn_seat(%Mjw.Game{turn_seatno: seatno, seats: seats}) do
    Enum.at(seats, seatno)
  end
end
