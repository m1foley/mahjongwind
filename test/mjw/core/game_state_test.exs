defmodule Mjw.GameStateTest do
  use ExUnit.Case, async: true

  test "waiting_for_players" do
    game = Mjw.Game.new()
    assert Mjw.GameState.state(game) == :waiting_for_players
  end

  test "waiting for players when partially filled" do
    game =
      %Mjw.Game{}
      |> Mjw.Game.seat_player("id0", "name0")
      |> Mjw.Game.seat_player("id1", "name1")

    assert Mjw.GameState.state(game) == :waiting_for_players
  end

  test "picking_winds" do
    game =
      %Mjw.Game{}
      |> Mjw.Game.seat_player("id0", "name0")
      |> Mjw.Game.seat_player("id1", "name1")
      |> Mjw.Game.seat_player("id2", "name2")
      |> Mjw.Game.seat_player("id3", "name3")

    assert Mjw.GameState.state(game) == :picking_winds
  end

  test "rolling_for_first_dealer" do
    game =
      %Mjw.Game{}
      |> Mjw.Game.seat_player("id0", "name0")
      |> Mjw.Game.seat_player("id1", "name1")
      |> Mjw.Game.seat_player("id2", "name2")
      |> Mjw.Game.seat_player("id3", "name3")
      |> Mjw.Game.pick_random_available_wind(0)
      |> Mjw.Game.pick_random_available_wind(1)
      |> Mjw.Game.pick_random_available_wind(2)
      |> Mjw.Game.pick_random_available_wind(3)

    assert Mjw.GameState.state(game) == :rolling_for_first_dealer
  end

  test "rolling_for_deal" do
    game =
      %Mjw.Game{}
      |> Mjw.Game.seat_player("id0", "name0")
      |> Mjw.Game.seat_player("id1", "name1")
      |> Mjw.Game.seat_player("id2", "name2")
      |> Mjw.Game.seat_player("id3", "name3")
      |> Mjw.Game.pick_random_available_wind(0)
      |> Mjw.Game.pick_random_available_wind(1)
      |> Mjw.Game.pick_random_available_wind(2)
      |> Mjw.Game.pick_random_available_wind(3)
      |> Mjw.Game.roll_dice_and_reseat_players()

    assert Mjw.GameState.state(game) == :rolling_for_deal
  end

  test "discarding" do
    game =
      %Mjw.Game{}
      |> Mjw.Game.seat_player("id0", "name0")
      |> Mjw.Game.seat_player("id1", "name1")
      |> Mjw.Game.seat_player("id2", "name2")
      |> Mjw.Game.seat_player("id3", "name3")
      |> Mjw.Game.pick_random_available_wind(0)
      |> Mjw.Game.pick_random_available_wind(1)
      |> Mjw.Game.pick_random_available_wind(2)
      |> Mjw.Game.pick_random_available_wind(3)
      |> Mjw.Game.roll_dice_and_reseat_players()
      |> Mjw.Game.roll_dice_and_deal()

    assert Mjw.GameState.state(game) == :discarding
  end

  test "drawing" do
    {:ok, game} =
      Mjw.Game.new()
      |> Mjw.Game.seat_player("id0", "name0")
      |> Mjw.Game.seat_player("id1", "name1")
      |> Mjw.Game.seat_player("id2", "name2")
      |> Mjw.Game.seat_player("id3", "name3")
      |> Mjw.Game.pick_random_available_wind(0)
      |> Mjw.Game.pick_random_available_wind(1)
      |> Mjw.Game.pick_random_available_wind(2)
      |> Mjw.Game.pick_random_available_wind(3)
      |> Mjw.Game.roll_dice_and_reseat_players()
      |> Mjw.Game.roll_dice_and_deal()
      |> Mjw.Game.discard(0, "n1-1")

    assert Mjw.GameState.state(game) == :drawing
  end

  test "win_declared" do
    game =
      %Mjw.Game{}
      |> Mjw.Game.seat_player("id0", "name0")
      |> Mjw.Game.seat_player("id1", "name1")
      |> Mjw.Game.seat_player("id2", "name2")
      |> Mjw.Game.seat_player("id3", "name3")
      |> Mjw.Game.pick_random_available_wind(0)
      |> Mjw.Game.pick_random_available_wind(1)
      |> Mjw.Game.pick_random_available_wind(2)
      |> Mjw.Game.pick_random_available_wind(3)
      |> Mjw.Game.roll_dice_and_reseat_players()
      |> Mjw.Game.roll_dice_and_deal()
      |> Mjw.Game.declare_win_from_hand(0, "n1-0")

    assert Mjw.GameState.state(game) == :win_declared
  end
end
