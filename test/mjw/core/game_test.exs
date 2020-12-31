defmodule Mjw.GameTest do
  use ExUnit.Case, async: true

  describe "new" do
    test "generates a Game with reasonable initial values" do
      game = Mjw.Game.new()
      assert game.id =~ ~r/\A[a-f0-9\-]{36}\z/
      assert length(game.deck) == 136
      assert game.wind == "🀀"
      assert game.discards == []
      assert length(game.seats) == 4
    end
  end

  describe "empty_seats_count" do
    test "returns 4 initially" do
      game = Mjw.Game.new()
      assert Mjw.Game.empty_seats_count(game) == 4
    end
  end
end
