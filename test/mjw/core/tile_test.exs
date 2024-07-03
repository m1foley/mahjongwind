defmodule Mjw.TileTest do
  use ExUnit.Case, async: true

  describe "suit" do
    test "returns the suit of a tile" do
      assert Mjw.Tile.suit("df-1") == "d"
    end
  end

  describe "number" do
    test "returns the number of a tile" do
      assert Mjw.Tile.number("c1-2") == "1"
    end
  end

  describe "to_integer" do
    test "returns the numeric value of a tile" do
      assert Mjw.Tile.to_integer("c1-2") == 1
    end
  end

  describe "sort" do
    test "sorts tiles with special tiles last" do
      tiles =
        Mjw.Tile.sort([
          "n1-0",
          "we-0",
          "we-1",
          "b9-0",
          "b8-0",
          "b9-1",
          "n1-3",
          "dp-0",
          "ww-0",
          "c1-0",
          "b1-3"
        ])

      assert tiles == [
               "n1-0",
               "n1-3",
               "c1-0",
               "b1-3",
               "b8-0",
               "b9-0",
               "b9-1",
               "we-0",
               "we-1",
               "ww-0",
               "dp-0"
             ]
    end
  end

  describe "contiguous_in_suit?" do
    test "true if contiguous" do
      assert Mjw.Tile.contiguous_in_suit?("c8-1", "c9-3")
    end

    test "false if not contiguous" do
      refute Mjw.Tile.contiguous_in_suit?("c7-1", "c9-3")
      refute Mjw.Tile.contiguous_in_suit?("n1-0", "n3-1")
    end

    test "false is tiles are not numeric" do
      refute Mjw.Tile.contiguous_in_suit?("c7-1", "wn-0")
      refute Mjw.Tile.contiguous_in_suit?("we-0", "ws-0")
    end
  end

  describe "tile_format?" do
    test "is true for tiles" do
      assert Mjw.Tile.tile_format?("wn-2")
      assert Mjw.Tile.tile_format?("n1-0")
    end

    test "is false for non-tiles" do
      refute Mjw.Tile.tile_format?("")
      refute Mjw.Tile.tile_format?("🥾")
    end
  end

  describe "identical?" do
    test "is true when tiles are the same except for id" do
      assert Mjw.Tile.identical?("dw-1", "dw-3")
      assert Mjw.Tile.identical?("c9-0", "c9-1")
    end

    test "is false when tiles are not identical" do
      refute Mjw.Tile.identical?("dw-1", "de-1")
      refute Mjw.Tile.identical?("c8-0", "c9-1")
    end
  end
end
