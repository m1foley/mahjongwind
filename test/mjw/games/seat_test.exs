defmodule Mjw.Games.SeatTest do
  use ExUnit.Case, async: true

  describe "empty?" do
    test "true if player_id is nil" do
      seat = %Mjw.Games.Seat{}
      assert Mjw.Games.Seat.empty?(seat)
    end

    test "false if player_id is present" do
      seat = %Mjw.Games.Seat{player_id: "123"}
      refute Mjw.Games.Seat.empty?(seat)
    end
  end

  describe "seat_player" do
    test "seats a player in an empty seat" do
      seat =
        %Mjw.Games.Seat{}
        |> Mjw.Games.Seat.seat_player("new_id", "New Name")

      assert seat.player_id == "new_id"
      assert seat.player_name == "New Name"
      assert seat.concealed == []
      assert seat.exposed == []
      assert seat.hiddengongs == []
    end

    test "replaces an existing player with the new player" do
      seat =
        %Mjw.Games.Seat{
          player_id: "old_id",
          player_name: "Old Name",
          concealed: ["n1-0"],
          exposed: ["n2-0"],
          hiddengongs: ["n3-0"]
        }
        |> Mjw.Games.Seat.seat_player("new_id", "New Name")

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
        %Mjw.Games.Seat{}
        |> Mjw.Games.Seat.seat_bot("Bot Name")

      assert Mjw.Games.Seat.bot?(seat)
      assert seat.player_name == "Bot Name"
      assert seat.concealed == []
      assert seat.exposed == []
      assert seat.hiddengongs == []
    end

    test "replaces an existing player with the new bot" do
      seat =
        %Mjw.Games.Seat{
          player_id: "old_id",
          player_name: "Old Name",
          concealed: ["n1-0"],
          exposed: ["n2-0"],
          hiddengongs: ["n3-0"]
        }
        |> Mjw.Games.Seat.seat_bot("Bot Name")

      assert Mjw.Games.Seat.bot?(seat)
      assert seat.player_name == "Bot Name"
      assert seat.concealed == ["n1-0"]
      assert seat.exposed == ["n2-0"]
      assert seat.hiddengongs == ["n3-0"]
    end
  end

  describe "bot" do
    test "true if player_id is the reserved bot id" do
      seat = %Mjw.Games.Seat{player_id: "bot"}
      assert Mjw.Games.Seat.bot?(seat)
    end

    test "false if player_id is not the reserved bot id" do
      seat = %Mjw.Games.Seat{player_id: "other_id"}
      refute Mjw.Games.Seat.bot?(seat)
    end

    test "false if player_id is nil" do
      seat = %Mjw.Games.Seat{}
      refute Mjw.Games.Seat.bot?(seat)
    end
  end

  describe "pick_wind" do
    test "picks a wind for a player" do
      seat =
        %Mjw.Games.Seat{}
        |> Mjw.Games.Seat.pick_wind("ws", 2)

      assert seat.picked_wind == "ws"
      assert seat.picked_wind_idx == 2
    end
  end

  describe "evacuate_player" do
    test "removes the player from the seat" do
      seat =
        %Mjw.Games.Seat{
          player_id: "id1",
          player_name: "Name1",
          concealed: ["n1-0"],
          exposed: ["n2-0"],
          hiddengongs: ["n3-0"]
        }
        |> Mjw.Games.Seat.evacuate_player()

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
        %Mjw.Games.Seat{
          player_id: "id1",
          player_name: "Name1",
          concealed: ["n1-0"],
          exposed: ["n2-0"],
          hiddengongs: ["n3-0"],
          peektile: "n4-0",
          wintile: "n5-0",
          winreaction: :ok
        }
        |> Mjw.Games.Seat.clear_tiles()

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
      refute %Mjw.Games.Seat{wintile: nil, winreaction: nil}
             |> Mjw.Games.Seat.confirmed_win?()
    end

    test "false when winreaction is :expose" do
      refute %Mjw.Games.Seat{wintile: nil, winreaction: :expose}
             |> Mjw.Games.Seat.confirmed_win?()
    end

    test "true when winreaction is :ok" do
      assert %Mjw.Games.Seat{wintile: nil, winreaction: :ok}
             |> Mjw.Games.Seat.confirmed_win?()
    end

    test "true when winreaction is :ok and wintile is present" do
      assert %Mjw.Games.Seat{wintile: "b1-1", winreaction: :ok}
             |> Mjw.Games.Seat.confirmed_win?()
    end

    test "true when winreaction is :expose_ok" do
      assert %Mjw.Games.Seat{wintile: nil, winreaction: :expose_ok}
             |> Mjw.Games.Seat.confirmed_win?()
    end

    test "true when player is a bot" do
      assert %Mjw.Games.Seat{wintile: nil, winreaction: nil, player_id: "bot"}
             |> Mjw.Games.Seat.confirmed_win?()
    end
  end

  describe "confirm_win" do
    test "changes winreaction from nil -> :ok" do
      seat = %Mjw.Games.Seat{winreaction: nil} |> Mjw.Games.Seat.confirm_win()
      assert seat.winreaction == :ok
    end

    test "doesn't change winreaction from :ok" do
      seat = %Mjw.Games.Seat{winreaction: :ok} |> Mjw.Games.Seat.confirm_win()
      assert seat.winreaction == :ok
    end

    test "changes winreaction from :expose -> :expose_ok" do
      seat = %Mjw.Games.Seat{winreaction: :expose} |> Mjw.Games.Seat.confirm_win()
      assert seat.winreaction == :expose_ok
    end

    test "doesn't change winreaction from :expose_ok" do
      seat = %Mjw.Games.Seat{winreaction: :expose_ok} |> Mjw.Games.Seat.confirm_win()
      assert seat.winreaction == :expose_ok
    end
  end

  describe "expose_loser_hand" do
    test "changes winreaction from nil -> :expose" do
      seat = %Mjw.Games.Seat{winreaction: nil} |> Mjw.Games.Seat.expose_loser_hand()
      assert seat.winreaction == :expose
    end

    test "changes winreaction from :ok -> :expose_ok" do
      seat = %Mjw.Games.Seat{winreaction: :ok} |> Mjw.Games.Seat.expose_loser_hand()
      assert seat.winreaction == :expose_ok
    end

    test "doesn't change winreaction from :expose" do
      seat = %Mjw.Games.Seat{winreaction: :expose} |> Mjw.Games.Seat.expose_loser_hand()
      assert seat.winreaction == :expose
    end

    test "doesn't change winreaction from :expose_ok" do
      seat = %Mjw.Games.Seat{winreaction: :expose_ok} |> Mjw.Games.Seat.expose_loser_hand()
      assert seat.winreaction == :expose_ok
    end
  end

  describe "clear_win_attributes" do
    test "removes the attributes related to declaring/confirming a win" do
      seat =
        %Mjw.Games.Seat{
          player_id: "id1",
          player_name: "Name1",
          concealed: ["n1-0"],
          exposed: ["n2-0"],
          hiddengongs: ["n3-0"],
          peektile: "n4-0",
          wintile: "n5-0",
          winreaction: :ok
        }
        |> Mjw.Games.Seat.clear_win_attributes()

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
        %Mjw.Games.Seat{wintile: nil, winreaction: nil}
        |> Mjw.Games.Seat.declare_win("b4-1")

      assert seat.wintile == "b4-1"
      assert seat.winreaction == :expose
    end
  end

  describe "declared_win?" do
    test "true if declared win" do
      seat = %Mjw.Games.Seat{wintile: "n4-0", winreaction: :expose}
      assert seat |> Mjw.Games.Seat.declared_win?()
    end

    test "false if not declared win" do
      seat = %Mjw.Games.Seat{wintile: nil, winreaction: :ok}
      refute seat |> Mjw.Games.Seat.declared_win?()
    end
  end

  describe "win_expose?" do
    test "true if expose or expose_ok" do
      assert %Mjw.Games.Seat{winreaction: :expose} |> Mjw.Games.Seat.win_expose?()
      assert %Mjw.Games.Seat{winreaction: :expose_ok} |> Mjw.Games.Seat.win_expose?()
    end

    test "false if not exposed" do
      refute %Mjw.Games.Seat{winreaction: nil} |> Mjw.Games.Seat.win_expose?()
      refute %Mjw.Games.Seat{winreaction: :ok} |> Mjw.Games.Seat.win_expose?()
    end

    test "true if bot" do
      assert %Mjw.Games.Seat{winreaction: nil, player_id: "bot"} |> Mjw.Games.Seat.win_expose?()
    end
  end

  describe "remove_from_hand" do
    test "removes tile from exposed" do
      seat =
        %Mjw.Games.Seat{
          concealed: ["n1-0", "n2-0", "n3-0"],
          exposed: ["n1-1", "n2-1", "n3-1"],
          hiddengongs: ["n1-2", "n2-2", "n3-2"],
          peektile: "b1-0"
        }
        |> Mjw.Games.Seat.remove_from_hand("n2-1")

      assert seat.concealed == ["n1-0", "n2-0", "n3-0"]
      assert seat.exposed == ["n1-1", "n3-1"]
      assert seat.hiddengongs == ["n1-2", "n2-2", "n3-2"]
      assert seat.peektile == "b1-0"
    end

    test "removes tile from concealed" do
      seat =
        %Mjw.Games.Seat{
          concealed: ["n1-0", "n2-0", "n3-0"],
          exposed: ["n1-1", "n2-1", "n3-1"],
          hiddengongs: ["n1-2", "n2-2", "n3-2"],
          peektile: "b1-0"
        }
        |> Mjw.Games.Seat.remove_from_hand("n2-0")

      assert seat.concealed == ["n1-0", "n3-0"]
      assert seat.exposed == ["n1-1", "n2-1", "n3-1"]
      assert seat.hiddengongs == ["n1-2", "n2-2", "n3-2"]
      assert seat.peektile == "b1-0"
    end

    test "removes tile from hiddengongs" do
      seat =
        %Mjw.Games.Seat{
          concealed: ["n1-0", "n2-0", "n3-0"],
          exposed: ["n1-1", "n2-1", "n3-1"],
          hiddengongs: ["n1-2", "n2-2", "n3-2"],
          peektile: "b1-0"
        }
        |> Mjw.Games.Seat.remove_from_hand("n2-2")

      assert seat.concealed == ["n1-0", "n2-0", "n3-0"]
      assert seat.exposed == ["n1-1", "n2-1", "n3-1"]
      assert seat.hiddengongs == ["n1-2", "n3-2"]
      assert seat.peektile == "b1-0"
    end

    test "removes tile from peektile" do
      seat =
        %Mjw.Games.Seat{
          concealed: ["n1-0", "n2-0", "n3-0"],
          exposed: ["n1-1", "n2-1", "n3-1"],
          hiddengongs: ["n1-2", "n2-2", "n3-2"],
          peektile: "b1-0"
        }
        |> Mjw.Games.Seat.remove_from_hand("b1-0")

      assert seat.concealed == ["n1-0", "n2-0", "n3-0"]
      assert seat.exposed == ["n1-1", "n2-1", "n3-1"]
      assert seat.hiddengongs == ["n1-2", "n2-2", "n3-2"]
      assert seat.peektile == nil
    end

    test "removes tile from wintile" do
      seat =
        %Mjw.Games.Seat{
          concealed: ["n1-0", "n2-0", "n3-0"],
          exposed: ["n1-1", "n2-1", "n3-1"],
          hiddengongs: ["n1-2", "n2-2", "n3-2"],
          wintile: "b1-0"
        }
        |> Mjw.Games.Seat.remove_from_hand("b1-0")

      assert seat.concealed == ["n1-0", "n2-0", "n3-0"]
      assert seat.exposed == ["n1-1", "n2-1", "n3-1"]
      assert seat.hiddengongs == ["n1-2", "n2-2", "n3-2"]
      assert seat.wintile == nil
    end

    test "no change if tile not present" do
      seat = %Mjw.Games.Seat{
        concealed: ["n1-0", "n2-0", "n3-0"],
        exposed: ["n1-1", "n2-1", "n3-1"],
        hiddengongs: ["n1-2", "n2-2", "n3-2"],
        peektile: "b1-0"
      }

      assert Mjw.Games.Seat.remove_from_hand(seat, "b9-0") == seat
    end
  end

  describe "add_to_concealed" do
    test "adds to concealed tiles" do
      seat =
        %Mjw.Games.Seat{
          concealed: ["n1-0"],
          exposed: ["n1-1"]
        }
        |> Mjw.Games.Seat.add_to_concealed("b1-0")

      assert seat.concealed == ["n1-0", "b1-0"]
      assert seat.exposed == ["n1-1"]
    end
  end

  describe "peek" do
    test "sets peektile" do
      seat = %Mjw.Games.Seat{} |> Mjw.Games.Seat.peek("b1-0")

      assert seat.peektile == "b1-0"
    end
  end

  describe "clear_peektile" do
    test "removes the peektile" do
      seat =
        %Mjw.Games.Seat{
          player_id: "id1",
          player_name: "Name1",
          concealed: ["n1-0"],
          exposed: ["n2-0"],
          hiddengongs: ["n3-0"],
          peektile: "n4-0",
          wintile: "n5-0",
          winreaction: :ok
        }
        |> Mjw.Games.Seat.clear_peektile()

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
        %Mjw.Games.Seat{peektile: "n1-0", concealed: ["b1-0"]}
        |> Mjw.Games.Seat.ensure_no_dangling_peektile()

      assert seat.peektile == nil
      assert seat.concealed == ["b1-0", "n1-0"]
    end

    test "doesn't modify the seat if no peektile" do
      orig_seat = %Mjw.Games.Seat{peektile: nil, concealed: ["b1-0"]}

      seat = orig_seat |> Mjw.Games.Seat.ensure_no_dangling_peektile()

      assert seat == orig_seat
    end
  end

  describe "merge_for_undo" do
    test "doesn't modify seat when hands are identical" do
      seat = %Mjw.Games.Seat{
        concealed: ["n1-0", "n1-1"],
        exposed: ["n2-0", "n2-1"],
        hiddengongs: ["n3-0", "n3-1"],
        peektile: "n4-0"
      }

      result = Mjw.Games.Seat.merge_for_undo(seat, seat)

      assert result == seat
    end

    test "doesn't modify seat when tiles were rearranged but not added or deleted" do
      undo_state_seat = %Mjw.Games.Seat{
        concealed: ["n1-0", "n1-1"],
        exposed: ["n2-0", "n2-1"],
        hiddengongs: ["n3-0", "n3-1"],
        peektile: "n4-0"
      }

      seat = %Mjw.Games.Seat{
        concealed: [],
        exposed: ["n2-0", "n2-1", "n1-1", "n1-0", "n3-1"],
        hiddengongs: ["n3-0", "n4-0"],
        peektile: nil
      }

      result = Mjw.Games.Seat.merge_for_undo(seat, undo_state_seat)

      assert result == seat
    end

    test "removes a tile added to a list by the undoable action" do
      undo_state_seat = %Mjw.Games.Seat{
        concealed: ["n1-0", "n1-1"],
        exposed: ["n2-0", "n2-1"],
        hiddengongs: ["n3-0", "n3-1"],
        peektile: "n4-0"
      }

      seat = %Mjw.Games.Seat{
        concealed: [],
        exposed: ["n2-0", "n2-1", "dz-0", "n1-1", "n1-0", "n3-1"],
        hiddengongs: ["n3-0", "n4-0"],
        peektile: nil
      }

      result = Mjw.Games.Seat.merge_for_undo(seat, undo_state_seat)

      assert result == %{seat | exposed: ["n2-0", "n2-1", "n1-1", "n1-0", "n3-1"]}
    end

    test "removes a tile added to peektile by the undoable action" do
      undo_state_seat = %Mjw.Games.Seat{
        concealed: ["n1-0", "n1-1"],
        exposed: ["n2-0", "n2-1"],
        hiddengongs: ["n3-0", "n3-1"],
        peektile: "n4-0"
      }

      seat = %Mjw.Games.Seat{
        concealed: [],
        exposed: ["n2-0", "n2-1", "n1-1", "n1-0", "n3-1"],
        hiddengongs: ["n3-0", "n4-0"],
        peektile: "dz-0"
      }

      result = Mjw.Games.Seat.merge_for_undo(seat, undo_state_seat)

      assert result == %{seat | peektile: nil}
    end

    test "restores a declared win from hand" do
      undo_state_seat = %Mjw.Games.Seat{
        concealed: ["n1-0", "n1-1"],
        exposed: ["n2-0", "n2-1", "n1-0", "n1-1"],
        hiddengongs: ["n3-0", "n3-1", "n4-0"],
        peektile: nil,
        wintile: nil
      }

      seat = %Mjw.Games.Seat{
        concealed: ["n1-1"],
        exposed: ["n2-0", "n2-1", "n1-0", "n3-0"],
        hiddengongs: ["n3-1"],
        peektile: nil,
        wintile: "n4-0"
      }

      result = Mjw.Games.Seat.merge_for_undo(seat, undo_state_seat)

      assert result == %{seat | wintile: nil, hiddengongs: ["n3-1", "n4-0"]}
    end

    test "restores a declared win from deck" do
      undo_state_seat = %Mjw.Games.Seat{
        concealed: ["n1-0", "n1-1"],
        exposed: ["n2-0", "n2-1", "n1-0", "n1-1"],
        hiddengongs: ["n3-0", "n3-1", "n4-0"],
        peektile: nil,
        wintile: nil
      }

      seat = %Mjw.Games.Seat{
        concealed: ["n1-1"],
        exposed: ["n2-0", "n2-1", "n1-0", "n3-0"],
        hiddengongs: ["n3-1", "n4-0"],
        peektile: nil,
        wintile: "dz-0"
      }

      result = Mjw.Games.Seat.merge_for_undo(seat, undo_state_seat)

      assert result == %{seat | wintile: nil}
    end

    test "restores a tile removed from a list by the undoable action" do
      undo_state_seat = %Mjw.Games.Seat{
        concealed: ["n1-0", "n1-1"],
        exposed: ["n2-0", "n2-1"],
        hiddengongs: ["n3-0", "n3-1"],
        peektile: "n4-0"
      }

      seat = %Mjw.Games.Seat{
        concealed: [],
        exposed: ["n2-0", "n2-1", "n1-1", "n1-0"],
        hiddengongs: ["n3-0", "n4-0"],
        peektile: nil
      }

      result = Mjw.Games.Seat.merge_for_undo(seat, undo_state_seat)

      assert result == %{seat | hiddengongs: ["n3-0", "n3-1", "n4-0"]}
    end

    test "restores a tile removed from the peektile by the undoable action" do
      undo_state_seat = %Mjw.Games.Seat{
        concealed: ["n1-0", "n1-1"],
        exposed: ["n2-0", "n2-1"],
        hiddengongs: ["n3-0", "n3-1"],
        peektile: "n4-0"
      }

      seat = %Mjw.Games.Seat{
        concealed: [],
        exposed: ["n2-0", "n2-1", "n1-1", "n1-0", "n3-1"],
        hiddengongs: ["n3-0"],
        peektile: nil
      }

      result = Mjw.Games.Seat.merge_for_undo(seat, undo_state_seat)

      assert result == %{seat | peektile: "n4-0"}
    end
  end

  describe "sort_concealed" do
    test "sorts the concealed tiles with special tiles last" do
      seat =
        %Mjw.Games.Seat{
          concealed: [
            "n1-0",
            "we-0",
            "we-1",
            "b9-0",
            "b9-1",
            "n1-3",
            "dp-0",
            "ww-0",
            "c1-0",
            "b1-3"
          ],
          exposed: ["n1-2", "b1-1"]
        }
        |> Mjw.Games.Seat.sort_concealed()

      assert seat.concealed == [
               "n1-0",
               "n1-3",
               "c1-0",
               "b1-3",
               "b9-0",
               "b9-1",
               "we-0",
               "we-1",
               "ww-0",
               "dp-0"
             ]

      assert seat.exposed == ["n1-2", "b1-1"]
    end
  end

  describe "remove_from_concealed" do
    test "removes a concealed tile" do
      seat =
        %Mjw.Games.Seat{concealed: ["n1-0", "b1-0", "n1-3", "dp-0"], exposed: ["n1-2", "b1-1"]}
        |> Mjw.Games.Seat.remove_from_concealed("n1-3")

      assert seat.concealed == ["n1-0", "b1-0", "dp-0"]
      assert seat.exposed == ["n1-2", "b1-1"]
    end
  end

  describe "merge_server_client_seats" do
    test "returns client seat when server and client seats match exactly" do
      server_seat = %Mjw.Games.Seat{
        concealed: ["n1-0", "b1-0", "c1-0"],
        exposed: ["n2-0", "b2-0"],
        hiddengongs: ["n3-0"],
        peektile: "b3-0",
        wintile: nil
      }

      client_seat = %Mjw.Games.Seat{
        concealed: ["n1-0", "b1-0", "c1-0"],
        exposed: ["n2-0", "b2-0"],
        hiddengongs: ["n3-0"],
        peektile: "b3-0",
        wintile: nil
      }

      result = Mjw.Games.Seat.merge_server_client_seats(server_seat, client_seat)

      assert result == client_seat
    end

    test "returns client seat when concealed tiles are same but in different order" do
      server_seat = %Mjw.Games.Seat{
        concealed: ["n1-0", "b1-0", "c1-0"],
        exposed: ["n2-0", "b2-0"],
        hiddengongs: ["n3-0"],
        peektile: "b3-0",
        wintile: nil
      }

      client_seat = %Mjw.Games.Seat{
        concealed: ["c1-0", "n1-0", "b1-0"],
        exposed: ["n2-0", "b2-0"],
        hiddengongs: ["n3-0"],
        peektile: "b3-0",
        wintile: nil
      }

      result = Mjw.Games.Seat.merge_server_client_seats(server_seat, client_seat)

      assert result == client_seat
    end

    test "merges when client has extra concealed tiles" do
      server_seat = %Mjw.Games.Seat{
        concealed: ["n1-0", "b1-0"],
        exposed: ["n2-0"],
        hiddengongs: [],
        peektile: nil,
        wintile: nil
      }

      client_seat = %Mjw.Games.Seat{
        concealed: ["n1-0", "b1-0", "c1-0"],
        exposed: ["n2-0"],
        hiddengongs: [],
        peektile: nil,
        wintile: nil
      }

      result = Mjw.Games.Seat.merge_server_client_seats(server_seat, client_seat)

      assert result.concealed == ["n1-0", "b1-0"]
      assert result.exposed == ["n2-0"]
      assert result.hiddengongs == []
    end

    test "merges when server has extra concealed tiles" do
      server_seat = %Mjw.Games.Seat{
        concealed: ["n1-0", "b1-0", "c1-0"],
        exposed: ["n2-0"],
        hiddengongs: [],
        peektile: nil,
        wintile: nil
      }

      client_seat = %Mjw.Games.Seat{
        concealed: ["n1-0", "b1-0"],
        exposed: ["n2-0"],
        hiddengongs: [],
        peektile: nil,
        wintile: nil
      }

      result = Mjw.Games.Seat.merge_server_client_seats(server_seat, client_seat)

      assert result.concealed == ["n1-0", "b1-0", "c1-0"]
      assert result.exposed == ["n2-0"]
      assert result.hiddengongs == []
    end

    test "preserves client ordering when merging with server additions" do
      server_seat = %Mjw.Games.Seat{
        concealed: ["n1-0", "b1-0", "c1-0", "n2-0"],
        exposed: ["n3-0"],
        hiddengongs: [],
        peektile: nil,
        wintile: nil
      }

      client_seat = %Mjw.Games.Seat{
        concealed: ["c1-0", "n1-0", "b1-0"],
        exposed: ["n3-0"],
        hiddengongs: [],
        peektile: nil,
        wintile: nil
      }

      result = Mjw.Games.Seat.merge_server_client_seats(server_seat, client_seat)

      # Should preserve client ordering for existing tiles and append new ones
      assert result.concealed == ["c1-0", "n1-0", "b1-0", "n2-0"]
      assert result.exposed == ["n3-0"]
    end

    test "handles complete mismatch in concealed tiles" do
      server_seat = %Mjw.Games.Seat{
        concealed: ["n1-0", "b1-0"],
        exposed: ["n2-0"],
        hiddengongs: [],
        peektile: nil,
        wintile: nil
      }

      client_seat = %Mjw.Games.Seat{
        concealed: ["c1-0", "c2-0"],
        exposed: ["n2-0"],
        hiddengongs: [],
        peektile: nil,
        wintile: nil
      }

      result = Mjw.Games.Seat.merge_server_client_seats(server_seat, client_seat)

      # Should use server tiles when there's a complete mismatch
      assert result.concealed == ["n1-0", "b1-0"]
      assert result.exposed == ["n2-0"]
    end

    test "handles mismatch in exposed tiles" do
      server_seat = %Mjw.Games.Seat{
        concealed: ["n1-0"],
        exposed: ["n2-0", "b2-0"],
        hiddengongs: [],
        peektile: nil,
        wintile: nil
      }

      client_seat = %Mjw.Games.Seat{
        concealed: ["n1-0"],
        exposed: ["n2-0"],
        hiddengongs: [],
        peektile: nil,
        wintile: nil
      }

      result = Mjw.Games.Seat.merge_server_client_seats(server_seat, client_seat)

      # Should use server seat data when exposed tiles don't match
      assert result == server_seat
    end

    test "handles mismatch in peektile" do
      server_seat = %Mjw.Games.Seat{
        concealed: ["n1-0"],
        exposed: [],
        hiddengongs: [],
        peektile: "b1-0",
        wintile: nil
      }

      client_seat = %Mjw.Games.Seat{
        concealed: ["n1-0"],
        exposed: [],
        hiddengongs: [],
        peektile: nil,
        wintile: nil
      }

      result = Mjw.Games.Seat.merge_server_client_seats(server_seat, client_seat)

      # Should use server seat data when peektile doesn't match
      assert result == server_seat
    end
  end
end
