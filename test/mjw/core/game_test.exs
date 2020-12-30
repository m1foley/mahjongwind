defmodule Mjw.GameTest do
  use ExUnit.Case, async: true

  describe "new" do
    test "generates a new game with a random id" do
      game = Mjw.Game.new()
      assert game.id =~ ~r/\A[a-f0-9\-]{36}\z/
    end

    test "shuffles the deck" do
      game = Mjw.Game.new()
      assert length(game.deck) == 136
    end

    test "defaults the wind to East" do
      game = Mjw.Game.new()
      assert game.wind == "🀀"
    end

    test "defaults discards to empty list" do
      game = Mjw.Game.new()
      assert game.discards == []
    end
  end
end
