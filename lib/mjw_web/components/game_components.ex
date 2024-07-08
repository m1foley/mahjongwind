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

  attr(:seatno, :integer, required: true)
  # seat is a decorator with extra attributes around Mjw.Seat
  attr(:seat, :map, required: true)
  attr(:game, Mjw.Game, required: true)
  attr(:turn_glow_seatno, :integer, required: true)
  attr(:player_seats_finalized, :boolean, required: true)
  attr(:game_state, :atom, required: true)

  def opponent_seat(assigns) do
    ~H"""
    <div id={"seat-#{@seatno}"}>
      <div class="tiles flex-wrap">
        <div class="player-name-container">
          <div class={"player-name turn-glow-#{if @turn_glow_seatno == @seat.seatno, do: "t"}"}>
            <%= @seat.player_name %>
          </div>

          <div class="player-icons">
            <%= if @seat.seatno == 0 && @player_seats_finalized do %>
              <div
                class="firstdealer-indicator"
                title="First dealer. Game wind changes when the deal circles back to them."
              >
                庄
              </div>
            <% end %>

            <%= if @seat.seatno == @game.dealer_seatno do %>
              <div
                class="dealer-indicator"
                title={"Dealer#{if @game.dealer_win_count > 0, do: " (time ##{@game.dealer_win_count + 1})"}"}
              >
                Dealer<%= if @game.dealer_win_count > 0 do %>
                  <sup><%= @game.dealer_win_count + 1 %></sup>
                <% end %>
              </div>
            <% end %>
            <%= if @game_state != :rolling_for_deal && @seat.seatno == @game.dealpick_seatno do %>
              <img
                src="/images/staircase.png"
                alt=""
                title="This staircase is the end of the deck (used to determine player wind)"
                class={"dealpickstaircase inline-block mx-auto relative bottom-1#{if @seat.seatno == @game.dealer_seatno, do: " pl-1"}"}
              />
            <% end %>
          </div>
        </div>

        <div class="exposed-tiles">
          <%= for tile <- @seat.exposed do %>
            <.tile id={tile} tile={tile} />
          <% end %>
        </div>

        <div class="hiddengong-tiles">
          <%= if @seat.win_expose do %>
            <%= for tile <- @seat.hiddengongs do %>
              <.tile tile={tile} class="opacity-50" />
            <% end %>
          <% else %>
            <%= for _tile <- @seat.hiddengongs do %>
              <.concealed_tile class="tile" />
            <% end %>
          <% end %>
        </div>

        <div class="line-break"></div>

        <div class="concealed-tiles">
          <%= if @seat.win_expose do %>
            <%= for tile <- @seat.concealed do %>
              <.tile tile={tile} />
            <% end %>
          <% else %>
            <%= for _tile <- @seat.concealed do %>
              <.concealed_tile class="tile" />
            <% end %>
          <% end %>
        </div>

        <%= if @seat.wintile do %>
          <div class="wintile-tiles">
            <.tile tile={@seat.wintile} class="ml-8" />
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
