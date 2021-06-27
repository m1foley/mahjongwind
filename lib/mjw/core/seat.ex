defmodule Mjw.Seat do
  defstruct concealed: [],
            exposed: [],
            hiddengongs: [],
            # A player "peeks" from the deck beore dragging it to their hand or
            # discards. This is the same as being in their concealed tiles, but
            # displays separately on the screen for convenience.
            peektile: nil,
            wintile: nil,
            player_id: nil,
            player_name: nil,
            picked_wind: nil,
            picked_wind_idx: nil,
            # Reaction to a declared win:
            # - nil = not confirmed
            # - :ok = confirmed
            # - :expose = exposed hand, not confirmed
            # - :expose_ok = exposed hand, confirmed
            winreaction: nil

  def empty?(%__MODULE__{player_id: nil}), do: true
  def empty?(%__MODULE__{}), do: false

  def seat_player(%__MODULE__{} = seat, player_id, player_name) do
    %{seat | player_id: player_id, player_name: player_name}
  end

  @bot_id "bot"

  def seat_bot(%__MODULE__{} = seat, bot_name) do
    %{seat | player_id: @bot_id, player_name: bot_name}
  end

  def bot?(%__MODULE__{player_id: @bot_id}), do: true
  def bot?(%__MODULE__{}), do: false

  def pick_wind(%__MODULE__{} = seat, picked_wind, picked_wind_idx) do
    %{seat | picked_wind: picked_wind, picked_wind_idx: picked_wind_idx}
  end

  def evacuate_player(%__MODULE__{} = seat) do
    %{seat | player_id: nil, player_name: nil}
  end

  @doc """
  Clear tile attributes between games
  """
  def clear_tiles(%__MODULE__{} = seat) do
    %{
      seat
      | concealed: [],
        exposed: [],
        hiddengongs: [],
        peektile: nil,
        wintile: nil,
        winreaction: nil
    }
  end

  @doc """
  True if the given player confirmed the declared win
  """
  def confirmed_win?(%__MODULE__{} = seat) do
    bot?(seat) || seat.winreaction in [:ok, :expose_ok]
  end

  @doc """
  Confirm another player's declared win
  """
  def confirm_win(%__MODULE__{} = seat)
      when seat.winreaction in [:expose, :expose_ok] do
    %{seat | winreaction: :expose_ok}
  end

  def confirm_win(%__MODULE__{} = seat) do
    %{seat | winreaction: :ok}
  end

  @doc """
  Expose the player's hand to other players after a loss
  """
  def expose_loser_hand(%__MODULE__{} = seat)
      when seat.winreaction in [:ok, :expose_ok] do
    %{seat | winreaction: :expose_ok}
  end

  def expose_loser_hand(%__MODULE__{} = seat) do
    %{seat | winreaction: :expose}
  end

  @doc """
  Clear attributes related to declaring/confirming a win
  """
  def clear_win_attributes(%__MODULE__{} = seat) do
    %{seat | wintile: nil, winreaction: nil}
  end

  def declare_win(%__MODULE__{} = seat, wintile) do
    %{seat | wintile: wintile, winreaction: :expose}
  end

  def declared_win?(%__MODULE__{wintile: nil}), do: false
  def declared_win?(%__MODULE__{}), do: true

  def win_expose?(%__MODULE__{} = seat) do
    bot?(seat) || seat.winreaction in [:expose, :expose_ok]
  end

  @doc """
  Remove a tile from a player's hand, no matter which list it's in.
  """
  def remove_from_hand(%__MODULE__{} = seat, tile) do
    seat
    |> remove_from_concealed(tile)
    |> remove_from_exposed(tile)
    |> remove_from_hiddengongs(tile)
    |> remove_matching_peektile(tile)
    |> remove_matching_wintile(tile)
  end

  def remove_from_concealed(%__MODULE__{} = seat, tile) do
    Map.update!(seat, :concealed, &List.delete(&1, tile))
  end

  def remove_from_exposed(%__MODULE__{} = seat, tile) do
    Map.update!(seat, :exposed, &List.delete(&1, tile))
  end

  def remove_from_hiddengongs(%__MODULE__{} = seat, tile) do
    Map.update!(seat, :hiddengongs, &List.delete(&1, tile))
  end

  def remove_matching_peektile(%__MODULE__{peektile: tile} = seat, tile) do
    %{seat | peektile: nil}
  end

  def remove_matching_peektile(%__MODULE__{} = seat, _tile), do: seat

  def remove_matching_wintile(%__MODULE__{wintile: tile} = seat, tile) do
    %{seat | wintile: nil}
  end

  def remove_matching_wintile(%__MODULE__{} = seat, _tile), do: seat

  def add_to_concealed(%__MODULE__{} = seat, tile) do
    %{seat | concealed: seat.concealed ++ [tile]}
  end

  @suit_sort_order ~w(n c b w d)

  @doc """
  Sort according to beauty, with special tiles last
  """
  def sort_concealed(%__MODULE__{} = seat) do
    Map.update!(seat, :concealed, fn concealed ->
      Enum.sort_by(concealed, fn tile ->
        suit = String.at(tile, 0)
        {Enum.find_index(@suit_sort_order, &(&1 == suit)), tile}
      end)
    end)
  end

  def peek(%__MODULE__{} = seat, tile) do
    %{seat | peektile: tile}
  end

  def clear_peektile(%__MODULE__{} = seat) do
    peek(seat, nil)
  end

  @doc """
  If a user discards a concealed tile while they still have a peektile, move
  the peektile into their concealed tiles
  """
  def ensure_no_dangling_peektile(%__MODULE__{peektile: nil} = seat), do: seat

  def ensure_no_dangling_peektile(%__MODULE__{peektile: peektile} = seat) do
    seat
    |> add_to_concealed(peektile)
    |> clear_peektile()
  end

  @doc """
  A user may have done minor (i.e., not undoable) things like moving tiles
  within their hand since they performed the undoable action. All those
  reordering changes should be preserved when undoing. The easiest way to do
  this is to just start with their current game hand, and remove/add any tiles
  that were added/removed by the undoable action, respectively. This ensures
  that the tiles in the two hands are identical but possibly rearranged.
  Assumes that any undoable action can add or remove at most 1 tile, and can't
  do both at once.
  """
  def preserve_hand_rearranges_for_undo(%__MODULE__{} = seat, %__MODULE__{} = undo_state_seat) do
    # There is no situation where we end up with a wintile present, because an
    # undo_state can never be a win state. Doing it this way is the easiest way
    # to rollback declare_win_from_hand, which appears as if it's "rearranging"
    # the tiles.
    seat = %{seat | wintile: nil}

    all_seat_tiles = seat |> all_tiles_in_hand()
    all_undo_state_seat_tiles = undo_state_seat |> all_tiles_in_hand()
    tile_added = all_seat_tiles |> Enum.find(&(!(&1 in all_undo_state_seat_tiles)))

    if tile_added do
      seat |> remove_from_hand(tile_added)
    else
      tile_removed = all_undo_state_seat_tiles |> Enum.find(&(!(&1 in all_seat_tiles)))

      if tile_removed do
        seat |> restore_to_hand(undo_state_seat, tile_removed)
      else
        seat
      end
    end
  end

  defp all_tiles_in_hand(%__MODULE__{} = seat) do
    seat.exposed ++
      seat.concealed ++
      seat.hiddengongs ++
      Enum.filter([seat.peektile, seat.wintile], & &1)
  end

  # Doesn't check wintile because it can never be populated in an undo_state
  defp restore_to_hand(%__MODULE__{} = seat, %__MODULE__{} = undo_state_seat, tile) do
    if undo_state_seat.peektile == tile do
      %{seat | peektile: tile}
    else
      removed_from_list =
        [:exposed, :concealed, :hiddengongs]
        |> Enum.find(fn list -> tile in Map.get(undo_state_seat, list) end)

      seat |> Map.update!(removed_from_list, fn list -> list ++ [tile] end)
    end
  end
end
