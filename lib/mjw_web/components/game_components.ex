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

  # seat is a decorator with extra attributes around Mjw.Seat
  attr(:seat, :map, required: true)
  attr(:current_user_drawing, :boolean, required: true)
  attr(:win_declared_seatno, :integer, required: true)
  attr(:current_user_seatno, :integer, required: true)
  attr(:current_user_discarding, :boolean, required: true)
  attr(:available_discard_tile, :boolean, required: true)

  def current_user_seat(assigns) do
    ~H"""
    <div id="seat-0">
      <div class={"tiles flex-wrap turn-glow-0-#{if @current_user_drawing, do: "t"}"}>
        <div
          id="hiddengongs-0"
          phx-hook="Drag"
          phx-target="#game"
          class={"hiddengong-tiles dropzone#{if @win_declared_seatno && @win_declared_seatno != @current_user_seatno && @seat.win_expose, do: " exposed-loser-hand"}"}
        >
          <%= for tile <- @seat.hiddengongs do %>
            <.tile id={tile} tile={tile} class="draggable" />
          <% end %>
          <div class="dropzone-description">Hidden gong</div>
        </div>

        <div id="exposed-0" phx-hook="Drag" phx-target="#game" class="exposed-tiles dropzone">
          <%= for tile <- @seat.exposed do %>
            <.tile id={tile} tile={tile} class="draggable" />
          <% end %>
          <div class="dropzone-description">Exposed tiles</div>
        </div>

        <div
          id="wintile-0"
          phx-hook="Drag"
          phx-target="#game"
          class={"wintile-tiles#{if !@win_declared_seatno || @win_declared_seatno == @current_user_seatno, do: " dropzone"}"}
        >
          <%= if @seat.wintile do %>
            <.tile id={@seat.wintile} tile={@seat.wintile} class="cursor-not-allowed" />
          <% end %>
          <%= if !@win_declared_seatno || @win_declared_seatno == @current_user_seatno do %>
            <div class="dropzone-description">Winning tile</div>
          <% end %>
        </div>

        <div class="line-break"></div>

        <div
          id="concealed-0"
          phx-hook="Drag"
          phx-target="#game"
          class={"concealed-tiles dropzone current-user-discarding-#{if @current_user_discarding, do: "t"} enable-pull-from-discards-#{if @available_discard_tile, do: "t"} concealed-loser-hand-#{if @win_declared_seatno && @win_declared_seatno != @current_user_seatno && !@seat.win_expose, do: "t"}"}
        >
          <%= for tile <- @seat.concealed do %>
            <.tile id={tile} tile={tile} class="draggable" />
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  attr(:seatno, :integer, required: true)

  def wall(assigns) do
    ~H"""
    <div id={"walltiles-#{@seatno}"}>
      <div class="tiles flex-wrap">
        <div class="wall-tiles wall-tiles-1">
          <%= for _ <- 0..15 do %>
            <.concealed_tile class="walltile" />
          <% end %>
        </div>
        <div class="line-break"></div>
        <div class="wall-tiles">
          <%= for _ <- 0..15 do %>
            <.concealed_tile class="walltile" />
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end
