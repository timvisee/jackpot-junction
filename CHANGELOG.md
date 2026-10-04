# Changelog

What changed in Jackpot Junction, for people who play it rather than for people
who read the commits. Every change a player would notice gets a line here in the
same commit that makes it, see GAME.md 10.4. The format is
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the versions are
[semantic](https://semver.org/spec/v2.0.0.html).

`tools/changelog` checks this file, cuts a release out of the Unreleased section
below, and hands the notes to the release workflow.

## [Unreleased]

### Fixed

- **No more spaces in a server address on a phone.** Address boxes use the phone's keyboard for
  addresses, which stopped adding a space after each dot, and port boxes the number keyboard.
- **No freeze making a profile in a game.** Profiles are only listed in the settings inside a game;
  make, edit, switch and delete them from the title screen.
- **Gold tracks you can see.** The trail of a kart one cash-out from winning is bright and wide
  now; it was too faint to notice, above all on the driving school's floor.
- **The touch menu button works with no kart to drive.** Watching an online game, or waiting for a
  seat, a tap on it did nothing.
- **A second gamepad no longer takes the first player's kart away.** The first player keeps the pad
  they came in on when someone else sits down, rather than being handed the keyboard.

## [0.13.0] - 2026-10-03

Everyone at a machine gets a profile of their own, with lifetime statistics, and can bring it to a
seat at a shared screen; Play Online keeps your own list of servers. It doesn't play with 0.12.x.

### Added

- **Your own server list.** Play Online keeps the dedicated servers you add, a press each to
  connect to, with Direct connect for one you don't keep.
- **Play as your own profile at a shared screen.** A second, third or fourth player can pick Link
  profile in the pause menu to bring their own name, kart and plate, and their games count toward
  their own statistics.
- **Lifetime statistics.** Every map you play to the end adds to your profile's numbers, from maps
  and Grand Prix won to kilometers driven, on a new Statistics page in the settings.
- **Profiles.** Each person at a machine has a profile of their own, with their names, karts,
  license and servers; make, switch and delete them on the settings' new Profiles page.
- **See what you type on a phone.** A text box the keyboard covers is shown on a bar just above the
  keyboard while you type into it.
- **The Android back button.** It closes dialogs and backs out of screens like B on a pad, opens
  the menu in a match, and no longer quits the game.
- **Ricochet kills show it.** A kill by a bullet that bounced off a wall has a bounce mark in the
  kill feed, with ×2 and up for more walls.
- **Decoys in the kill feed.** A kill your decoy makes reads "Ann's decoy shot Bo", and a decoy
  destroyed has a line of its own.
- **Short tire marks, or only yours.** The Video page's Tire marks is Full, Short, Mine or Off:
  Short fades in seconds and Mine lays only your own kart's, short too. Phones start on Short.

### Changed

- **One way in to playing online.** The title has Play and Play Online; games on your network are
  under Play Online's LAN games, with Host a game and Direct connect.
- **Lists in a box of their own.** Servers and games are listed in a sunken box, a link under them
  to add or host one; addresses and connecting are dialogs, and icons remove and watch.
- **Seats on the Players page.** Its rows are Seat 1 to Seat 4, under a line saying what the page
  is for.
- **The License page during the driving test.** Opened from the test, it says the license is in
  progress rather than offering to send you back to the school.
- **The settings in a new order.** License, Players, Controls, Audio, Video, Accessibility,
  Statistics, Profiles, About.
- **The game's words stand out in the driving test.** Chips, mult, pot, bank, nitro and lives are in
  their HUD colors, and the Jackpot, the Junction and the Royal Flush in a color of their own.
- **Chips, everywhere.** What you collect is called chips in every lesson, card, award and item; the
  Coin Magnet is now the Chip Magnet.
- **A smaller license in the settings.** The License page shows the card smaller; click or tap it to
  see it full size.
- **Type your license plate on the plate.** The plate itself is the text box, with a line beside it
  saying how to edit it.
- **More room by the lobby's stalls.** The stack of wheels in the lobby stands a step further from
  the back wall.
- **Untouchable karts stop bullets.** A kart just back or just hit no longer lets shots through:
  they stop on it harmlessly, with a small flash.
- **An emote wheel you can read on a pad.** The right stick's wheel stays up while you hold the
  stick; push to the edge and let go to send, or let go sooner to send nothing.
- **A Skip button on the joker pick everywhere.** On a keyboard or a pad it shows the key that skips
  inside it, rather than leaving skipping to the small print.
- **A steering wheel on the touch screen.** Driving with wheel and pedals, the stick under your
  left thumb is drawn as a wheel that turns as you steer.
- **The mult die is a real die.** It has black pips on every side, one to six.
- **Pictures on the dressing pads.** The paint, hat, flag and trail pads in the lobby and the
  Garage show a picture of what they change rather than its name.
- **Plates in Manage players.** The host's list of players shows each one's license plate, or the
  learner's L, beside the name.
- **Inspectors at the driving test.** Four people in hi-vis vests with clipboards watch your kart
  from the wall tops, and now and then write something down.
- **A finger for a tap.** On a phone, the theory book and the license stamp show a finger tapping
  rather than a "Tap" button, and the license on the title and in the settings shows one too.
- **The theory book warns you.** "Read carefully. There will be questions." stands beside the shut
  book until you open it.

### Fixed

- **Bots no longer stay stuck.** A bot that has gone nowhere for ten seconds gives up and drives
  somewhere else, and if that fails too, it is put back on a spawn point, keeping its pot.
- **Spaces in a license plate.** A space typed at the end of the plate no longer vanishes before
  the next letter.
- **A smooth guide arrow in the driving test.** The blue arrow on the floor follows the kart as it
  is drawn, rather than shaking against it on a phone.
- **A joker's word leans with its card.** GUARDED, LOST and the rest tilt as the card does in the
  fan, rather than sitting level over it.
- **No gray flash on quitting.** The window stays the menus' dark while the game closes and
  between screens.
## [0.12.0] - 2026-10-02

A driving school teaches the game and ends with a license whose plate your kart wears, and jokers
now show in your hand when they go off. It doesn't play with 0.11.x.

### Added

- **A tutorial, as a driving school.** Enroll, sit through a Highway Code that reads itself, pass a
  quiz nobody fails, then the driving test: eleven lessons in a row of rooms, from driving to a
  final exam against three bots, and a driver license to stamp at the end. The title offers it the
  first time you press Play, and has a button for it.
- **License plates.** Your kart wears the plate you chose with your license, up to eight
  characters, online too; until you pass it wears a learner's L, as the easiest bots do.
- **A learner hat.** The driving school's L block, to wear on your helmet.
- **Run with another settings file.** `--settings=<path>` after `--` starts the game with a fresh
  or a particular settings file, leaving your own alone.
- **Jokers show when they go off.** Guardian Angel, Insurance Policy, Tight Grip, Pickpocket, Toll
  Booth, Road Rage and Carbon Copy pull out of your hand and glow with a word when they act; a
  joker your death drops or takes, such as Spare Tire, burns out of it in red, saying LOST.

### Changed

- **The shader warm-up asks for patience.** The title's strip reads "Compiling shaders, please
  wait..." while it runs.
## [0.11.0] - 2026-09-30

Most jokers now stack, four new ones join them, and the bots emote back. Dedicated servers kick
changed clients and come as a Docker image and for ARM Linux too; it doesn't play with 0.10.x.

### Added

- **Hold Alt for a joker's details.** Or click the right stick: the card adds how far it stacks,
  and one copy's number beside each gold one. The card itself no longer says how far it stacks.
- **Most jokers with a number stack.** Take one again for more of it, up to three copies (two for
  Wild Card, Spare Tire and Scar Tissue); the card says the stack's total, in gold.
- **Aim the Swivel Cannon by touch.** On a phone or tablet, touch the arena to point it there;
  the fire button fires.
- **Bots emote now and then.** Pleased at a double kill or a kart shoved down a hole, cross at being
  shot at over and over or killed as they come back, and a gg for a win, now and then for a loss
  too; never every time.
- **Emotes while you wait to come back.** A dead player's emote floats up from the bottom of the
  screen in their color, the way a watcher's does.
- **Carbon Copy.** A joker your death drops goes on the floor as a copy, and you keep your own.
- **Guardian Angel.** A joker that spends the Shield or Bullet Wipe you hold on a hit about to cost
  you a life, the moment it lands.
- **Two jokers with a life in them.** Spare Tire is one more life, lost with the kart; Scar Tissue
  is one more that nothing heals but coming back.
- **Three more awards.** Knocking on the Door for match points, Piggy Bank for coins dropped on the
  floor and Battering Ram for players rammed.
- **A server says where it listens.** As it starts, a dedicated server logs the addresses of its
  machine that players can reach it on.
- **Garbage is dropped at the door.** A server drops a connection that says anything but the game's
  own hello, which now names the game, or opens too many at once, on the spot and logs where it
  came from; a player flooding it is kicked.
- **A changed client is shown out.** One that sends what no copy of the game sends is kicked after
  three, told "Kicked: abnormal behavior detected", and the others see it in the kill feed; a bad
  connection never counts.
- **The server as a Docker image.** Every release publishes `timvisee/jackpot-junction-server`
  for x86_64 and ARM, with a Compose example in `docker/compose.yaml`.
- **Linux on ARM.** Every release has the game and the dedicated server for 64-bit ARM Linux too.
- **Server settings from the environment and a range of game ports.** A dedicated server takes
  `JJ_PORT`, `JJ_GAMES` and `JJ_GAME_PORTS` as well as its arguments, and `--game-ports=9000-9015`
  puts its games on ports of their own.
- **Everybody is told when a cash-out would win.** The moment a player's next cash-out would win
  the match, every screen calls MATCH POINT after their name in their color, and the music climbs
  to the top the way it does for Last Call.
- **A bar while a server makes a game.** Make a game in Play Online shows how far along the new game
  is, from the server starting it to its lobby being built.

### Changed

- **The game as a server loads no sound.** Run with `--server`, or with `make server` from a
  checkout, it plays the same game the server build does, which carries none.
- **Plainer release zips.** Each zip holds the game at its top: `jackpot-junction` for Linux,
  `jackpot-junction.exe` for Windows and `jackpot-junction-server` for the server.
- **Full screen from the start on a desktop.** A released game starts full screen on Linux,
  Windows and macOS until the Video page says otherwise; a window mode already saved is kept.
- **The lobby's football answers at once online.** A client's kart kicks it the moment the two
  meet, rather than driving into a ball that shoots off a round trip later.
- **Pickups and pads are instant online.** A client's kart takes a chip, die, box or card, or a
  Royal Flush pad, the moment it gets there, with the flight and the sound; the host still decides
  what it was worth.
- **The crowd can be turned off for speed too.** The crowd setting is Full, Half or Off, one
  setting shown on the Video page and in Accessibility alike; a crowd switched off before stays
  off.

### Fixed

- **No second copy of a joker off the floor.** A kart already holding a joker leaves it lying,
  unless it stacks and the stack has room.
- **A bot's Swivel Cannon is its own.** It no longer aims wherever the host's mouse is pointing.
- **The joker you chose online is the joker you get.** A client names the card it picks, keeps,
  drops or destroys, and the host checks it had that card; the host could take a neighbor.
- **No cheating through a changed client.** A host, a dedicated server most of all, no longer
  takes a client's word for its nitro, boosts, power-ups or speed, nor for driving further than the
  kart can, and drops controls that are not controls.
- **A clean exit.** Quitting while music or a sound was playing, or after keeping a joker in a
  Grand Prix, no longer ends with warnings of leaked instances and resources still in use.
- **Pause game stays on the host's menu.** It stays up while the room is paused, with a tick in it
  while it is the host's own pause, and pressing it again lets go; a pause goes with the host's say
  when that is handed on.
- **Leaving a server game alone says so.** The player with the host's say who leaves with nobody
  else playing is told the game ends, not that the say passes on to nobody.
- **No errors when a dedicated server's game ends.** The server no longer logs three "Attempt to
  disconnect a nonexistent connection" errors as the last player leaves a game.
- **A steady aim guide.** The dots ahead of the cannon, and the arrow of a freely aimed one, follow
  the kart as it is drawn: on a phone they jittered against it every frame.
- **No "Its address" in the server box.** Play Online's server field is empty until something is
  typed in it.
- **No key named over the kart on a touch screen.** The picture of a new item still comes up beside
  the kart; the button that uses it is the touch button with the item on it.
- **A smooth joker pick online.** Taking a card no longer makes the pick blink back up and the
  hand redeal while the host catches up, and the card is heard once.
- **Watchers see the Royal Flush tally.** A watcher's screen shows who holds which pads whenever
  anybody holds one, where it only ever showed the one-pad-off warning.
## [0.10.1] - 2026-09-30

Faster everywhere and much faster on phones: a match on a Pixel 7 runs at around fifty frames a
second where it ran in the mid-thirties, and shaders compile behind the title rather than
mid-race. It plays with 0.10.0.

### Added

- **Shaders compile behind the title.** The first time a version of the game runs on a machine, a
  bar above the credits says "Compiling shaders" while the menu keeps working, so the first bomb,
  nitro or firework of a match no longer stutters.
- **Crowd size.** A Video setting for how full the house is, Full or Half; a phone starts with
  half a house, since the crowd is the most triangles on the screen and none of them are the
  match.

### Changed

- **Particles for a fiftieth of the triangles.** Smoke, sparks and flames cast no shadows and are
  drawn as small balls: the particles behind four karts were six of every seven triangles in a
  frame.
- **Fewer draw calls.** Chips, item boxes, the clock board, the pads, the stands and the tanks
  each draw as one thing rather than a mesh a piece, so a frame of Lucky Crossing is 344 draw
  calls where it was 713.
- **Fewer triangles in the small things.** Bullets, aim dots, markers, bombs, turrets, rings and
  every onlooker in the crowd are cut to the detail their size shows, and share their meshes and
  materials rather than building their own.
- **Cheaper shadows, sharper up close.** The sun's shadow map has two splits rather than four and
  reaches only as far as the camera can see, and the pads and plates set into the felt no longer
  cast shadows nobody saw.
- **Fewer lights.** The fill light is folded into the ambient light, and a faded drift glow, a
  spent firework or a dark disco head is put out rather than left shining at nothing.
- **Disco lights: Full, Few or Off.** The setting has a middle, three heads at most, which is
  where a phone starts, and the beams are scaled to their throw rather than rebuilt every frame.
- **The felt and the table lit in tiles on a phone.** A phone's renderer pays for every light
  that reaches a mesh on every pixel of it, so there the two big surfaces are cut three by three.
- **A lighter crowd.** It is lit without the shadow map or a highlight, and a side of it the
  camera cannot see is not drawn at all.
- **A lighter HUD.** The scoreboard, the corner blocks, the hearts and the clock restyle
  themselves only when something changed, where they did every row every frame.
- **Textures with mipmaps, compressed for the card.** The felt, wood, paint, stone and card
  textures take a quarter of the bandwidth they did.
- **Cheaper bullets.** Two shots are only measured against each other once they are near enough
  to have met, and every bullet shares one look-up of the karts and targets a frame.
## [0.10.0] - 2026-09-29

Play Online, on a dedicated server you can run yourself from the new headless Linux build. It
doesn't play with 0.9.x.

### Added

- **Play Online, on a dedicated server.** A new title entry connects to a server, then lists its
  games: make one and host it from your machine, or join or watch one; it won't play with 0.9.x.
- **Dedicated servers.** `--server` runs the game headless as a server of several games at once on
  7777, logging who comes and goes; idle it takes about 90 MB, starting a game only when one is made.
- **A server build for Linux.** Releases carry `jackpot-junction-server`, the game as a headless
  server with no sound or pictures in it, 75 MB; it needs no flags to start.
- **The host's say passes on.** On a dedicated server, whoever made a game hosts it from their own
  machine and can hand that on with Make host in Manage players; if they leave, the longest in does.
## [0.9.0] - 2026-09-29

XL versions of every map, several players at one LAN client, and a pot about to win now burns in
your corner and lays gold tracks behind your kart. It changes the LAN protocol, so it doesn't play
with 0.8.x.

### Added

- **A stacked joker shows how many you hold.** A joker such as Rubber Bumpers held more than once
  says ×2 or ×3 beside its name, and "makes ×2" when offered again.
- **A slow connection is warned of.** Online, past 100 ms there and back, a warning and the time
  show in the player's corner, and a warning beside their name in the standings on every screen.
- **A pot that would win catches fire.** Your pot's numbers burn in your corner, and your kart
  lays gold tracks every player can see.
- **The item you pick up shows by your kart.** Off its top right, it spins like the roulette,
  settles with its button and fades, but stays up near a box you can't take while holding it.
- **Back to lobby after a quick match.** The podium offers it beside Rematch and Back to title,
  on one machine as well as for a LAN host.
- **Joker slots in the match settings.** Choose how many jokers a hand holds, 3 to 8, under
  Items; Deep Pockets still adds two to it.
- **Tight Grip joker.** Your pot never spills: a death drops no coins, a killer takes none,
  and a ram knocks none out.
- **The Royal Flush pads you hold show under the clock.** Each pad's suit in its holder's color,
  yours first and the free ones faint, while you hold one, your flush pays, or a rival is one off.
- **XL maps.** Lucky Crossing XL, The Vault XL and Crossfire XL are roomier versions with space
  around the pits and turbos that never aim into a wall; a Grand Prix can deal normal, XL or both.
- **A death shows where its pot went.** The banked share flies into the score as gold coins,
  and for your own players the lost share goes gray into a trash can; the whistle too.
- **Page between a map's podium and the standings.** In a Grand Prix, arrows on the left turn
  between the two, with a dot marking the page, and Next map on the right is on both.
- **Several players at a LAN client.** A client takes another player with J or Start, the
  way the host does, up to the lobby's limit; it won't play with 0.8.x.

### Fixed

- **A pot that would win counts what the cash-out pays.** Glass Jackpot and Last Call now count,
  so a 2000 pot with Glass Jackpot shows as winning against a 3000 target.
- **A late snapshot is never shown over a newer one.** A small one arriving out of order could
  run a client's clock and karts back for a moment; now it is dropped, as big ones already were.
- **A watcher can be shown out as soon as they arrive.** Kicked in the moment before their
  connection was complete, they stayed; they are now only listed once they are all the way in.
- **The Vault's pits can be seen.** They are edged in a faint red neon, and the lamp over an
  XL map lights its far corners as well as the usual map's.
- **A second player at a LAN client leaves nothing behind.** Shown out quickly, or asked for twice,
  they could leave a stray corner or a kart nobody drove.
- **Two turbo pads side by side always launch.** Driving down the line between them went
  through without a turbo; they now work as one pad.
- **A death after the whistle no longer changes the result.** A late bomb or fall banked half a
  pot after the Grand Prix points and the winner were already decided.
- **Mouse buttons can be bound in Controls.** A click to bind went to the settings screen's
  own buttons instead, so fire on the left mouse button could never be set.
- **A player taking over a bot's kart wears their own dress.** They were left in the bot's
  plain kart, and a LAN player no longer borrows the host's own seats' names and dress.
- **Nitro comes back quickly in a LAN lobby on a client too.** A client refilled at a match's
  pace there, and never felt a hot room's quicker nitro on a map either.
- **Item boxes no longer throw an error when taken.** They also shrink down a hole and grow
  in when thrown from a wreck, as other pickups do.
- **A full LAN lobby turns away another seat.** Pressing J at the host past the lobby's
  player limit says the game is full rather than adding a player.

### Changed

- **The bullet limit never refuses a shot.** Firing with three bullets already in the air takes
  your oldest one out instead of doing nothing.
- **The cash-out that wins runs to its last coin.** Reaching the target mid-cash-out no longer
  ends the match there; it ends once the whole pot is in, or the cash-out stops.
- **Bots go after a player about to win.** By their trait's chance, bots hunt, ram and shoot
  whoever is one cash-out from winning, and a bot that could win itself goes to cash out.
- **Rams knock coins out of untouchable karts.** A kart blinking after a hit or a respawn loses
  coins to a ram but no life, and a kart can be rammed at most once every 0.2 s.
- **Escape closes a joker card you clicked open.** It puts the card away first, and pauses the
  match only once no card is open.
- **Royal Flush pads wear the four card suits.** A spade, heart, diamond and club, one per pad
  in the holder's color, replace the A, K, Q and J letters.
- **Jokers on the floor show their picture.** The card is printed on both sides like a card in
  your hand, and leans back so it can be seen, instead of two letters over it.
- **Item boxes are branded with what they hold.** A dropped box wears its item's picture on its
  top and sides instead of a letter over it, and a box from a pad wears a question mark.
- **Chips go into the Junction the whole time you bank.** They used to fly only once the
  cash-out was done.
- **A death banks a share of what is left of the pot.** The coins it drops leave the pot first;
  Insurance Policy banks all that is left, and Tight Grip keeps them all to bank.
- **The shoulder buttons turn a Grand Prix's podium pages.** On a pad, left goes back and right
  goes on, and the buttons are drawn beside the arrows.
- **After a Grand Prix's last map, Continue goes on.** Its podium and the final standings are a
  page each, so they show no page arrows.
- **Lucky Crossing's pits sit a cell clear of the Junction.** A kart pushed off the pad's edge
  no longer drops straight into one.
- **The game starts at half volume.** A fresh install's master volume is 50% rather than 100%;
  one already set keeps its level.
- **Pots bank at the whistle when time runs out.** With Match ends, every pot still carried
  banks what a death would, and a field of one at the clock takes all of its own.
- **Mouse buttons are drawn as a mouse.** A binding on the left, right or middle button shows
  a mouse with that button lit, and a double click adds ×2.
- **Bots dress their karts.** Each bot drives with its own paint, hat, flag and trail, and
  keeps them through a Grand Prix.
- **Manage players sits under Lobby settings.** On the host's pause menu the two are now the
  other way round.
- **A spectator's countdown to the standings is a small ring.** It sits beside the line saying
  the host starts the next map, in place of the bar across the pane.
- **Back in a LAN lobby, only the match settings come up.** The lobby settings were set when
  the game was hosted, and are still on the pause menu.
- **A host nobody has joined leaves without being asked.** Back to title only warns about
  disconnecting everybody when somebody is connected, to play or to watch.
- **The lobby says how many bots are coming.** "1 / 2 PLAYERS READY + 2 BOTS", at the top
  of the screen and on the board, in place of the number on the green plan line.
- **The kill feed says when a turret made the kill.** "P1's turret shot P2" rather than
  "P1 shot P2".
## [0.8.2] - 2026-09-25

Matches run much faster the longer they go, and the Video settings gain MSAA, shadows, an
upscaler, a frame rate limit and more. With three or four players each hand of jokers sits by
its owner's corner, and it still plays over LAN with 0.8.0 and 0.8.1.

### Added

- **A Show FPS setting.** The frame rate in the top left corner of every screen.
- **A Frame rate limit setting.** Unlimited, or 30 to 144 frames a second; 30 saves a
  phone's battery.
- **A Shadows setting.** Off, Low or High; a phone starts on Low, as it always drew them.
- **An Upscaler setting.** FSR 1 or FSR 2 in place of the plain stretch, for a render
  scale below 100%.
- **MSAA and Screen smoothing settings.** MSAA from Off to 8x, and FXAA or SMAA over the
  picture, in place of Edge smoothing; yours carries over.
- **A Tire marks setting.** Under Video; off, karts leave no marks on the floor.
- **An Intense music setting.** How much louder the music gets as a match heats up,
  from Off to Strong; it starts where the music always was.
- **Jokers by mouse.** Hover a card to read it; click a pick card to take it, or a hand
  card to keep it open with Drop and Destroy on its pane.

### Changed

- **Bigger option boxes, lists and tabs.** Every box you pick from is button-sized, and
  the list it opens has big entries, spaced further apart on a touch screen.
- **Phones no longer show Fullscreen or V-sync.** A phone decides both itself; the Video
  page offers only what it can change.
- **Matches run faster, most of all on phones.** The tire marks were built again whole
  every frame; now only the newest stretch of them is.
- **With three or four players, each hand of jokers sits by its owner's corner.** The top
  two hang from the top edge, and a respawn pick comes up in its owner's corner too.
- **With three or four players, the hands tuck half off the screen.** As on a phone, a
  hand comes out to full size while you read it.
- **On a touch screen the fire button shows what a stall changes.** A roller, a hat, a
  flag or a trail in place of FIRE while you stand on one, and the hint shows it too.

### Fixed

- **Hints over a kart are all one size.** The drive and fire hint and a stall's hint
  look the same size on screen, whatever the map and however far off the camera is.
## [0.8.1] - 2026-09-25

Fixes for LAN play: joining with a password works, names stay put, and a client no longer
loses the game for seconds at a time. Every release now comes with a signed Android APK.

### Added

- **An Android APK with every release.** Built and signed by the release itself, so
  each one installs over the last; uninstall the 0.8.0 APK once first.

### Fixed

- **A LAN client no longer loses the game for seconds at a time.** ENet dropped whole
  snapshots whenever the connection wobbled, so a kart could fall through the floor.
- **Joining a LAN game with a password works.** After typing it you were left in an
  empty lobby, never connected to the host.
- **LAN players keep their funny names.** A client that set no name lost the one it
  was handed in the lobby as the match started.
- **A wrong password goes back to Play LAN.** It says so there, and Back on the
  password prompt goes there too rather than to the title.

### Changed

- **Every watcher has a name of their own.** One who gives none, or one somebody else
  has, is handed a watcher's name nobody has, like Couch Potato or Stool Pigeon.
- **Manage players shows the host too.** Marked Me, at the top, with no Kick.
- **Most players is now Player limit.** The same setting in Lobby settings, named
  more plainly.
## [0.8.0] - 2026-09-25

LAN games find each other now, and the host decides who comes in: a password, a player
limit, watchers or not, and a kick. Everybody in an online game needs 0.8.

### Added

- **The LAN screen finds games on your network.** Each one found says whose it is,
  how many play and whether it wants a password, with Join and Watch.
- **Lobby settings for the host.** The most players the game takes, a password for
  joining, and whether anybody may watch; hosting shows them first, then the match.
- **The host can kick players.** Manage players, in the host's pause menu, lists
  everybody else in the game with Kick beside each; they can join again.
- **One of several players at a screen can leave.** Their pane in the pause menu has
  Leave; on a map a bot takes their kart on.
- **The pause menu says what each player is playing on.** Beside their pane: keyboard,
  gamepad or touch screen, and what they throttle and steer with.
- **Aim assist finds the lobby's football.** A shot at it leans onto it the way one
  at a kart does.
## [0.7.0] - 2026-09-24

Dress your kart at the stalls, change your name and color, and emote at each other in
the lobby, and watch a LAN game from the side. Everybody in an online game needs 0.7.

### Added

- **An About page in Settings.** It says the game was made by AI as an experiment,
  by which models, credits everybody else whose work is in it and links to GitHub.
- **A Marksman award for accuracy.** How many of a player's shots landed on another
  kart is counted now, once they have fired ten.
- **The host can pause everybody at once.** Online the room still waits for everybody
  to pause, unless the host presses Pause game.
- **Kart colors for color blindness.** Accessibility has a palette each for
  protanopia, deuteranopia and tritanopia, chosen to keep all eight players apart.
- **Dress your kart at the stalls.** The lobby and the Garage have a pad each for
  paint, hat, flag and trail; drive onto one and press fire to put the next one on.
- **Emotes.** Flick the right stick, press 7 to 0, or V and a direction, to put GG,
  a smile, a scowl or a heart over your kart, online too; a wheel shows the four.
- **An emote button on touch screens.** It sits beside the menu button and opens a
  row of the four.
- **Change your name and color in the lobby.** Your pane in the pause menu has a
  name box and a button for your color in the lobby and the Garage, online too.
- **Watch a LAN game.** Watch, beside Join, lets somebody in with no kart, even when
  every seat is taken, and the podiums go on by themselves.
- **Watchers can emote.** Theirs float up from the bottom of every screen in gray,
  with their name under them.

### Changed

- **Play goes straight into the lobby.** The match settings come up over it the way
  they do for a LAN host, and anybody else joins in the room with J or Start.
- **Names are in Settings.** A Players tab has a box for each seat.
- **Every seat's driving is on the Players tab.** A small button after each name
  switches that seat between simple and advanced.
- **Grand Prix or Quick match is two big buttons.** They sit at the top of the match
  settings, with a trophy and a stopwatch on them.
- **Karts are dressed at the stalls rather than on a menu.** Online a client's kart
  now looks the way its player dressed it on every screen.

### Fixed

- **Leaving the LAN lobby takes the kart out.** A bot took it over and drove round
  the room; bots only join when the match starts.
- **The match settings scroll on a small phone.** On a short screen they ran off the
  top and the bottom, with Done out of reach.
- **Every player at one screen hears their own kart.** With two or more, each kart
  was heard from halfway between them, so a player far from the others barely heard
  their own.
- **Going to the next map online is one dark screen.** Starting the match was said on
  the menus' gray and then the loading screen cut in on black.
- **The start lamps always go after the countdown.** A match that went straight into
  anything but ordinary play kept them up.
- **Joining an address nobody is at says so.** It said it was waiting for the host
  for half a minute; it says it is connecting, and gives up after a few seconds.
## [0.6.2] - 2026-09-24

A simple way to drive: push the way on the screen you want to go and the kart takes
itself there. The pause menu gains a way back to the lobby, and asks before anybody
leaves an online game.

### Added

- **Simple driving.** Push the way on the screen you want to go and the kart turns
  and drives there, and brakes when you let go; pick it under Settings, Controls.
- **Simple driving on a touch screen.** The stick points the way, and the slider or
  the buttons keep only nitro and drift.
- **The first Play asks how you want to drive.** Simple or advanced, each with its
  picture; Settings can change it later or ask again.
- **Switch how you drive from the pause menu.** Each player has a switch over their
  own corner, and on a touch screen one for the slider or the buttons too.
- **Every player picks how they drive on the Play screen.** It sits under their name
  and kart.
- **Hints for simple driving.** The hint over the kart and the test track's first
  signs name the way to go: WASD, or the stick with an arrow each way.
- **Leaving an online game asks first.** The host is told that everybody who
  joined will be disconnected.
- **Back to lobby from the pause menu.** It ends the map and the Grand Prix, and
  online the host takes everybody back with them, still connected.

### Changed

- **Touch driving shows its two layouts as pictures.** Slider and Buttons are picked
  in Settings the way the driving is.

### Fixed

- **The pause menu darkens the room behind it.** So does the host's Match settings
  pane; both meant to, and neither did.

## [0.6.1] - 2026-09-24

A Grand Prix asks everybody which joker to keep between maps, to start with, and
phones start on a lighter picture.

### Changed

- **A Grand Prix asks which joker to keep, to start with.** Jokers between maps
  starts on Pick one to keep rather than Keep one at random.
- **Phones start on a lighter picture.** Bloom and edge smoothing are off and the
  render scale is 80% to begin with, which the settings can change.

## [0.6.0] - 2026-09-24

Jackpot Junction plays on a touch screen: a stick, a slider for the pedals and a
UI scale to make it all big enough to press. The rooms between the maps load
like maps.

### Added

- **Touch controls.** On a phone or a tablet a stick steers and one slider runs
  nitro, gas, brake and drift, or a button each if you prefer, beside fire and your
  item. Hold a joker to read it, tap it to drop or destroy it, and tap one in the
  respawn pick to take it.
- **A UI scale setting.** The menus and the HUD can be drawn from 75% to 200% of
  their size, and a phone or a tablet starts at 150%.

### Changed

- **The Garage, the test track and the lobby load like a map.** They go up behind
  the same screen with its progress bar rather than freezing the last one.
- **The waiting room is called the Lobby.**
- **The driving hint over your kart grows with the UI scale.**
- **Menu buttons are much quieter.** The tick of the cursor landing on a button and
  the click of pressing it, both on every tap on a touch screen, are well down.

### Fixed

- **Jokers sit where they should with three or four players on one screen.** Each
  hand of cards stood a little below its place and off to the right of it.

## [0.5.2] - 2026-09-24

A Grand Prix now ends in a party on a podium, hushed until the music drops into
fireworks. The standings between maps fit their pane again.

### Added

- **A party at the end of a Grand Prix.** The top three float over a podium on a
  hushed, smoky dance floor until the muffled music drops, the crowd dances and
  the fireworks go up, before the final standings come up.

### Fixed

- **The Grand Prix standings between maps fit their pane again.** The pane no longer
  comes up too small with the players' rows spilling out of the bottom of it.

## [0.5.1] - 2026-09-24

Online play holds together: you can join a match already under way, every map waits
for everybody to load, and games check each other's version. A Grand Prix shows its
standings after every map and lets you pick which joker to keep as the next starts.

### Added

- **The music goes under when you die.** It drops to a muffled rumble for a moment
  and slowly comes back; a switch in the audio settings turns it off.

- **The football can be heard.** A soft thump when a kart kicks it and a knock off
  walls and shots, louder the harder it is hit.

- **Shoot the football.** A bullet that hits the ball in the waiting room kicks it
  the way the shot was going.

- **Everybody ready has a sound.** When the ring turns green, the ready chime runs up
  to its octave.

- **Shoulder buttons switch settings tabs.** On a gamepad, LB and RB step through
  Controls, Audio, Video and Accessibility.

- **Join a match already under way.** Connecting to a host mid-match takes you
  into the map being played, or its podium, in a free seat; a full match says so.

- **A version check when joining online.** Games with a different major or minor
  version are told which version the host has and sent back; patch releases from
  0.5.1 on still play together.

- **Arrows on the Grand Prix podium.** Green for anybody who climbed the standings
  on the last map, red for anybody who fell.

- **Nitro kicks the football twice as hard.** Hit the ball in the waiting room with
  nitro on and it flies.

- **The ready pad can be heard.** A soft tick climbs as you charge it, and a chime
  plays when somebody is ready.

- **A lighter HUD in the waiting room.** Your corner shows your name, lives and
  nitro, without banked chips, pot, mult, kills or deaths.

- **Who is in the waiting room, down the side.** A list of everybody there, where a
  match keeps its running order, without places or scores.

### Fixed

- **Joining shows the menu background while it waits.** "Connecting..." and "Starting
  the match..." no longer sit over an empty world.

- **The ready chime plays on your own machine.** Playing alone or hosting, readying
  up on the pad was silent; only players who joined a host heard it.

- **Settings no longer restart the match.** Opening them from the pause menu lays
  them over the game, and Back takes you back to the menu with the match as it was.

- **Joining a host that isn't there says so.** The waiting room used to sit empty
  when the connection failed; now it tells you and goes back to the menu.

- **The respawn countdown shows.** Your corner says how long until you are back on
  the floor; the line was there all along but had no room to be drawn in.

- **Respawns flare where the kart comes back online.** Joining somebody else's game,
  the ring opened over the spot a kart had died on instead of where it reappeared.

- **The crowd dances online.** Joining somebody else's game, the crowd stood still
  however loud the room got; it gets up with the music now, and the camera thumps
  on the beat at the top level too.

- **Your own kart is heard online.** Joining somebody else's game, your engine and
  tires sounded as far off as everybody else's and the camera did not look ahead of
  you; both work as they do for the host now.

- **No stray gap before the buttons in a hint.** A line like "Press J or Menu on
  another device to join" had a wide space in front of each button; it reads as a
  sentence now.

### Changed

- **Play online is now Play LAN.** The title button and its screen say what it is:
  play with friends on the same network.

- **Grand Prix standings after every map.** Each map's podium leads to how the run
  stands, and Next map is started from there.

- **Bots finish the Jackpot.** A bot collecting it stays until the pile is empty,
  and leaves early only when it is in danger.

- **Pick which joker to keep as the next map starts.** Under "Pick one to keep" the
  joker pick opens on the grid with the jokers you held, and the lamps wait for it.

- **Out in Sudden Death, your corner says so.** It reads "waiting on players"
  instead of a respawn countdown that was never going to finish.

- **Online maps start together.** The countdown waits until everybody has the map
  loaded, showing how many players it is waiting on, for 15 seconds at most.

- **One Play button.** The lobby's first row picks a Grand Prix or a quick match,
  instead of the title screen asking with two buttons.

- **American English throughout.** Color, center, gray, tires and a checkered flag,
  on every screen.

- **One-minute maps in every build.** A short map is on offer outside debug builds
  too, handy for a quick Grand Prix.

- **Clearer names in the match settings.** Basic items, Harmless and Deadly own
  bullets, and Discard all or Pick one to keep for jokers between maps.
## [0.5.0] - 2026-09-23

### Added

- **Online matches start in a waiting room.** Hosting or joining now opens a small
  garage bay where everybody drives around while the rest arrive, and the match
  begins when all of you have parked on the pad in the middle.

- **A football in the waiting room.** Drive into it to kick it about while everybody
  gets ready; it stays on the floor and inside the walls.

- **The host chooses the online match in the waiting room.** Arena, length, target
  score, bots and the rest come up when you open the room and again from the pause
  menu, and everybody waiting is told what is coming next.

- **Play is a match of several maps.** Choose how many, drive into the waiting room,
  and once everybody is ready the maps are dealt at random and played one after
  another with Next map on each podium, the same bots on every one of them. Works on
  one screen and online.

- **A match is won on points.** Each map pays points by place, and after the last
  map's own podium a Grand Prix podium ranks everybody on points over the whole match.

- **Jokers can carry over between the maps of a match.** Keep none, choose one on
  the podium, keep one at random (the default), or keep all.

- **Quick play on the title screen.** Setting up and playing a single map moves to
  its own button, next to Play.

- **Back to lobby after an online match.** The host's podium has a button that
  takes everybody back to the waiting room together, where the match settings come
  up again for the next one.

### Changed

- **Driving off the ready pad unreadies you.** Ready used to stick once the pad had
  charged, so a room could start without somebody who had wandered off; it now
  lasts exactly as long as you stay parked.

- **The ready pad's ring is split between the players in the room.** Each of you
  charges your own arc of it in your own kart colour, so it is clear who the pad
  has taken and who it is still waiting on.

- **A box to weave round in the waiting room.** A destructible crate now stands
  opposite the drum down one side of the room, close enough to run a figure of
  eight between the two, and it comes back a few seconds after you break it.

- **The waiting room's ready count is on a sign you can read.** It was on a
  hoarding set back behind the room, above the shot and too far off; it is a small
  board on top of the back wall now, with the count on a line of its own.

- **The waiting room turns green before it goes.** Once everybody is ready the
  ring round the pad goes green and the match starts a second later, instead of
  cutting away the instant the last player readies.

- **The waiting room shows the pad's join button too.** The line under the ready
  count used to draw only the key or only the pad button, whichever this machine
  was last touched with; it draws both now.

- **Crashing in the waiting room costs nothing.** You come straight back with no
  respawn wait, and no joker pick comes up over the screen while everybody else is
  waiting on you.

### Fixed

- **Every pad can join and pause.** Only the first pad plugged in answered to Start
  and to the menu buttons; the others could drive but not take a seat, pause or
  work a menu. And Start on a pad nobody is driving now takes a seat instead of
  opening the pause menu.
## [0.4.1] - 2026-09-23

### Added

- **The Garage is a garage.** The practice rooms are set in a concrete workshop bay
  now, with tyres, tool chests, drums, cans, pallets and a two-post lift stacked
  against the walls all the way round it, and the camera sits closer than it does
  in a match, since there is no crowd out there to look at.

### Changed

- **The pot's cells grow to fit their numbers.** A mult of 24.5 was losing its last
  digit. The HUD pane around them is a constant width as before.

- **The podium no longer comes up over a joker pick.** A kart killed after the
  whistle was still offered one, and the cards sat over the standings unusable.

- **The Vault's wheel has more pockets.** Twenty-eight red and black ones rather
  than eighteen, which read as a pie chart.

- **Crossfire's Junction drops its two painted bay lines.** The hazard border round
  the edge says what the pad is; the lines argued with it.
## [0.4.0] - 2026-09-22

### Added

- **A fixed camera, in the accessibility settings.** It holds the whole arena for
  the match instead of following the karts, and still comes in at the start.

### Changed

- **The Junction wears its room.** A roulette wheel in The Vault, a marked-out bay
  in Crossfire, a bolted steel plate in Lucky Crossing.

- **The fireworks are louder.** The bangs sit over the fanfare now rather than
  behind it.

- **The camera looks ahead of the kart you are driving.** The aim slides the way you
  are travelling, so there is more road in front of you than behind.

- **The Yard keeps barrels where you can see them.** A stack now stands in against
  the fence on either flank instead of only turning up out past the crowd.

- **The standings rank by banked coins.** A carried pot is still shown beside the
  score, but it no longer moves anyone up the board.

- **Fewer signs in the Garage.** Only the Junction, the Jackpots and the joker pad
  are labelled now; the rest name themselves.

- **The Swivel Cannon is named once on the HUD.** It was listed twice, as an effect
  and as a loaded cannon, counting down alongside itself.

- **No prop in a room stands inside another.** Every prop now asks for the patch of
  table it actually covers, so the Yard's barrels keep out of each other for good.

- **The Vault's dice no longer land in each other.** A pair is set down either side
  of its place rather than dropped at random near it.

- **The settings switches are drawn smoothly.** They are painted at four times
  their size with soft edges, so they stay round on a big display.

- **The Vault keeps its cards nearer the camera.** More of the hands are fanned out
  on the near apron, and the apron itself starts closer in.

- **The crowd fades out the further back it goes.** Eight rows now instead of four:
  packed at the rail, and thinner and further apart with every row behind it.

- **There is something at the bottom of a pit now.** Rusted rebar in the yard,
  nails on the workbench, something dark under the card table, and black and yellow
  painted round the rim of the yard's.

- **Crossfire gets a forklift, and its fence comes down.** The fence behind the
  crowd is half the height it was, the painted hazard stripes are one area at the
  back rather than three patches, black and yellow tape is strung across what is
  cordoned off, and there is a hard hat hung on the hoarding.

- **The Vault deals in four suits.** The cards it leaves about are hearts, diamonds,
  spades and clubs, its chips and dice carry their own markings, the rope line is a
  row of brass stanchions with a velvet rope, and there is a little of it dropped on
  the floor of the arena itself.

- **Chips and mult have a colour each.** The pot on the HUD is now two pills, blue
  chips and red mult with the multiply between them, rather than a line of
  arithmetic.

- **Crossfire is fenced and marked out.** A fence runs behind the crowd on three
  sides, hazard stripes are painted where the plant works, and the barriers wear
  black and yellow rather than traffic orange.

- **Every map hangs its hoardings its own way.** The workshop bolts one to a
  scaffold tower and stands another out on a flank, the card room hangs both from
  rods, and the yard braces a pair out by the corners.

### Fixed

- **A room deals its clutter rather than rolling for it.** The yard was ending up
  with piles of barrels in one corner and nothing anywhere else; each kind of thing
  now comes out once before any of them comes out twice, and a prop with nowhere
  free to stand is left out rather than stood on top of something.

- **The Vault's hoardings are clear of the clock.** One stood a few metres off the
  clock board and read as a second board stuck behind it.

- **The dice are dice.** Every one was showing five on the top and nothing on any
  other face; they are thrown now, with pips on every side a camera can see and
  opposite faces coming to seven.

- **A setting that is off can be seen.** The empty tick boxes in Settings were
  invisible against the dark menu; every on-or-off setting is now a switch with a
  dark track and a pale knob, gold when it is on.

- **The speed readout is not clipped.** At three digits the h of km/h was half a
  letter.

- **Props stop standing in each other.** The things placed by hand -- the lamp, the
  vice, the truck, the forklift, the floodlights -- never reserved the ground they
  were on, so the clutter was dealt straight through them; the fences and hoardings
  did not either. The truck is built out of parts that sit on each other rather than
  inside each other, and the hazard border round a pit no longer doubles up at the
  corners.

- **The card room's suits and dice are drawn properly.** Hearts and clubs came out
  looking like diamonds, and a die wore a quarter of a pip on each corner.

- **The wall behind the workbench can be seen.** It stood too far back, in the
  table's own colour, with its pegboard hung above the top of the screen.

- **Long props stop lying through short ones.** A bundle of rod stock or a stack of
  boards reserved the same patch of table as a mug did, so anything longer than the
  patch ran through whatever was next to it.

- **A player's HUD block holds its width.** It grew and shrank with the speedometer
  and the pot, which made the corner of the screen twitch all match.

- **Nothing in a room is put down on top of anything else.** Stacks of chips grew
  out of the DJ booth, hoardings stood in piles of rod stock and a fanned hand of
  cards flickered against itself; every prop now takes a patch of table nobody else
  has, and a fan is dealt one card over another.

- **The wall behind a room is close enough to see.** It stood sixty metres past the
  crowd with nothing in between; it now runs just past the clutter, and the table
  ends with it.

- **The rooms are packed in tighter.** Everything the maps are dressed with now
  starts right behind the crowd instead of trailing off into the distance, so the
  truck, the brick pallets and the rest are close enough to see.

- **A match opens on the room it is played in.** The camera is placed to hold the
  whole map and the crowd round it as the map finishes loading, and moves in on the
  karts from there over the countdown.

- **Each room has landmarks of its own.** A lamp on an arm and a vice on the bench,
  two shades and a pair of pictures in the card room, a lit sign and painted
  markings in the yard.

- **A map is put up behind a loading screen.** The room is built a phase at a time
  with its name and a progress bar on the screen, rather than in one go while the
  last screen sits frozen.

- **The scenery is baked into a handful of meshes as a map loads.** The rooms were
  asking the card to draw everything they are dressed with one chip and one card at
  a time; The Vault now asks for less than half of what it did.

- **The rooms are tidied.** Everything outside the arena is lined up with the table
  and stacked rather than scattered: rod stock in bundles, barrels in a row with
  one on top, cones in a line, chips squared off.

- **The Vault's cards look like cards.** The cards and decks left round the table
  were blank white slabs half again too big; they now carry a face and a back, at
  the size a card is next to a kart, and there are fewer of them.

- **Walls have a moulded top instead of a drawn-on edge.** The strip round the top
  of a wall shared a plane with the side of it and the two flickered against each
  other; a wall is now a block with a smaller block on it.

- **The Vault's lamp reaches the table round the arena.** The cards and chips left
  out there were in the dark; the edge of the cone now falls on them.

- **The walls and the boxes belong to their room.** Walls wear a capping strip and
  some of them carry a stack of chips, a cone or a handful of bolts; the breakable
  boxes are packs of cards in The Vault, stacked offcuts on the workbench and
  cement sacks in the yard.

- **The Yard is warm.** It was lit like a cold grey morning; it is now a low
  afternoon sun over the concrete, with dust in the air rather than frost.

- **The maps stand in a room rather than on a plane.** The table has an edge and
  legs, a floor under it and walls round it, and each room is dressed with what
  belongs to it: tools on the workbench, chips and decks in the card room,
  scaffolding, hoarding and a truck in the yard.

- **The Vault's bloom is the halo it was meant to be.** The glow was blurring a
  step wider than it was asked for, and lighting a room printed an error while it
  did.

- **The rooms run at the frame rate the game had before them.** The lighting and
  the effects behind the new look were costing nearly half the frame rate; they
  now cost almost nothing outside The Vault, which spends half a millisecond a
  frame on the bloom its neon is made of.

- **Numbers stop jittering.** Scores, the clock, speeds and the standings are set
  with tabular figures, so a line does not shift sideways every time a digit
  changes.

- **Shadows are softer.** They were dark enough to read as holes in the floor;
  they are now a dark side, and the sooty corners are gone with the screen-space
  occlusion that was drawing them.

- **A dead player can still read their hand, sudden death included.** The cards
  would not open at all once the clock had run out, and the pane offered two
  buttons that do nothing while you are down.

- **The lights always find the winner.** A leader who was down at the whistle used
  to be passed over and the rig kept sweeping.

- **Bots shoot at what they are bumping into.** A kart pressed up against a bot
  was too far off its nose to be fired at, so it got shoved around instead of
  shot.

- **The test track keeps the hint off the kart.** The signs along the road
  already say what every button does.

- **The test track's end room is twice as wide.** Room to get a drift wrong and
  go round again, which is what that room is for.

- **The D-pad picture loses its box.** It is a cross, which is already a shape,
  so it is drawn the way the face buttons and the stick are.

- **Aim assist fades on a kart that is standing still.** Sitting with the nose
  pointed down a corridor no longer aims for you; driving off hands the help
  straight back.

### Added

- **A loaded cannon shows on the HUD.** The Spread Cannon and the Ricochet Cannon
  are loaded with shots rather than timed, so they now get their own line counting
  the shots down.

- **The HUD says what power-up is running on you.** Under the item in hand,
  whatever it started is named in its own colour with a bar counting down the time
  it has left.

- **Bloom and edge smoothing can be turned off in Video settings.** They are the
  two passes over the whole screen a room pays for; turning both off is most of
  the difference between The Vault and the other maps on a card that is
  struggling.

- **The lobby says which room a map is played in.** Picking The Vault says
  "Played in After Hours" under the row.

- **Every map is played in a room of its own.** Lucky Crossing keeps a warm table
  under a workbench lamp, The Vault is a dark room with one light over the felt,
  and Crossfire is played in cold daylight.

- **The pads are set into the table.** The Junction is a roundel with metal rings
  rather than a black hole with a pink ring, and the coin, power-up and turbo pads
  wear rims and frames instead of lying on the felt like stickers.

- **The signs are lit.** The hoardings and the clock carry their own light in a
  dark room, so a board over the crowd can still be read at The Vault, and stay
  paint on a board in daylight.

- **Karts are painted, not coloured.** A coat of lacquer over the body colour, so
  the light runs along a kart as it turns, and chips on the floor are chips: a
  notched rim, a printed face, and metal for the gold ones.

- **The menus are built out of one set of parts.** Buttons are cards that light up
  under the cursor, the title screen wears the game's own mark over its name, and
  the kill feed carries its own shadow so it reads over a bright table.

- **The game has a typeface.** Every screen is set in Inter now, on one scale,
  with scores and headings in a heavy cut and sentences in a light one, instead
  of the engine's default font at nine different sizes.

- **The crowd is dressed for the room it is standing in.** Deepened carnival
  colours at Lucky Crossing, silhouettes with neon on their edges in The Vault,
  workwear in Crossfire, instead of a thousand random bright shirts everywhere.

- **The table is made of something.** Felt with worn patches, a surround of
  boards with the grain running along them, painted blocks and concrete slabs,
  instead of flat colour everywhere.

- **A logo of its own.** The game wears a mark rather than the engine's: the
  Junction from above, a gold chip with a crossroads through it.

- **Billboards around the table.** Two hoardings advertising the house, drawn at
  random from a set so a run of matches is not the same two posters, and a third
  keeping the match clock on an LED display. The clock board counts the field down
  with READY, SET and GO!, flashes OVERTIME through sudden death, and names the
  winner at the whistle.

- **Fireworks for the winner.** A won match is seen off with a display over the
  table in the winner's colour, through the pause before the podium and on under
  it.

- **Two more music tracks.** Ginger Bread and Let It Breathe join Deceased
  Rodent, each in the same three intensities, and one is picked at random when a
  match starts.

- **A picture on every joker card.** Each joker has a pictogram of its own in its
  kind's colour, in place of the initials, so a card is recognised by its shape
  rather than read.

- **Lives are hearts.** They were squares, which say one of something without
  saying what.

- **Losing or regaining a life shows a heart, not words.** A small heart breaks
  over your kart when a life goes and a whole one floats off when the Junction
  hands it back, in place of "-1 LIFE" and "PATCHED UP".

- **A picture for every power-up.** The item you are holding shows its own
  pictogram beside its name, and the roulette flicks through the others while the
  box is still opening.
## [0.3.3] - 2026-09-21

Camera work: it sits closer to the karts, keeps the arena centred in the frame,
and opens out to the whole table at the whistle.

### Changed

- **The score tanks' caps sit on top of the glass.** They were sunk into it, so
  the tank wall cut through the ring and the cap came out looking cracked.

- **The camera sits closer to the karts.** Less floor around them before it
  starts pulling back, and it comes in further when they are packed together.

- **The camera opens out to the whole arena at the whistle.** While the lights
  swing onto the winner it eases back to show the table, and the podium comes up
  over that.

- **The screen stops shaking at the whistle.** A match that ended while the room
  was at its loudest kept trembling through the pull-out and on under the podium.

- **The arena sits in the middle of the screen.** There was a band of empty table
  above it and almost none below, because the camera is tilted and the framing
  only ever chose a distance. It now aims so the spare room is split between the
  two.

- **A picked joker card only goes up.** It used to straighten out of the fan as
  it rose, which slid it sideways at the same time.

- **The same for the joker pick.** The card under the cursor grew as it rose,
  and the growing dragged it left along the row. It rises in place now.

## [0.3.2] - 2026-09-20

A tank per player beside the arena that fills as you bank, and a camera that
comes in on the karts instead of framing the whole room.

### Changed

- **No standings in the Garage.** There is no clock and nothing to reach in
  there, so the running order was a table of two dummy karts and you.

- **Button pictures stand out against the game behind them.** They were drawn on
  a faint wash of the text colour, which disappeared into a busy arena: the Y for
  the joker hand and the shoulder buttons for drift and nitro were the worst of
  it. Every picture now sits on a solid dark chip with a rim, and a gamepad's
  face buttons are filled in with the colour the pad has them in.

- **The stick picture says which stick it is.** It has an L written inside the
  gate, or an R for the right one, and it is drawn as a bare button the way A and
  B are rather than inside a box.

- **A tank per player beside the arena.** Glass tanks stand on the table outside
  the wall and fill with your colour as you bank, full at the score that wins. A
  glance says how close anybody is to taking the match, which the numbers do not.

- **The camera frames the karts, not the room.** It comes in as close as it can
  while keeping every kart on screen and follows them around the floor, so a
  fight in one corner fills the screen instead of sharing it with three empty
  corners and the crowd. Parts of the arena go off the edge when they do; no kart
  ever does.
## [0.3.1] - 2026-09-20

Buttons you can see. Every hint that used to spell a binding out in words now
draws the thing you press, and the rest of this is the round of fixes that came
with it: a test track with room to use nitro and to drift through its chicane, a
turbo pad that actually shoves you, a booth standing in its own crowd, a whistle
with a moment before the podium, and a decoy that can no longer fetch the Jackpot
for you.

### Changed

- **The podium starts with Rematch selected.** A gamepad no longer has to go
  looking for a button on a screen that came up by itself.

- **A Decoy Kart cannot collect the Jackpot.** Parking one on the pile handed the
  whole thing to you from across the arena, and stopped anybody who actually
  drove there from collecting it. It now counts for nothing on the tile, the same
  as it does on a Royal Flush pad.

- **Controls are shown as buttons, not spelled out.** Every hint that names a
  binding now draws it: a key cap with the key on it, the round coloured face
  button your pad actually has, a pill for a shoulder or a trigger, a stick seen
  from above, a cross with the pressed arm lit for the D-pad. That covers the
  hints under your block, the joker hand and pick, the hint beside your kart at
  the start of a match, the signs on the test track, the join line in the lobby
  and the rebinding rows in Settings.

### Changed

- **The test track's nitro straight is long enough to use nitro on.** It ran out
  about when the bottle got going. It is 45 m now, with the sign at the near end
  of it.

- **The test track's chicane has a gap you can drift through.** The way between
  the two stubs of wall was one cell wide, which is a keyhole to be lined up and
  crept through. It is three wide now.

- **A turbo pad fires you down its arrow and holds the throttle.** The pad points
  your kart along the arrow, sends it off at 150% of top speed, and keeps your
  foot down for a second whether or not you are touching the trigger. The wheel,
  the handbrake and the brake are yours the whole time, so you steer and drift
  through the boost instead of either riding a rail or throwing the boost away by
  turning.

- **The DJ booth stands in the crowd.** It was out on its own behind the back
  row. It is a couple of rows in now, with people in front of it and people
  behind it.

- **The whistle gets a moment before the podium.** The karts roll to a halt and
  the lights swing onto the winner for a couple of seconds, the music steps back,
  and then the screen comes up.

## [0.3.0] - 2026-09-20

A room worth sitting in. The arena picked up a crowd a thousand strong on
tribunes, a DJ booth, and two more maps to choose between in the lobby; the karts
picked up paint, hats, flags and trails, and their drivers picked up names; the
end of a match picked up a podium; and the Garage picked up a test track in front
of it that teaches the controls a sign at a time. Underneath all that: seven new
jokers, a Junction that no longer patches you up for free, hard bots that come
after whoever is carrying the money, aim assist that looks at more than karts, and
a long list of smaller things that were wrong.

### Changed

- **Nitro is on the right shoulder.** On a gamepad nitro has moved off B onto the
  right shoulder button, opposite the handbrake. It is held rather than tapped,
  and holding a face button through a corner meant fighting the thumb that was
  steering through it.

- **The notice about a lost host says where you are going.** It said the title,
  which is what the first screen is called in the code. A player sees a menu.

- **Out of time says what happens.** The lobby offers Last one standing and Match
  ends where it used to offer Sudden death and Whistle on the hour. Both of those
  needed the rule explained before they meant anything.

- **The Junction only patches you up once every three seconds.** A wounded kart
  parked on the pad used to get its life back the instant it lost it, so the one
  place everybody has to visit was the one place nobody could be finished off.
  The wait runs whether the kart stays put or drives off and comes back.

- **The Junction refills your nitro four times as fast.** Cashing out parks you
  still and in the open in the middle of the arena, so the pad now hands you the
  one thing that gets you out of there again, on top of whatever the hot table is
  already giving you.

- **Big Tank is worth two bullets.** It gave one more bullet in the air, on top of
  three, which was hard to feel next to what the other common jokers do. It now
  gives two.

- **Six jokers hit harder.** Nitro Habit stretches drift boosts and turbo pads
  three times rather than twice, Slipstream grazes are worth +1.5 mult, Green
  Light pays a whole point of mult per turbo pad, Vulture makes a dropped chip
  worth three coins, Loaded Dice turns a quarter of your chips gold, and Toll
  Booth takes 15% of everybody else's cash-outs instead of 5%.

- **Aim assist aims at everything worth shooting.** Boxes, bombs and shooting
  targets bend a shot the way a kart always did, and nothing behind the shot can
  take the aim off what is in front of it any more. Karts still come first: a box
  has to be well inside a player to be chosen over one.

- **Hard bots come after a big pot.** They look further for whoever is carrying
  one, pick the richest kart in range over the nearest, and a pot big enough will
  take them off almost any errand. Easy and normal bots still fight whoever
  happens to be closest.

- **The results screen is laid out properly.** Everybody gets a row of their own
  built like the joker detail pane, with their colour down its leading edge, their
  score in gold on the right, and each award on a chip of its own rather than run
  together into one line. The row belonging to whoever is reading it stands out of
  the rest.

- **The name box says Player rather than A funny one.** The box is asking for a
  name, not describing what happens if you leave it empty.

- **The results screen is headed Podium.**

- **Bullet marks are round.** They were squares, which read as stickers rather
  than as holes.

- **The pause menu and the online lobby are built like the rest of the game.**
  Both sit on the same dark pane with a bar of colour along the top that the joker
  details and the podium use.

- **Nitro comes back almost at once in the Garage.** A tank in a few seconds
  rather than a minute and a half, so the button can actually be tried out.

- **Flags fly off the back of the kart** rather than out of its side.

- **The portal is smaller.** It was a wide pad for what is a door.

### Added

- **A one-minute match, in debug builds only.** Long enough to reach the Junction
  and the results screen, short enough to do it again straight away.

- **A new joker, Payday.** A coin every second, wherever you are and whatever you
  are doing. Uncommon.

- **A new joker, Hot Streak.** Half a point of mult every ten seconds you stay on
  the floor. Rare.

- **A new joker, Odometer.** A coin for every 20 m you drive. Common.

- **A new joker, Tailslide.** A coin for every 8 m you spend sideways. Uncommon.

- **A new joker, Jerry Can.** Nitro refills four times as fast. Uncommon.

- **A new joker, Direct Debit.** Five points of your pot bank themselves every
  second, wherever you are, and your mult is left alone. Uncommon.

- **A new joker, Deep Pockets.** Two more joker slots, one of which it stands in,
  and it stacks. Rare.

- **Joker cards say how rare they are.** One, two or three pips under the name,
  steel for common, cyan for uncommon, magenta for rare, and the pane that
  describes a joker names the rarity next to the kind.

- **Two dummy karts in the Garage.** Nobody is driving them, so they never shoot
  back. Each carries a pot of coins and an item, so shooting one scatters loot
  worth picking up, and each comes back after a moment carrying something new.

- **Taking a place in sudden death is called out.** A kill in overtime that puts
  you past the player you took out reads OVERTAKE across the middle of the
  screen, or TAKING THE LEAD when it puts you top of the board, and counts toward
  a Last Word award on the results.

- **Bullets leave marks on the walls they hit.** A small scorch in the shooter's
  colour, fading out over a few seconds, so a wall that has been shot at looks
  like one.

- **Players have names.** Anybody who has not set one is handed a silly one off a
  list, so the standings, the kill feed and the results screen read as a room full
  of people rather than P1 through P4. Names carry through a rematch and reach
  every screen online.

- **The lobby has a name box for every player.** Up to 16 characters each,
  remembered between sessions. Left empty, the match hands out one of the funny
  ones.

- **The results open on a victory podium.** The top three on three steps, the
  winner in the middle on the tallest, each with their own kart standing on top of
  it turning on the spot.

- **Online players can set their name.** The screen you host or join from asks
  what you are called, so somebody joining a friend never arrives under whatever
  name that machine last used.

- **You can see the Jackpot pile running out.** The kart collecting it wears the
  same progress ring the Junction draws, since the count on the floor is under the
  kart standing on it, and the pile going throws a handful of gold up off the tile.

- **A kart coming back says so.** A ring opens across the floor in the player's
  colour with a column of light in it, so a respawn reads from anywhere in the
  arena rather than only to whoever was watching that kart blink.

- **Menus answer the gamepad.** A presses the button under the cursor and B backs
  out, in the pause menu, the lobby, the online screen and the settings. The title
  screen has nowhere to back out to, so B does nothing there.

- **Ramming somebody knocks coins out of them.** A ram they live through spills a
  quarter of their coins, at most 8, onto the floor for anybody to pick up.

- **Crashes come through the pad.** Hitting a wall or another kart knocks the
  gamepad, as hard as the hit was, on top of the sound.

- **A test track, before the Garage.** The first time you pick Garage you arrive
  on a road instead: a straight, some corners, a wall of boxes to shoot through, a
  straight to open the bottle on, a chicane to drift and a room at the end. Each
  stretch has one word on it and the button it names. A portal at the end leads to
  the Garage, and the Garage has one back.

- **Dress your kart.** Four things to pick in the lobby beside your name: a paint
  pattern, a hat, a flag and what the kart leaves behind it. Your colour is still
  your colour underneath, and everybody sees the same kart online.

- **Two more arenas, and a choice of which to play.** The Vault puts the Junction
  in a walled box with four ways in; Crossfire leans four diagonals away from the
  middle so every approach is a corner. The lobby picks one, and online everybody
  plays the host's pick.

- **A crowd, and a DJ booth.** Small figures stand on the table all the way round
  the arena and get up on their feet when the room is going or when somebody is
  taken out. The booth's speakers pulse on the beat.

- **The title screen has something behind it.** A slow carnival sunburst with
  poker chips drifting up past it.

- **A chequered flag to fly.** A fourth flag, in the colours a chequered flag
  comes in rather than the player's.

- **You can read your hand while you are dead.** The joker menu opens and the
  cursor walks; dropping and destroying wait until you are back on the floor.

### Fixed

- **Shots are not bent toward what they cannot reach.** Aim assist, and Curve Ball
  most of all, would swing a bullet toward somebody standing safely behind a wall
  and bury it in the brickwork. Anything with a wall or a box in the way is now
  passed over for whatever is on this side of it.

- **The podium sits properly in its frame.** The karts were clipped along the top
  edge with empty space under the steps; the picture is aimed a little higher now.

- **An online match keeps running when the host looks at something else.** An
  unfocused window could hold the whole main loop up waiting for the desktop to
  take a frame, which froze every client in the room until somebody clicked back.

- **The joker pick cannot be answered for half a second.** You are killed with a
  thumb on the trigger and the cards open under it, so a card was being claimed
  before anybody had read it. Moving the cursor still works the whole time.

- **The joker hand goes away at the whistle.** It was lying across the bottom of
  the podium screen.

- **Hats sit down on the head.** They were perched level with the top of the
  helmet, which read as a hat hovering just above it.

- **A Decoy Kart is dressed like you.** It had your colour and none of the rest of
  your kart, which rather gave it away.

- **Kart paint has clean edges.** The patterns were drawn at sixteen pixels and
  snapped to them, which looked like it.

- **Confetti can be seen.** It was flat squares small enough to miss, half of them
  edge-on at any moment; it is tumbling blocks now, bigger and twice as many.

- **The podium steps wear their colour cleanly.** The grey of the step was showing
  through the coloured plate on top of it in patches.

- **The Garage portal is clear of the wall.** It was standing half inside the
  bottom one.

- **The joker hints name the stick, not the axes.** On a pad they read "Left stick
  cycle" rather than "Left Stick X-Axis - / Left Stick X-Axis + cycle".

- **A turbo shove can be steered.** Leaning on the wheel pulls the line round
  after the nose instead of doing nothing until the shove is thrown away
  altogether. Hands off, it still holds the arrow exactly.

- **The test track is bigger, and the camera comes down to it.** The lanes are
  half again as wide and the road is longer, so a corner taken badly leaves you
  room to carry on rather than parked against a wall. The camera follows your
  kart from close in instead of framing all sixty-five metres of road at once.

- **The test track's signs say what the button does.** They were a word and a
  key: "DRIFT" over "Shift". They now read "DRIFT" over "handbrake and turn",
  with a HANDBRAKE sign at the first stub of the chicane saying what locks the
  wheels.

- **The crowd is a crowd.** There was one person per two metres in a single line
  round the arena. There are now getting on for a thousand of them, four rows
  deep, no two the same height, colour or heading, standing where they like
  rather than on a grid, with gaps in the rows. The lot of them draw in two
  calls and cost nothing per frame, so a full house runs the same as an empty
  one did.

- **Tribunes round the table.** A stretch of each side of the crowd is up on
  steps behind a back wall, with everybody on it a step higher than the row in
  front.

- **The crowd can be sent home.** Accessibility settings has a Crowd switch, on
  by default. Off empties the stands and leaves the DJ booth where it is.

## [0.2.0] - 2026-09-18

Multiplayer. Online play worked before this and did not feel like it: every button
a player pressed went to the host and came back, so at any real ping the kart
answered late and driving felt like steering through treacle. A client now drives
its own kart and answers its own controls on the frame they are pressed, and the
host puts it right where the two ever disagree. Almost everything below follows
from that, one way or another.

### Fixed

- **Online: a client's kart comes back from a hole, and a dead kart is out of the
  way.** Falling down a hole on a client left the kart there for good: a respawn
  is the host's to place and a kart being driven here was ignoring the host's
  position, so it came back still standing in the hole and fell down it again.
  Separately, a kart somebody had just shot went invisible on every other screen
  but stayed solid where it died, so the spot could not be driven through until
  it respawned.
- **Online: a kart that has been down a hole is solid again.** Falling takes a
  kart's collisions away, and on a client the kart is dead, stood down and
  brought back between losing them and being driven again, so it came back able
  to drive through walls for the rest of the match.
- **Online play is written down.** GAME.md 10.3 opens with who decides what, as a
  table, along with what the arrangement guarantees and what it does not.
- **Online: pulling the trigger answers at once.** The cannon goes on cooldown and
  the shot is heard on the tick the button goes down; the bullet still comes from
  the host, because whether one lives depends on a bullet fired by somebody a
  client only sees where they were a round trip ago.
- **Online: the floor is sent as what changed.** Every chip on the ground went out
  thirty times a second whether or not it had moved, which was the largest part of
  a snapshot and most of why one did not fit in a single packet. A typical snapshot
  is now about a fifth smaller, and more on a busy floor.
- **Online: chips pulled in by a Coin Magnet move on every screen.** They sat
  where a client first saw them and blinked out from there, so both halves of the
  effect were missed.
- **Online: nitro stops flickering on a client.** It was lit on the tick the button
  went down and then put out again by the host'''s word for it, a round trip behind.
- **Online: a correction says so on screen.** A client that is put back where the
  host has it now shows how far it moved and how many times it has happened, so a
  bad connection reads as a bad connection rather than as a bad kart.
- **Online: a rematch starts fresh on every screen.** A client keeps its own
  excitement meter and announcer, and nothing told either of them the last match
  was over, so the new one opened at the old one's heat with the lights still
  going and somebody still on a killing spree they earned in a finished game.
- **Online: the Swivel Cannon aims where a client is aiming.** Free aim never
  crossed the wire when it came from a mouse, so the host asked where its own
  pointer was and fired the client's shot at that.
- **Online: a rematch keeps the players who are in it.** The host pressing
  Rematch started again from the lobby's list, so every connected player's kart
  was handed to a bot while they carried on steering it.
- **Online: a chip pulled in by the Coin Magnet flies into the kart.** On a
  client it blinked off the floor instead: the magnet triples how far a kart
  reaches, and a client judging who took something was still using the plain
  reach.
- **Online: turbo pads shove a client's kart again.** They had stopped working on
  clients altogether: the pad could not see a kart being driven there, and the
  host's shove lost to that machine's own answer about where its kart was.
- **Online: dropped chips fly out on every screen.** Coins and items thrown clear
  of a bursting kart or a breaking box only arced on the host; everybody else saw
  them appear on the floor already landed.
- **Online: things a client does now happen when it does them.** Nitro burnt a
  round trip late, driving into a crate at ramming speed stopped the kart dead
  and then dragged it through, driving into another kart carried on through
  where they were standing, driving into a hole crossed it and then fell in
  backwards, and the joker cursor moved a round trip after the key. All of them
  are answered on the spot now and put right by the host afterwards. A kart that
  falls in a hole stays in it rather than being lifted back out to fall in again
  when the host catches up, and a box driven through at ramming speed comes off
  the floor rather than being ploughed through while still drawn, and stays off
  it rather than being put back by the next snapshot under the kart that has
  already gone through it.
- **Online: picking a joker on a client.** A player whose kart had died was not
  heard by the host at all, so no card could be picked, no cursor moved and
  nothing answered until the kart came back on its own. The same held on the
  grid during the countdown.

### Changed

- **Losing the host says so properly.** The notice now sits on a pane like the
  one that describes a joker, and has the screen to itself: the HUD stands down
  and takes any open joker pick, the standings and the control hints with it.

- **Online play: your own kart is yours.** A client drives its own kart on the
  frame the stick moves, and the host takes its word for where that kart ended
  each tick rather than working it out again. The host takes the wheel back only
  for what one end cannot settle alone: running into another kart, being hit,
  oil, going down a hole, dying, coming back. Over 100 ms of round trip the kart
  answers at once instead of five ticks later, and through four seconds of
  driving, drifting and handbrake turns the host had nothing to correct at all.
  On a wire losing a packet in five the corrections are absorbed whole: the kart
  a player is looking at does not move for them. A claim further out than a few
  ticks of driving is refused, so this cannot be used to appear somewhere else,
  and everything that decides the game is still the host's: what you collected,
  who you hit, what it was worth.
## [0.1.0] - 2026-09-18

### Added

- **The table.** A top-down arena kart game for one to four players. Drive a
  drifty toy kart around a felt-topped diorama, collect poker-chip coins and
  multipliers, and decide when to cash out before somebody shoots you.
- **Push your luck.** Everything you are carrying is a pot of coins times a
  multiplier, and it is only yours once you have driven it onto the Junction and
  sat there while it drains. Dying hands half of it to the bank, scatters some on
  the floor and may cost you a joker.
- **The Junction.** The cash-out pad, paying faster the longer you hold it, and
  patching up a wounded kart with the last coin of a pot. Its ring blinks when
  you are carrying something worth protecting, and goes flat gold when you are
  one cash-out from winning.
- **The Jackpot.** A pile in the corner that grows on its own and pays whoever
  stands in it, contested to a standstill when two karts arrive at once.
- **Royal Flush pads.** Four pads that trickle coins to whoever holds them, and
  hand out a multiplier and a full nitro tank to anyone holding all four.
- **Jokers.** Cards that bend the rules, picked one of three when you die, held
  five at a time, dropped on death and lying on the floor for anyone to take.
- **Power-ups.** Held items used on a button: shields, bombs, oil, boost,
  turrets, decoys and cannon swaps, on pads around the table.
- **Combat.** A forward-firing cannon with bouncing, colour-coded bullets that
  cancel each other, grazing for multiplier, two lives, and spawn protection.
- **Driving.** Drift with a handbrake flick, a boost for carrying one all the
  way round, a nitro tank, turbo pads, tire marks, smoke and sparks.
- **Bots.** Three difficulties of opponent that pick real goals, navigate the
  room, drive on the limit and cash out on purpose. They watch how the humans in
  the room play and aim for that.
- **Local multiplayer.** Up to four players on one screen, joining in the lobby
  or mid-match by taking over a bot, each with their own corner of the HUD.
- **Online multiplayer.** Up to four players over direct IP, host-authoritative,
  with clients taking over bot karts and the host's match settings.
- **The finale.** Last Call doubles the payouts for the final thirty seconds,
  and overtime turns the whistle into sudden death where the last kart standing
  takes everything it is carrying.
- **A room that reacts.** Six levels of excitement that build through a match and
  drive the music, the lights and the camera, a hot table that speeds the room up
  at the top, and an announcer calling out what just happened.
- **Results.** Rankings, and up to three awards per player picked from twenty-six
  statistics for whatever they did most.
- **The Garage.** A practice room off the title screen with no clock, no score
  and nobody else in it.
- **Settings.** Full rebinding on keyboard and gamepad, volume per bus, and
  accessibility options: the aim guide, flash reduction and colour-blind roof
  markers.

[Unreleased]: https://github.com/timvisee/jackpot-junction/compare/v0.13.0...HEAD
[0.13.0]: https://github.com/timvisee/jackpot-junction/releases/tag/v0.13.0
[0.12.0]: https://github.com/timvisee/jackpot-junction/releases/tag/v0.12.0
[0.11.0]: https://github.com/timvisee/jackpot-junction/releases/tag/v0.11.0
[0.10.1]: https://github.com/timvisee/jackpot-junction/releases/tag/v0.10.1
[0.10.0]: https://github.com/timvisee/jackpot-junction/releases/tag/v0.10.0
[0.9.0]: https://github.com/timvisee/jackpot-junction/releases/tag/v0.9.0
[0.8.2]: https://github.com/timvisee/jackpot-junction/releases/tag/v0.8.2
[0.8.1]: https://github.com/timvisee/jackpot-junction/releases/tag/v0.8.1
[0.8.0]: https://github.com/timvisee/jackpot-junction/releases/tag/v0.8.0
[0.7.0]: https://github.com/timvisee/jackpot-junction/releases/tag/v0.7.0
[0.6.2]: https://github.com/timvisee/jackpot-junction/releases/tag/v0.6.2
[0.6.1]: https://github.com/timvisee/jackpot-junction/releases/tag/v0.6.1
[0.6.0]: https://github.com/timvisee/jackpot-junction/releases/tag/v0.6.0
[0.5.2]: https://github.com/timvisee/jackpot-junction/releases/tag/v0.5.2
[0.5.1]: https://github.com/timvisee/jackpot-junction/releases/tag/v0.5.1
[0.5.0]: https://github.com/timvisee/jackpot-junction/releases/tag/v0.5.0
[0.4.1]: https://github.com/timvisee/jackpot-junction/releases/tag/v0.4.1
[0.4.0]: https://github.com/timvisee/jackpot-junction/releases/tag/v0.4.0
[0.3.3]: https://github.com/timvisee/jackpot-junction/releases/tag/v0.3.3
[0.3.2]: https://github.com/timvisee/jackpot-junction/releases/tag/v0.3.2
[0.3.1]: https://github.com/timvisee/jackpot-junction/releases/tag/v0.3.1
[0.3.0]: https://github.com/timvisee/jackpot-junction/releases/tag/v0.3.0
[0.2.0]: https://github.com/timvisee/jackpot-junction/releases/tag/v0.2.0
[0.1.0]: https://github.com/timvisee/jackpot-junction/releases/tag/v0.1.0
