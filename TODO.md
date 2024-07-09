# TODO

- 2-click instead of drag & drop. First click will pause other players.
- Display everyone's wind direction instead of staircase
- Change "Pause bots" to "Pause" to pause humans too. Allows time to pick tile.
- Slider for tile size (so users don't have to increase font size)
- Real user accounts instead of just web sessions
- Shrink tile sizes on mobile
- Lobby not receiving bot player added
- Refactor: Denormalize seatno as a seat attribute
- Point out game menu on first load
- Make seating process less confusing
- Sound
- "Sort" button after deal (disappears if player moves any tile)
- Indicate when deck is running low
- Experiment with more CSS animations: dealing the tiles, etc.
- Exclude bots (e.g., PresidentCardGames uses phone numbers)
- Support more Mahjong rule sets (flower tiles, no game wind, etc.)
- Instructions
- Protect games from being erased during deploys
- Test Internet Explorer
- Automatically expire games
- Refactor: Extract some common HTML elements (e.g., tile images) to components
- Only show "hidden gong" if actually possible
- Add titles to tile images ("5 of bamboo"). good for game log where it's small
- Add "Waiting for Mei..." to game log when waiting, then delete when no longer waiting
- Make Pause button easier to click (click on board center?)
- Animated "waiting" dots next to player name when waiting for them
- Allow dragging from decktile to exposed tiles (adding onto a pong)
- Animate deal: 4 at a time goes into people's hand
- Sanity check for (possible race condition) bug: rearranging hand leads to duplicate tiles. Last time it happened after peek tile got put into hand, and user drag & dropped that new tile.
- Remember sorted hand in browser so it doesn't get reshuffled when losing internet connection
- Put everyone's discards in front of their hand (suggested by Mom)

## Future rule enforcement
- Winning tile was the last one picked up
