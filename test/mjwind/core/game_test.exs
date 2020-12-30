defmodule Mjwind.GameTest do
  use ExUnit.Case, async: true
  doctest Mjwind.Game

  test "new generates a new game with a random id" do
    game = Mjwind.Game.new()
    assert game.id =~ ~r/\A[a-f0-9\-]{36}\z/
    assert length(game.deck) == 136
    assert game.discards == []
    assert game.wind == "🀀"
  end
end
