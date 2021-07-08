defmodule Mjw.Tile do
  @numeric_suits ~w(n c b)
  @non_numeric_suits ~w(w d)
  @suit_sort_order @numeric_suits ++ @non_numeric_suits
  @tile_format_regex ~r/^[ncbwd][a-z1-9]-[0-3]$/

  @doc """
  Sort according to beauty, with special tiles last
  """
  def sort(tiles) do
    Enum.sort_by(tiles, fn tile ->
      {Enum.find_index(@suit_sort_order, &(&1 == suit(tile))), tile}
    end)
  end

  def suit(tile) do
    String.at(tile, 0)
  end

  def number(tile) do
    String.at(tile, 1)
  end

  def to_integer(tile) do
    String.to_integer(number(tile))
  end

  def without_id(tile) do
    String.slice(tile, 0..1)
  end

  def numeric?(tile) do
    suit(tile) in @numeric_suits
  end

  def tile_format?(string) do
    String.match?(string, @tile_format_regex)
  end

  @doc """
  True if tile2 is after tile1 in the same suit (order-dependent)
  """
  def contiguous_in_suit?(tile1, tile2) do
    numeric?(tile1) && numeric?(tile2) &&
      suit(tile1) == suit(tile2) && to_integer(tile1) + 1 == to_integer(tile2)
  end

  def identical?(tile1, tile2) do
    without_id(tile1) == without_id(tile2)
  end
end
