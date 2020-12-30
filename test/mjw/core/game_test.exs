defmodule Mjw.GameTest do
  use ExUnit.Case, async: true

  test "new generates a new game with a random id" do
    game = Mjw.Game.new()
    assert game.id =~ ~r/\A[a-f0-9\-]{36}\z/
    assert length(game.deck) == 136
    assert game.discards == []
    assert game.wind == "🀀"
  end
end
