# Mahjong Wind

Play mahjong with your friends online!

## TODO
- Pause bots button
- Optionally enqueue bot action after undo
- Slam/shake animation when current player discards
- Visually indicate when another player drew from deck. Floating peektile?
- Highlight discarding drop zone on hover
- Change drag cursor on "remaining deck"
- Label "roll" on hand
- Label "discarding..." next to name
- Refactor: Try extracting code and/or assigns from show.ex into components
- Check if there's needlessly glowing tiles when the player's tiles are already glowing from turn indication
- CSS: Is it possible to vertically spread the discards if only 1 flexbox row? Make it less obvious that it's a jerry-rigged plain flexbox row.
- Experiment: Put hidden gong next to exposed if not empty, so it doesn't cover seat-3
- Experiment with more CSS animations: exposing a tile, taking from discards, dealing the tiles, etc.
- Enforce that the winning tile was the last one picked up
- Inform the player if their browser window is too small
- Discards shift when 2nd tile is discarded

## Long-term TODOs for public release
- Real user accounts instead of just web sessions
- Exclude bots (e.g., PresidentCardGames uses phone numbers)
- Support more Mahjong rule sets (flower tiles, no game wind, etc.)
- Instructions
- Protect games from being erased during deploys
- Test Internet Explorer
- Mobile support
- Automatically expire games
- Think of a better domain name?

## Instructions

### Server
- Install dependencies with `mix deps.get`
- Install Node.js dependencies with `npm install` inside the `assets` directory
- Start Phoenix endpoint with `mix phx.server`
- Visit <http://localhost:4000>

### Deploy to Heroku
```sh
heroku login
git push heroku main:main
```

### Console
`iex -S mix`

### pry server
`iex -S mix phx.server`

### pry tests
`iex -S mix test <file>`

## Misc. development notes

### Research/similar sites
- <http://mahjongbuddy.com>
- <https://www.reddit.com/r/Mahjong/comments/jsbsve/i_created_online_hong_kong_mahjong_web_app/>
- <https://www.reddit.com/r/Mahjong/>
- <https://en.wikipedia.org/wiki/Hong_Kong_Mahjong_scoring_rules>
- Deploys: <https://damonvjanis.medium.com/optimizing-for-free-hosting-elixir-deployments-6bfc119a1f44>

### sortablejs
- <https://fullstackphoenix.com/features/sortable-lists-with-sortable-js>
- <https://www.headway.io/blog/client-side-drag-and-drop-with-phoenix-liveview>
- <https://github.com/kelseyleftwich/phoenix-liveview-hook-demo>
- <https://github.com/SortableJS/Sortable>

### Tile images
- <https://en.wikipedia.org/wiki/Mahjong_tiles>

### Tailwind
- <https://pragmaticstudio.com/tutorials/adding-tailwind-css-to-phoenix>

### PresidentCardGames
- <https://twitter.com/toranb/status/1341069221829242881>
- <https://presidentcardgames.com/>
- <https://elixirmatch.com/>

### Available domains
```
mahjonggenius.com
mahjongmeetup.com
mahjongnight.com
mahjongwithfriends.com
mahjongwithhonor.com
mjmad.com
themahjongtable.com
mahjongauntie.com
letsallplaymahjong.com
mjanywhere.com
mjbuddies.com
mjfriends.com
mjfromhome.com
mjhonor.com
mjsimulator.com
mjwithfriends.com
mahjongwash.com
ourmahjong.com
playmah.com
remotemj.com
themahjongtable.com
mahjongjia.com
mahjongis.fun
mahjongfriends.party
mahjongfriends.club
mahjongfriends.fun
damahjong.party
damahjong.club
damahjong.fun
mahjong.gold
```
