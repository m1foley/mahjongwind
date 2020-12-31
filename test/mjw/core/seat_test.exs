defmodule Mjw.SeatTest do
  use ExUnit.Case, async: true

  describe "empty?" do
    test "true if user_id is nil" do
      seat = %Mjw.Seat{}
      assert Mjw.Seat.empty?(seat)
    end

    test "false if user_id is present" do
      seat = %Mjw.Seat{user_id: "123"}
      refute Mjw.Seat.empty?(seat)
    end
  end
end
