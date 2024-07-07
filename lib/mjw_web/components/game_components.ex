defmodule MjwWeb.GameComponents do
  use Phoenix.Component

  attr(:tile, :string, required: true)
  attr(:class, :string, default: nil)
  attr(:id, :string, default: nil)

  def tile(assigns) do
    ~H"""
    <img
      id={@id}
      src={"/images/tiles/#{Mjw.Tile.without_id(@tile)}.png"}
      alt=""
      class={["tile", @class]}
    />
    """
  end

  attr(:class, :string, default: nil)
  attr(:rest, :global)

  def concealed_tile(assigns) do
    ~H"""
    <img src="/images/tiles/concealed.png" alt="" class={@class} {@rest} />
    """
  end
end
