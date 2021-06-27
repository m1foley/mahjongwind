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
      seat =
        %Mjw.Seat{}
        |> Mjw.Seat.seat_player("new_id", "New Name")

      assert seat.player_id == "new_id"
      assert seat.player_name == "New Name"
      assert seat.concealed == []
      assert seat.exposed == []
      assert seat.hiddengongs == []
    end

    test "replaces an existing player with the new player" do
      seat =
        %Mjw.Seat{
          player_id: "old_id",
          player_name: "Old Name",
          concealed: ["n1-0"],
          exposed: ["n2-0"],
          hiddengongs: ["n3-0"]
        }
        |> Mjw.Seat.seat_player("new_id", "New Name")

      assert seat.player_id == "new_id"
      assert seat.player_name == "New Name"
      assert seat.concealed == ["n1-0"]
      assert seat.exposed == ["n2-0"]
      assert seat.hiddengongs == ["n3-0"]
    end
  end

  describe "seat_bot" do
    test "seats a bot in an empty seat" do
      seat =
        %Mjw.Seat{}
        |> Mjw.Seat.seat_bot("Bot Name")

      assert Mjw.Seat.bot?(seat)
      assert seat.player_name == "Bot Name"
      assert seat.concealed == []
      assert seat.exposed == []
      assert seat.hiddengongs == []
    end

    test "replaces an existing player with the new bot" do
      seat =
        %Mjw.Seat{
          player_id: "old_id",
          player_name: "Old Name",
          concealed: ["n1-0"],
          exposed: ["n2-0"],
          hiddengongs: ["n3-0"]
        }
        |> Mjw.Seat.seat_bot("Bot Name")

      assert Mjw.Seat.bot?(seat)
      assert seat.player_name == "Bot Name"
      assert seat.concealed == ["n1-0"]
      assert seat.exposed == ["n2-0"]
      assert seat.hiddengongs == ["n3-0"]
    end
  end

  describe "bot" do
    test "true if player_id is the reserved bot id" do
      seat = %Mjw.Seat{player_id: "bot"}
      assert Mjw.Seat.bot?(seat)
    end

    test "false if player_id is not the reserved bot id" do
      seat = %Mjw.Seat{player_id: "other_id"}
      refute Mjw.Seat.bot?(seat)
    end

    test "false if player_id is nil" do
      seat = %Mjw.Seat{}
      refute Mjw.Seat.bot?(seat)
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
          peektile: "n4-0",
          wintile: "n5-0",
          winreaction: :ok
        }
        |> Mjw.Seat.clear_tiles()

      assert seat.player_id == "id1"
      assert seat.player_name == "Name1"
      assert seat.concealed == []
      assert seat.exposed == []
      assert seat.hiddengongs == []
      assert seat.peektile == nil
      assert seat.wintile == nil
      assert seat.winreaction == nil
    end
  end

  describe "confirmed_win?" do
    test "false when winreaction is nil" do
      refute %Mjw.Seat{wintile: nil, winreaction: nil}
             |> Mjw.Seat.confirmed_win?()
    end

    test "false when winreaction is :expose" do
      refute %Mjw.Seat{wintile: nil, winreaction: :expose}
             |> Mjw.Seat.confirmed_win?()
    end

    test "true when winreaction is :ok" do
      assert %Mjw.Seat{wintile: nil, winreaction: :ok}
             |> Mjw.Seat.confirmed_win?()
    end

    test "true when winreaction is :ok and wintile is present" do
      assert %Mjw.Seat{wintile: "b1-1", winreaction: :ok}
             |> Mjw.Seat.confirmed_win?()
    end

    test "true when winreaction is :expose_ok" do
      assert %Mjw.Seat{wintile: nil, winreaction: :expose_ok}
             |> Mjw.Seat.confirmed_win?()
    end

    test "true when player is a bot" do
      assert %Mjw.Seat{wintile: nil, winreaction: nil, player_id: "bot"}
             |> Mjw.Seat.confirmed_win?()
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
          peektile: "n4-0",
          wintile: "n5-0",
          winreaction: :ok
        }
        |> Mjw.Seat.clear_win_attributes()

      assert seat.player_id == "id1"
      assert seat.player_name == "Name1"
      assert seat.concealed == ["n1-0"]
      assert seat.exposed == ["n2-0"]
      assert seat.hiddengongs == ["n3-0"]
      assert seat.peektile == "n4-0"
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

    test "true if bot" do
      assert %Mjw.Seat{winreaction: nil, player_id: "bot"} |> Mjw.Seat.win_expose?()
    end
  end

  describe "remove_from_hand" do
    test "removes tile from exposed" do
      seat =
        %Mjw.Seat{
          concealed: ["n1-0", "n2-0", "n3-0"],
          exposed: ["n1-1", "n2-1", "n3-1"],
          hiddengongs: ["n1-2", "n2-2", "n3-2"],
          peektile: "b1-0"
        }
        |> Mjw.Seat.remove_from_hand("n2-1")

      assert seat.concealed == ["n1-0", "n2-0", "n3-0"]
      assert seat.exposed == ["n1-1", "n3-1"]
      assert seat.hiddengongs == ["n1-2", "n2-2", "n3-2"]
      assert seat.peektile == "b1-0"
    end

    test "removes tile from concealed" do
      seat =
        %Mjw.Seat{
          concealed: ["n1-0", "n2-0", "n3-0"],
          exposed: ["n1-1", "n2-1", "n3-1"],
          hiddengongs: ["n1-2", "n2-2", "n3-2"],
          peektile: "b1-0"
        }
        |> Mjw.Seat.remove_from_hand("n2-0")

      assert seat.concealed == ["n1-0", "n3-0"]
      assert seat.exposed == ["n1-1", "n2-1", "n3-1"]
      assert seat.hiddengongs == ["n1-2", "n2-2", "n3-2"]
      assert seat.peektile == "b1-0"
    end

    test "removes tile from hiddengongs" do
      seat =
        %Mjw.Seat{
          concealed: ["n1-0", "n2-0", "n3-0"],
          exposed: ["n1-1", "n2-1", "n3-1"],
          hiddengongs: ["n1-2", "n2-2", "n3-2"],
          peektile: "b1-0"
        }
        |> Mjw.Seat.remove_from_hand("n2-2")

      assert seat.concealed == ["n1-0", "n2-0", "n3-0"]
      assert seat.exposed == ["n1-1", "n2-1", "n3-1"]
      assert seat.hiddengongs == ["n1-2", "n3-2"]
      assert seat.peektile == "b1-0"
    end

    test "removes tile from peektile" do
      seat =
        %Mjw.Seat{
          concealed: ["n1-0", "n2-0", "n3-0"],
          exposed: ["n1-1", "n2-1", "n3-1"],
          hiddengongs: ["n1-2", "n2-2", "n3-2"],
          peektile: "b1-0"
        }
        |> Mjw.Seat.remove_from_hand("b1-0")

      assert seat.concealed == ["n1-0", "n2-0", "n3-0"]
      assert seat.exposed == ["n1-1", "n2-1", "n3-1"]
      assert seat.hiddengongs == ["n1-2", "n2-2", "n3-2"]
      assert seat.peektile == nil
    end

    test "removes tile from wintile" do
      seat =
        %Mjw.Seat{
          concealed: ["n1-0", "n2-0", "n3-0"],
          exposed: ["n1-1", "n2-1", "n3-1"],
          hiddengongs: ["n1-2", "n2-2", "n3-2"],
          wintile: "b1-0"
        }
        |> Mjw.Seat.remove_from_hand("b1-0")

      assert seat.concealed == ["n1-0", "n2-0", "n3-0"]
      assert seat.exposed == ["n1-1", "n2-1", "n3-1"]
      assert seat.hiddengongs == ["n1-2", "n2-2", "n3-2"]
      assert seat.wintile == nil
    end

    test "no change if tile not present" do
      seat = %Mjw.Seat{
        concealed: ["n1-0", "n2-0", "n3-0"],
        exposed: ["n1-1", "n2-1", "n3-1"],
        hiddengongs: ["n1-2", "n2-2", "n3-2"],
        peektile: "b1-0"
      }

      assert Mjw.Seat.remove_from_hand(seat, "b9-0") == seat
    end
  end

  describe "add_to_concealed" do
    test "adds to concealed tiles" do
      seat =
        %Mjw.Seat{
          concealed: ["n1-0"],
          exposed: ["n1-1"]
        }
        |> Mjw.Seat.add_to_concealed("b1-0")

      assert seat.concealed == ["n1-0", "b1-0"]
      assert seat.exposed == ["n1-1"]
    end
  end

  describe "peek" do
    test "sets peektile" do
      seat = %Mjw.Seat{} |> Mjw.Seat.peek("b1-0")

      assert seat.peektile == "b1-0"
    end
  end

  describe "clear_peektile" do
    test "removes the peektile" do
      seat =
        %Mjw.Seat{
          player_id: "id1",
          player_name: "Name1",
          concealed: ["n1-0"],
          exposed: ["n2-0"],
          hiddengongs: ["n3-0"],
          peektile: "n4-0",
          wintile: "n5-0",
          winreaction: :ok
        }
        |> Mjw.Seat.clear_peektile()

      assert seat.player_id == "id1"
      assert seat.player_name == "Name1"
      assert seat.concealed == ["n1-0"]
      assert seat.exposed == ["n2-0"]
      assert seat.hiddengongs == ["n3-0"]
      assert seat.peektile == nil
      assert seat.wintile == "n5-0"
      assert seat.winreaction == :ok
    end
  end

  describe "ensure_no_dangling_peektile" do
    test "moves the peektile into the seat's concealed tiles" do
      seat =
        %Mjw.Seat{peektile: "n1-0", concealed: ["b1-0"]}
        |> Mjw.Seat.ensure_no_dangling_peektile()

      assert seat.peektile == nil
      assert seat.concealed == ["b1-0", "n1-0"]
    end

    test "doesn't modify the seat if no peektile" do
      orig_seat = %Mjw.Seat{peektile: nil, concealed: ["b1-0"]}

      seat = orig_seat |> Mjw.Seat.ensure_no_dangling_peektile()

      assert seat == orig_seat
    end
  end

  describe "preserve_hand_rearranges_for_undo" do
    test "doesn't modify seat when hands are identical" do
      seat = %Mjw.Seat{
        concealed: ["n1-0", "n1-1"],
        exposed: ["n2-0", "n2-1"],
        hiddengongs: ["n3-0", "n3-1"],
        peektile: "n4-0"
      }

      result = Mjw.Seat.preserve_hand_rearranges_for_undo(seat, seat)

      assert result == seat
    end

    test "doesn't modify seat when tiles were rearranged but not added or deleted" do
      undo_state_seat = %Mjw.Seat{
        concealed: ["n1-0", "n1-1"],
        exposed: ["n2-0", "n2-1"],
        hiddengongs: ["n3-0", "n3-1"],
        peektile: "n4-0"
      }

      seat = %Mjw.Seat{
        concealed: [],
        exposed: ["n2-0", "n2-1", "n1-1", "n1-0", "n3-1"],
        hiddengongs: ["n3-0", "n4-0"],
        peektile: nil
      }

      result = Mjw.Seat.preserve_hand_rearranges_for_undo(seat, undo_state_seat)

      assert result == seat
    end

    test "removes a tile added to a list by the undoable action" do
      undo_state_seat = %Mjw.Seat{
        concealed: ["n1-0", "n1-1"],
        exposed: ["n2-0", "n2-1"],
        hiddengongs: ["n3-0", "n3-1"],
        peektile: "n4-0"
      }

      seat = %Mjw.Seat{
        concealed: [],
        exposed: ["n2-0", "n2-1", "dz-0", "n1-1", "n1-0", "n3-1"],
        hiddengongs: ["n3-0", "n4-0"],
        peektile: nil
      }

      result = Mjw.Seat.preserve_hand_rearranges_for_undo(seat, undo_state_seat)

      assert result == %{seat | exposed: ["n2-0", "n2-1", "n1-1", "n1-0", "n3-1"]}
    end

    test "removes a tile added to peektile by the undoable action" do
      undo_state_seat = %Mjw.Seat{
        concealed: ["n1-0", "n1-1"],
        exposed: ["n2-0", "n2-1"],
        hiddengongs: ["n3-0", "n3-1"],
        peektile: "n4-0"
      }

      seat = %Mjw.Seat{
        concealed: [],
        exposed: ["n2-0", "n2-1", "n1-1", "n1-0", "n3-1"],
        hiddengongs: ["n3-0", "n4-0"],
        peektile: "dz-0"
      }

      result = Mjw.Seat.preserve_hand_rearranges_for_undo(seat, undo_state_seat)

      assert result == %{seat | peektile: nil}
    end

    test "restores a declared win from hand" do
      undo_state_seat = %Mjw.Seat{
        concealed: ["n1-0", "n1-1"],
        exposed: ["n2-0", "n2-1", "n1-0", "n1-1"],
        hiddengongs: ["n3-0", "n3-1", "n4-0"],
        peektile: nil,
        wintile: nil
      }

      seat = %Mjw.Seat{
        concealed: ["n1-1"],
        exposed: ["n2-0", "n2-1", "n1-0", "n3-0"],
        hiddengongs: ["n3-1"],
        peektile: nil,
        wintile: "n4-0"
      }

      result = Mjw.Seat.preserve_hand_rearranges_for_undo(seat, undo_state_seat)

      assert result == %{seat | wintile: nil, hiddengongs: ["n3-1", "n4-0"]}
    end

    test "restores a declared win from deck" do
      undo_state_seat = %Mjw.Seat{
        concealed: ["n1-0", "n1-1"],
        exposed: ["n2-0", "n2-1", "n1-0", "n1-1"],
        hiddengongs: ["n3-0", "n3-1", "n4-0"],
        peektile: nil,
        wintile: nil
      }

      seat = %Mjw.Seat{
        concealed: ["n1-1"],
        exposed: ["n2-0", "n2-1", "n1-0", "n3-0"],
        hiddengongs: ["n3-1", "n4-0"],
        peektile: nil,
        wintile: "dz-0"
      }

      result = Mjw.Seat.preserve_hand_rearranges_for_undo(seat, undo_state_seat)

      assert result == %{seat | wintile: nil}
    end

    test "restores a tile removed from a list by the undoable action" do
      undo_state_seat = %Mjw.Seat{
        concealed: ["n1-0", "n1-1"],
        exposed: ["n2-0", "n2-1"],
        hiddengongs: ["n3-0", "n3-1"],
        peektile: "n4-0"
      }

      seat = %Mjw.Seat{
        concealed: [],
        exposed: ["n2-0", "n2-1", "n1-1", "n1-0"],
        hiddengongs: ["n3-0", "n4-0"],
        peektile: nil
      }

      result = Mjw.Seat.preserve_hand_rearranges_for_undo(seat, undo_state_seat)

      assert result == %{seat | hiddengongs: ["n3-0", "n4-0", "n3-1"]}
    end

    test "restores a tile removed from the peektile by the undoable action" do
      undo_state_seat = %Mjw.Seat{
        concealed: ["n1-0", "n1-1"],
        exposed: ["n2-0", "n2-1"],
        hiddengongs: ["n3-0", "n3-1"],
        peektile: "n4-0"
      }

      seat = %Mjw.Seat{
        concealed: [],
        exposed: ["n2-0", "n2-1", "n1-1", "n1-0", "n3-1"],
        hiddengongs: ["n3-0"],
        peektile: nil
      }

      result = Mjw.Seat.preserve_hand_rearranges_for_undo(seat, undo_state_seat)

      assert result == %{seat | peektile: "n4-0"}
    end
  end

  describe "sort_concealed" do
    test "sorts the concealed tiles" do
      seat =
        %Mjw.Seat{concealed: ["n1-0", "b1-0", "n1-3", "dp-0"], exposed: ["n1-2", "b1-1"]}
        |> Mjw.Seat.sort_concealed()

      assert seat.concealed == ["b1-0", "dp-0", "n1-0", "n1-3"]
      assert seat.exposed == ["n1-2", "b1-1"]
    end
  end

  describe "remove_from_concealed" do
    test "removes a concealed tile" do
      seat =
        %Mjw.Seat{concealed: ["n1-0", "b1-0", "n1-3", "dp-0"], exposed: ["n1-2", "b1-1"]}
        |> Mjw.Seat.remove_from_concealed("n1-3")

      assert seat.concealed == ["n1-0", "b1-0", "dp-0"]
      assert seat.exposed == ["n1-2", "b1-1"]
    end
  end
end
