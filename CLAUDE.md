# CLAUDE.md

## Project Overview

Mahjong Wind is a multiplayer Hong Kong-style Mahjong web application built with Elixir, Phoenix Framework, and LiveView. Players can create games, invite friends, and play mahjong together in real-time with drag-and-drop interactions.

## Tech Stack

- **Elixir**
- **Phoenix Framework** with LiveView
- **PostgreSQL** (via Ecto)
- **Bandit** web server
- **Tailwind CSS** with Dart Sass for styling
- **esbuild** for JavaScript bundling
- **Deployment**: Fly.io (auto-deploys from `main` branch)

## Commands

```bash
mix setup          # Install deps and build assets (first-time setup)
mix phx.server     # Start dev server at http://localhost:4000
mix ecto.migrate   # Run database migrations
mix test           # Run tests
mix credo          # Static code analysis
```

## Game Architecture

### Module Structure
- `lib/mjw/` - Domain logic (game engine, bot AI, persistence)
- `lib/mjw_web/` - Web layer (LiveView, components, router, plugs)
- `lib/mjw_web/stores/` - `GameStore` (persistence + PubSub broadcasts)

### LiveView Pages
- `GameLive.Index` (`/`) - Game lobby
- `GameLive.Show` (`/games/:id`) - Active game board

### Authentication
Session-based only (no real user accounts). A UUID is auto-generated and stored in the browser session on first visit (`MjwWeb.Plugs.Authentication`).

### Game States (GameState module)
The game progresses through these states:
1. `:waiting_for_players` - Lobby, waiting for 4 players
2. `:picking_winds` - Players pick wind tiles to determine seating
3. `:rolling_for_first_dealer` - Dice roll to determine first dealer
4. `:rolling_for_deal` - Dealer rolls to determine deal position
5. `:drawing` - Current player draws a tile
6. `:discarding` - Current player discards a tile
7. `:win_declared` - A player has declared a win

### Turn States (within Game struct)
- `:rolling` - Waiting for dice roll
- `:drawing` - Player's turn to draw
- `:discarding` - Player's turn to discard

### Real-time Updates
- Uses Phoenix PubSub for broadcasting game changes
- `GameStore` handles persistence and broadcasts
- LiveView subscribes to game-specific topics (`game:{id}`)
- Lobby subscribes to `games` topic for new/removed games

### Tile Naming Convention
Tiles use short string IDs: `b1-b9` (bamboo), `c1-c9` (circles), `n1-n9` (numbers), `df`/`dp`/`dz` (dragons), `we`/`ws`/`ww`/`wn` (winds). Each tile gets a unique numeric suffix `0-3` (e.g., `dp-0` through `dp-3` for the 4 plate tiles).

### Bot System
- `BotService` is a GenServer that queues delayed bot actions
- Bots use `BotStrategy` for decision-making
- Bots can be paused/resumed during gameplay

### Stale Game Cleanup
`StaleGameSweeper` is a GenServer that auto-deletes games inactive for 60+ minutes, running every 2 minutes.

## Testing

Tests are in the `test/` mirroring the `lib/` structure. Any significant code changes require adding appropriate tests.

## Frontend Notes

- Drag-and-drop via SortableJS (`assets/vendor/sortable.js`)
- Custom drag hook in `assets/js/dragHook.js`
- Confetti animation for wins (`assets/js/confetti.js`)
- Tailwind CSS for styling with custom SCSS in `assets/css/`

## Environment Configuration

- `config/dev.exs` - Development settings
- `config/test.exs` - Test settings
- `config/prod.exs` - Production settings
- `config/runtime.exs` - Runtime configuration (`DATABASE_URL`, etc.)
