# Changelog

What changed in Jackpot Junction, for people who play it rather than for people
who read the commits. Every change a player would notice gets a line here in the
same commit that makes it, see GAME.md 10.4. The format is
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the versions are
[semantic](https://semver.org/spec/v2.0.0.html).

`tools/changelog` checks this file, cuts a release out of the Unreleased section
below, and hands the notes to the release workflow.

## [Unreleased]

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

### Changed

- **Touch driving shows its two layouts as pictures.** Slider and Buttons are picked
  in Settings the way the driving is.

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

[Unreleased]: https://github.com/timvisee/jackpot-junction/compare/v0.6.1...HEAD
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
