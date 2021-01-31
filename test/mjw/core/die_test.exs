defmodule Mjw.DieTest do
  use ExUnit.Case, async: true

  describe "roll_three" do
    test "rolls 3 random dice" do
      dice = Mjw.Die.roll_three()

      assert length(dice) == 3
      assert Enum.all?(dice, & &1.value)
      sum = Mjw.Die.sum(dice)
      assert sum >= 1 * 3
      assert sum <= 6 * 3
    end
  end

  describe "sum" do
    test "adds the values of the dice" do
      dice = [
        %Mjw.Die{value: 1},
        %Mjw.Die{value: 1},
        %Mjw.Die{value: 6}
      ]

      assert Mjw.Die.sum(dice) == 8
    end
  end
end
