defmodule Mjw.Die do
  defstruct [:value]

  def roll_three() do
    1..3
    |> Enum.map(fn _ -> random() end)
  end

  @doc """
  Add up the values of the dice
  """
  def sum(dice) do
    dice |> Enum.map(& &1.value) |> Enum.sum()
  end

  defp random() do
    %__MODULE__{value: random_value()}
  end

  defp random_value() do
    1..6 |> Enum.random()
  end
end
