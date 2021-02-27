# Mahjong Wind

Play mahjong with your friends online!

## TODO
- Undo button
- Bug: released tile, still in hand
- Allow exposed -> discards
- Indicate how many tiles remain in deck
- Persist notifications longer. e.g., persist "drew from deck" after remaining exposed tiles come out
- DQ confetti not working on Safari: probably svg/png issue
- Firefox confetti performance: https://github.com/Agezao/confetti-js/issues/23
- Don't close win menu after clicking OK
- Change "You are the dealer 2 times" to "You are the dealer (time #2)" or "You are the dealer 2nd time"
- Click on deckoffer to reveal before dragging?
- CSS: tile turn glowing on Safari 1 pixel too big
- Consider replacing notification system with log system?
- Check if there's needlessly glowing tiles when the player's tiles are already glowing from turn indication
- Add website name to landing page
- CSS: Is it possible to vertically spread the discards if only 1 flexbox row? Make it less obvious that it's a jerry-rigged plain flexbox row.
- Inform the player if their browser window is too small
- Experiment: Put hidden gong next to exposed if not empty, so it doesn't cover seat-3
- Experiment with more CSS animations: exposing a tile, taking from discards, etc.
- Enforce that the winning tile was the last one picked up
- Think of a better domain name

## Long-term TODOs for public release
- Real user accounts instead of just web sessions
- Exclude bots (e.g., PresidentCardGames uses phone numbers)
- Instructions page
- Protect games from being erased during deploys
- Support more Mahjong rule sets (flower tiles, no game wind, etc.)
- Test Internet Explorer
- Mobile support
- Automatically expire games

## Instructions

### Server
- Install dependencies with `mix deps.get`
- Install Node.js dependencies with `npm install` inside the `assets` directory
- Start Phoenix endpoint with `mix phx.server`
- Visit [`localhost:4000`](http://localhost:4000)

### Deploy to Heroku
git push heroku main:main

### Console
`iex -S mix`

### pry server
`iex -S mix phx.server`

### pry tests
`iex -S mix test <file>`

## Misc. development notes

### sortablejs
- https://fullstackphoenix.com/features/sortable-lists-with-sortable-js
- https://www.headway.io/blog/client-side-drag-and-drop-with-phoenix-liveview
- https://github.com/kelseyleftwich/phoenix-liveview-hook-demo
- https://github.com/SortableJS/Sortable

### Tile images
- https://en.wikipedia.org/wiki/Mahjong_tiles

### Tailwind
- https://pragmaticstudio.com/tutorials/adding-tailwind-css-to-phoenix

### PresidentCardGames
- https://twitter.com/toranb/status/1341069221829242881
- https://presidentcardgames.com/
- https://elixirmatch.com/

### Available domains
- mahjonggenius.com
- mahjongmeetup.com
- mahjongnight.com
- mahjongwithfriends.com
- mahjongwithhonor.com
- mjmad.com
- themahjongtable.com
- mahjongauntie.com
- letsallplaymahjong.com
- mjanywhere.com
- mjbuddies.com
- mjfriends.com
- mjfromhome.com
- mjhonor.com
- mjsimulator.com
- mjwithfriends.com
- mahjongwash.com
- ourmahjong.com
- playmah.com
- remotemj.com
- themahjongtable.com
- mahjongjia.com
- mahjongis.fun
- mahjongfriends.party
- mahjongfriends.club
- mahjongfriends.fun
- damahjong.party
- damahjong.club
- damahjong.fun
- mahjong.gold
