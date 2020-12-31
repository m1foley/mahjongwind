defmodule Mjw.SeatTest do
  use ExUnit.Case, async: true

  describe "empty?" do
    test "true if player_id is nil" do
      seat = %Mjw.Seat{}
      assert Mjw.Seat.empty?(seat)
    end

    test "false if player_id is present" do
      seat = %Mjw.Seat{player_id: "123"}
      refute Mjw.Seat.empty?(seat)
    end
  end

  describe "seat_player" do
    test "seats a player in an empty seat" do
      seat = %Mjw.Seat{}
      seat = Mjw.Seat.seat_player(seat, "new_id", "New Name")
      assert seat.player_id == "new_id"
      assert seat.player_name == "New Name"
      assert seat.covered == []
      assert seat.exposed == []
    end

    test "replaces an existing player with the new player" do
      seat = %Mjw.Seat{
        player_id: "old_id",
        player_name: "Old Name",
        covered: ~w(🀇),
        exposed: ~w(🀈)
      }

      seat = Mjw.Seat.seat_player(seat, "new_id", "New Name")
      assert seat.player_id == "new_id"
      assert seat.player_name == "New Name"
      assert seat.covered == ~w(🀇)
      assert seat.exposed == ~w(🀈)
    end
  end
end
