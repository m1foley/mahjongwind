# Mahjong Wind

Play mahjong with your friends online!

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

## TODO
- CSS: Is it possible to spread out the discards if only 1 row?
- CSS animation for exposing a tile?
- Automatically expire games
- Figure out production deployments ([Phoenix deployment guides](https://hexdocs.pm/phoenix/deployment.html))
- Enforce that the winning tile was the last one picked up
- Defensive backend code to protect against JS errors/cheats
- Instructions page
- Support more Mahjong rule sets (flower tiles, no game wind, etc.)
- Exclude bots (e.g., PresidentCardGames uses phone numbers)

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
