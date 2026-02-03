defmodule Mjw.Games.GameStateTest do
  use ExUnit.Case, async: true

  test "waiting_for_players" do
    game = Mjw.Games.Game.new()
    assert Mjw.Games.GameState.state(game) == :waiting_for_players
  end

  test "waiting for players when partially filled" do
    game =
      %Mjw.Games.Game{}
      |> Mjw.Games.Game.seat_player("id0", "name0")
      |> Mjw.Games.Game.seat_player("id1", "name1")

    assert Mjw.Games.GameState.state(game) == :waiting_for_players
  end

  test "picking_winds" do
    game =
      %Mjw.Games.Game{}
      |> Mjw.Games.Game.seat_player("id0", "name0")
      |> Mjw.Games.Game.seat_player("id1", "name1")
      |> Mjw.Games.Game.seat_player("id2", "name2")
      |> Mjw.Games.Game.seat_player("id3", "name3")

    assert Mjw.Games.GameState.state(game) == :picking_winds
  end

  test "rolling_for_first_dealer" do
    game =
      %Mjw.Games.Game{}
      |> Mjw.Games.Game.seat_player("id0", "name0")
      |> Mjw.Games.Game.seat_player("id1", "name1")
      |> Mjw.Games.Game.seat_player("id2", "name2")
      |> Mjw.Games.Game.seat_player("id3", "name3")
      |> Mjw.Games.Game.pick_random_available_wind(0)
      |> Mjw.Games.Game.pick_random_available_wind(1)
      |> Mjw.Games.Game.pick_random_available_wind(2)
      |> Mjw.Games.Game.pick_random_available_wind(3)

    assert Mjw.Games.GameState.state(game) == :rolling_for_first_dealer
  end

  test "rolling_for_deal" do
    game =
      %Mjw.Games.Game{}
      |> Mjw.Games.Game.seat_player("id0", "name0")
      |> Mjw.Games.Game.seat_player("id1", "name1")
      |> Mjw.Games.Game.seat_player("id2", "name2")
      |> Mjw.Games.Game.seat_player("id3", "name3")
      |> Mjw.Games.Game.pick_random_available_wind(0)
      |> Mjw.Games.Game.pick_random_available_wind(1)
      |> Mjw.Games.Game.pick_random_available_wind(2)
      |> Mjw.Games.Game.pick_random_available_wind(3)
      |> Mjw.Games.Game.roll_dice_and_reseat_players()

    assert Mjw.Games.GameState.state(game) == :rolling_for_deal
  end

  test "discarding" do
    game =
      %Mjw.Games.Game{}
      |> Mjw.Games.Game.seat_player("id0", "name0")
      |> Mjw.Games.Game.seat_player("id1", "name1")
      |> Mjw.Games.Game.seat_player("id2", "name2")
      |> Mjw.Games.Game.seat_player("id3", "name3")
      |> Mjw.Games.Game.pick_random_available_wind(0)
      |> Mjw.Games.Game.pick_random_available_wind(1)
      |> Mjw.Games.Game.pick_random_available_wind(2)
      |> Mjw.Games.Game.pick_random_available_wind(3)
      |> Mjw.Games.Game.roll_dice_and_reseat_players()
      |> Mjw.Games.Game.roll_dice_and_deal()

    assert Mjw.Games.GameState.state(game) == :discarding
  end

  test "drawing" do
    {:ok, game} =
      Mjw.Games.Game.new()
      |> Mjw.Games.Game.seat_player("id0", "name0")
      |> Mjw.Games.Game.seat_player("id1", "name1")
      |> Mjw.Games.Game.seat_player("id2", "name2")
      |> Mjw.Games.Game.seat_player("id3", "name3")
      |> Mjw.Games.Game.pick_random_available_wind(0)
      |> Mjw.Games.Game.pick_random_available_wind(1)
      |> Mjw.Games.Game.pick_random_available_wind(2)
      |> Mjw.Games.Game.pick_random_available_wind(3)
      |> Mjw.Games.Game.roll_dice_and_reseat_players()
      |> Mjw.Games.Game.roll_dice_and_deal()
      |> Mjw.Games.Game.discard(0, "n1-1")

    assert Mjw.Games.GameState.state(game) == :drawing
  end

  test "win_declared" do
    game =
      %Mjw.Games.Game{}
      |> Mjw.Games.Game.seat_player("id0", "name0")
      |> Mjw.Games.Game.seat_player("id1", "name1")
      |> Mjw.Games.Game.seat_player("id2", "name2")
      |> Mjw.Games.Game.seat_player("id3", "name3")
      |> Mjw.Games.Game.pick_random_available_wind(0)
      |> Mjw.Games.Game.pick_random_available_wind(1)
      |> Mjw.Games.Game.pick_random_available_wind(2)
      |> Mjw.Games.Game.pick_random_available_wind(3)
      |> Mjw.Games.Game.roll_dice_and_reseat_players()
      |> Mjw.Games.Game.roll_dice_and_deal()
      |> Mjw.Games.Game.declare_win_from_hand(0, "n1-0")

    assert Mjw.Games.GameState.state(game) == :win_declared
  end
end
