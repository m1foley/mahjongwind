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
  def empty?(%__MODULE__{player_id: _id}), do: false

  def seat_player(%__MODULE__{} = seat, player_id, player_name) do
    %{seat | player_id: player_id, player_name: player_name}
  end

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
  def confirmed_win?(%__MODULE__{winreaction: winreaction}) do
    winreaction in [:ok, :expose_ok]
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

  def win_expose?(%__MODULE__{winreaction: winreaction}) do
    winreaction in [:expose, :expose_ok]
  end

  @doc """
  Remove a tile from a player's hand, no matter which list it's in.
  Excludes wintile because that's a special case.
  """
  def remove_from_hand(%__MODULE__{} = seat, tile) do
    seat
    |> Map.update!(:exposed, &List.delete(&1, tile))
    |> Map.update!(:concealed, &List.delete(&1, tile))
    |> Map.update!(:hiddengongs, &List.delete(&1, tile))
    |> Map.update!(:peektile, fn peektile -> if peektile == tile, do: nil, else: peektile end)
  end

  def add_to_concealed(%__MODULE__{} = seat, tile) do
    %{seat | concealed: seat.concealed ++ [tile]}
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
end
