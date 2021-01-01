defmodule Mjw.Die do
  defstruct [:value, :unicode]

  @unicodes %{1 => "⚀", 2 => "⚁", 3 => "⚂", 4 => "⚃", 5 => "⚄", 6 => "⚅"}

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
    {value, unicode} =
      @unicodes
      |> Enum.random()

    %__MODULE__{value: value, unicode: unicode}
  end
end
