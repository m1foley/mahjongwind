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
      assert seat.concealed == []
      assert seat.exposed == []
      assert seat.hidden_gongs == []
    end

    test "replaces an existing player with the new player" do
      seat = %Mjw.Seat{
        player_id: "old_id",
        player_name: "Old Name",
        concealed: ["n1-0"],
        exposed: ["n2-0"],
        hidden_gongs: ["n3-0"]
      }

      seat = Mjw.Seat.seat_player(seat, "new_id", "New Name")
      assert seat.player_id == "new_id"
      assert seat.player_name == "New Name"
      assert seat.concealed == ["n1-0"]
      assert seat.exposed == ["n2-0"]
      assert seat.hidden_gongs == ["n3-0"]
    end
  end

  describe "pick_wind" do
    test "picks a wind for a player" do
      seat =
        %Mjw.Seat{}
        |> Mjw.Seat.pick_wind("ws", 2)

      assert seat.picked_wind == "ws"
      assert seat.picked_wind_idx == 2
    end
  end

  describe "evacuate_player" do
    test "removes the player from the seat" do
      seat =
        %Mjw.Seat{
          player_id: "id1",
          player_name: "Name1",
          concealed: ["n1-0"],
          exposed: ["n2-0"],
          hidden_gongs: ["n3-0"]
        }
        |> Mjw.Seat.evacuate_player()

      assert seat.player_id == nil
      assert seat.player_name == nil
      assert seat.concealed == ["n1-0"]
      assert seat.exposed == ["n2-0"]
      assert seat.hidden_gongs == ["n3-0"]
    end
  end
end
