# TODO

- CD: https://fly.io/docs/app-guides/continuous-deployment-with-github-actions/
- Put everyone's discards in front of their hand (suggested by Mom)
- Bug: Can't undo to get first discarded tile of the game from bot (human went last, missed a discarded tile, can't go back to beginning of game). If there are no human actions to go back to, Undo should return to beginning of game.
- Bug: Undoing a win after a bot drew a tile hung bot (workaround: paused & unpaused bots)
- Shrink tile sizes on mobile
- Lobby not receiving bot player added
- Refactor: Denormalize seatno as a seat attribute
- Point out game menu on first load
- Make seating less confusing
- Sound
- "Sort" button after deal (disappears if player moves any tile)
- Indicate when deck is running low
- Experiment with more CSS animations: dealing the tiles, etc.
- Real user accounts instead of just web sessions
- Exclude bots (e.g., PresidentCardGames uses phone numbers)
- Support more Mahjong rule sets (flower tiles, no game wind, etc.)
- Instructions
- Protect games from being erased during deploys
- Test Internet Explorer
- Automatically expire games
- Refactor: Extract some common HTML elements (e.g., tile images) to components
- Change "Pause bots" to "Pause" to pause humans too. Allows time to pick tile.
- Only show "hidden gong" if actually possible
- Add titles to tile images ("5 of bamboo"). good for game log where it's small
- Add "Waiting for Mei..." to game log when waiting, then delete when no longer waiting
- Make Pause button easier to click (click on board center?)
- Slider for tile size (so users don't have to increase font size)
- Animated "waiting" dots next to player name when waiting for them
- Allow dragging from decktile to exposed tiles (adding onto a pong)
- 2-click instead of drag & drop. First click will pause other players.
- Display everyone's wind direction instead of staircase
- Animate deal: 4 at a time goes into people's hand
- Sanity check for (possible race condition) bug: rearranging hand leads to duplicate tiles. Last time it happened after peek tile got put into hand, and user drag & dropped that new tile.
- Remember sorted hand so it doesn't get reshuffled when losing internet connection

## Future rule enforcement
- Winning tile was the last one picked up
