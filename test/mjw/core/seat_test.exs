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
      assert seat.hiddengongs == []
    end

    test "replaces an existing player with the new player" do
      seat = %Mjw.Seat{
        player_id: "old_id",
        player_name: "Old Name",
        concealed: ["n1-0"],
        exposed: ["n2-0"],
        hiddengongs: ["n3-0"]
      }

      seat = Mjw.Seat.seat_player(seat, "new_id", "New Name")
      assert seat.player_id == "new_id"
      assert seat.player_name == "New Name"
      assert seat.concealed == ["n1-0"]
      assert seat.exposed == ["n2-0"]
      assert seat.hiddengongs == ["n3-0"]
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
          hiddengongs: ["n3-0"]
        }
        |> Mjw.Seat.evacuate_player()

      assert seat.player_id == nil
      assert seat.player_name == nil
      assert seat.concealed == ["n1-0"]
      assert seat.exposed == ["n2-0"]
      assert seat.hiddengongs == ["n3-0"]
    end
  end

  describe "clear_tiles" do
    test "removes the round-specific tiles from the seat" do
      seat =
        %Mjw.Seat{
          player_id: "id1",
          player_name: "Name1",
          concealed: ["n1-0"],
          exposed: ["n2-0"],
          hiddengongs: ["n3-0"],
          wintile: "n4-0",
          winreaction: :ok
        }
        |> Mjw.Seat.clear_tiles()

      assert seat.player_id == "id1"
      assert seat.player_name == "Name1"
      assert seat.concealed == []
      assert seat.exposed == []
      assert seat.hiddengongs == []
      assert seat.wintile == nil
      assert seat.winreaction == nil
    end
  end

  describe "confirmed_win?" do
    test "false when winreaction is nil" do
      seat = %Mjw.Seat{
        wintile: nil,
        winreaction: nil
      }

      refute seat |> Mjw.Seat.confirmed_win?()
    end

    test "false when winreaction is :expose" do
      seat = %Mjw.Seat{
        wintile: nil,
        winreaction: :expose
      }

      refute seat |> Mjw.Seat.confirmed_win?()
    end

    test "true when winreaction is :ok" do
      seat = %Mjw.Seat{
        wintile: nil,
        winreaction: :ok
      }

      assert seat |> Mjw.Seat.confirmed_win?()
    end

    test "true when winreaction is :ok and wintile is present" do
      seat = %Mjw.Seat{
        wintile: "b1-1",
        winreaction: :ok
      }

      assert seat |> Mjw.Seat.confirmed_win?()
    end

    test "true when winreaction is :expose_ok" do
      seat = %Mjw.Seat{
        wintile: nil,
        winreaction: :expose_ok
      }

      assert seat |> Mjw.Seat.confirmed_win?()
    end
  end

  describe "confirm_win" do
    test "changes winreaction from nil -> :ok" do
      seat = %Mjw.Seat{winreaction: nil} |> Mjw.Seat.confirm_win()
      assert seat.winreaction == :ok
    end

    test "doesn't change winreaction from :ok" do
      seat = %Mjw.Seat{winreaction: :ok} |> Mjw.Seat.confirm_win()
      assert seat.winreaction == :ok
    end

    test "changes winreaction from :expose -> :expose_ok" do
      seat = %Mjw.Seat{winreaction: :expose} |> Mjw.Seat.confirm_win()
      assert seat.winreaction == :expose_ok
    end

    test "doesn't change winreaction from :expose_ok" do
      seat = %Mjw.Seat{winreaction: :expose_ok} |> Mjw.Seat.confirm_win()
      assert seat.winreaction == :expose_ok
    end
  end

  describe "expose_loser_hand" do
    test "changes winreaction from nil -> :expose" do
      seat = %Mjw.Seat{winreaction: nil} |> Mjw.Seat.expose_loser_hand()
      assert seat.winreaction == :expose
    end

    test "changes winreaction from :ok -> :expose_ok" do
      seat = %Mjw.Seat{winreaction: :ok} |> Mjw.Seat.expose_loser_hand()
      assert seat.winreaction == :expose_ok
    end

    test "doesn't change winreaction from :expose" do
      seat = %Mjw.Seat{winreaction: :expose} |> Mjw.Seat.expose_loser_hand()
      assert seat.winreaction == :expose
    end

    test "doesn't change winreaction from :expose_ok" do
      seat = %Mjw.Seat{winreaction: :expose_ok} |> Mjw.Seat.expose_loser_hand()
      assert seat.winreaction == :expose_ok
    end
  end

  describe "clear_win_attributes" do
    test "removes the attributes related to declaring/confirming a win" do
      seat =
        %Mjw.Seat{
          player_id: "id1",
          player_name: "Name1",
          concealed: ["n1-0"],
          exposed: ["n2-0"],
          hiddengongs: ["n3-0"],
          wintile: "n4-0",
          winreaction: :ok
        }
        |> Mjw.Seat.clear_win_attributes()

      assert seat.player_id == "id1"
      assert seat.player_name == "Name1"
      assert seat.concealed == ["n1-0"]
      assert seat.exposed == ["n2-0"]
      assert seat.hiddengongs == ["n3-0"]
      assert seat.wintile == nil
      assert seat.winreaction == nil
    end
  end

  describe "declare_win" do
    test "sets wintile and winreaction attributes" do
      seat =
        %Mjw.Seat{wintile: nil, winreaction: nil}
        |> Mjw.Seat.declare_win("b4-1")

      assert seat.wintile == "b4-1"
      assert seat.winreaction == :expose
    end
  end

  describe "declared_win?" do
    test "true if declared win" do
      seat = %Mjw.Seat{wintile: "n4-0", winreaction: :expose}
      assert seat |> Mjw.Seat.declared_win?()
    end

    test "false if not declared win" do
      seat = %Mjw.Seat{wintile: nil, winreaction: :ok}
      refute seat |> Mjw.Seat.declared_win?()
    end
  end

  describe "win_expose?" do
    test "true if expose or expose_ok" do
      assert %Mjw.Seat{winreaction: :expose} |> Mjw.Seat.win_expose?()
      assert %Mjw.Seat{winreaction: :expose_ok} |> Mjw.Seat.win_expose?()
    end

    test "false if not exposed" do
      refute %Mjw.Seat{winreaction: nil} |> Mjw.Seat.win_expose?()
      refute %Mjw.Seat{winreaction: :ok} |> Mjw.Seat.win_expose?()
    end
  end
end
