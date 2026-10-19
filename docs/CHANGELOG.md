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

- **Steam's keyboard on the screen.** On a Steam Deck, a Steam Machine or in Big Picture, typing a
  name, a password or an address brings up Steam's keyboard beside the box; with a pad, press A on
  the box.
- **A fez and a magnet.** The Ten Times Bar now also pays a fez, and Chip Alley a Magnet flag
  that grows and comes alive while a Chip Magnet or Magnet Hubcaps pulls chips in.
- **Next new.** The catalog, the loyalty program and the achievements have a jump button, N or a
  pad's View, that jumps to the next thing wearing NEW and makes it stand out, so a few quick presses
  clear them all.
- **A tour of the loyalty program.** After the welcome's card, the House shows you round its map
  in four short steps on the map itself, and How it works shows them again any time.
- **Bets won, shown.** Opening the map now shows the bets you won since last time being stamped,
  their roads drawing out in gold; a few one by one, any more all at once.
- **Straight to the exam.** Enrolling in the driving school has a smaller button for players who
  can drive already.
- **Cones to knock over.** The driving test's cones go over when you hit them, and the examiner
  notes how many on the back of your license.
- **Your test time.** The license screen says how long your test took, and your best once you've
  beaten it.

### Changed

- **Where the loyalty map opens.** It opens at what you pinned, where you left it, or the nearest
  open bet, rather than on the slip road.
- **Quicker first bets.** The Cashier's Cage asks for 20 cash-outs rather than 25, and the first
  milestone, now Milestone 2.5, for 2.5 km rather than 10.
- **The House's amendments** at the Final Hand are worded to match what it does to the table.
- **The House's forecast** at the Final Hand is drawn much fainter, so it no longer gets in the way
  of driving, and is labeled on the floor; late in the match it shows the line its models follow.
- **The House's last page** has its tear-off tab beside the stamp now, where it is easier to find,
  and tears straight across from there.
- **The license after the Final Hand** is stamped by the House while you watch.
- **The title after the Final Hand** opens as it does when the game starts.
- **The Final Hand with other players** has the House seat more models late in the match where
  there are too few, so every player has one following them.
- **Straight to your free lesson.** Accepting the invitation now takes you to the driving school
  rather than the title.
- **The driving school's menu.** Escape, B, or on a touch screen the menu button in its corner,
  now opens a menu on every page of the school, with Settings and a way to skip the school, which
  asks first. The
  driving test's menu skips the school the same way.
- **The Highway Code at your pace.** The book waits on its title page until you turn the page,
  then riffles through to the end in a few seconds.
- **No more pop quiz.** The book's "Got that?" is the only question now. With the story on, the
  enrollment has a box over its Enroll button that ticks itself.
- **The driving school opens like the title.** Its first page comes in the same way, mark first.
- **A driving test on one open lot.** The rooms and gates are gone: six lessons on one lot, each
  bringing its pieces up out of the floor or down from the sky, so by the final exam the lot is a
  table. Steering, braking and drifting are folded into two lessons, drifting being an extra; the
  shooting lesson ends on a Turret; the jokers lesson deals two cards, the second from a trench you
  can't drive round, and leaves a pit open for more; and the exam asks for 500 points.
- **One place to read in the driving test.** The examiner's clipboard is now the only place with
  words: it comes up large in the middle as the test starts, then flies to its corner and pops
  out with a ripple at each new lesson, and each task shows its control. The word at the top, the cards beside the HUD and the words over
  the kart are gone; the kart shows just the key to press.
- **The plate on the License tab.** Your license comes with a plate made from your initials;
  change it on the License tab rather than at the end of the test. A retake puts the name you
  enroll under on your license.

### Fixed

- **Notes found online.** Kit's folder now peeks in beside the payout slip online too, so a note
  picked up in an online map can be read right after it.
- **The Final Hand's blacked-out settings.** The marker goes over the match settings in the order
  they are read again, the presets first and then down each column, since they moved into two.
- **Tap a toast.** On a touch screen, tapping an achievement's toast shows it in the achievements,
  as clicking it does.

## [0.19.0] - 2026-10-16

The story is retold, from the driving school to a Final Hand whose end is up to you, with the
House writing to you along the way. It doesn't play with 0.18.x.

### Added

- **NEW on the loyalty map's tabs.** The House's map and Kit's map tabs wear the NEW tag while a
  landmark won on that map hasn't been looked at yet, as the catalog's tabs do.
- **The House's mail.** As the story goes on, the House writes to you at the title now and then,
  and its letters are kept in Kit's folder.
- **Cards nobody printed.** Once the story is under way, a pick may now and then hold one of five
  cards drawn in pencil, each paying for something at a cost of its own.
- **Two more hidden achievements**, both of them choices the story leaves to you.

### Changed

- **The story, retold.** It now opens at the driving school, has its first note on your first map,
  and reaches its end in about two hours of play.
- **The Final Hand.** The story's last match plays like no other, and how it ends is up to you.

### Fixed

- **Notes in overtime.** A note lying in the map can be picked up in overtime too, and one left
  lying turns up again in the maps after.
- **Escape over Kit's folder.** By the payout slip it puts the note back, then the folder, before
  it opens the menu.
- **The license's scratched line.** It looks cut into the stripe now and catches the light as the
  card turns; the stub in the folder is torn along the same line as the invitation it came off.

## [0.18.0] - 2026-10-16

The House can deal its Final Hand online, and the menus are read out to a screen reader and show a
pointing hand over everything that can be clicked. It doesn't play with 0.17.x.

### Added

- **Screen readers.** With one running, the menus are read out: every button, setting, card, peek
  and hook by name, and notices, the start's lamps, who won and the card under a pick's cursor as
  they come up.
- **The Final Hand online.** Whoever has the say over a room, a host or the player holding it on a
  dedicated server, can deal the Final Hand to everybody once it is due for them. Every player plays
  it as their own candidate, and the room goes back to its lobby once all of them are through.
- **A Steam version.** The game can be built for Steam, with cloud saves, achievements, what you
  play in the friends list and games with Steam friends. The builds here on GitHub carry nothing of
  Steam.

### Changed

- **A hand over what can be clicked.** With a mouse, every button, switch, slider and tab shows the
  pointing hand, as do the kart bay's hooks, cans and keys, the peeks on the title and your jokers.
- **Customize kart.** The buttons to the kart dialog, in the pause menu's Clubhouse and on the Me
  page of Settings, now say Customize kart.
- **LAN games on a tab.** Play Online has a tab for your servers and one for games on your network,
  standing on the list, in place of the LAN games button and its own screen.

### Fixed

- **A host quitting ends the game for everybody at once.** Those who joined used to wait for their
  connection to give up before hearing the host had gone.
- **The F3 overlay offers only what works.** It no longer says F4 opens the tuning panel, which only
  the development playground has.
- **Hold to flip through Kit's notes.** Holding the D-pad or the stick left or right in the notes
  folder, or on a note up close, turns once and then keeps going quickly, as an arrow key does.
- **No taps through a dialog.** On a touch screen, tapping the loyalty program, the catalog, the
  achievements or Your kart opened over a pause menu no longer presses the menu's buttons under it.
- **Smoother camera feeds in the Garage.** The shader warm-up behind the title now films the room
  the way the dyno's and the Showroom's feeds do, so they come on with less to compile.
- **Turn your kart with a finger.** On a touch screen, dragging the kart in the Your kart dialog
  turns it, opened from the Garage's lift or a pause menu too.

## [0.17.0] - 2026-10-15

Jokers come in four suits that make poker hands, every map has slot machines, and you dress your
kart in the Garage's own bay. It doesn't play with 0.16.x.

### Added

- **Four more achievements.** Hold one drift for fifteen seconds, break 250 crates, make every hand
  and be Suited in every suit, and hit three of a kind on a slot machine at match point.
- **Joker suits and hands.** Every joker has a suit for what it feeds: Spades shooting, Hearts
  staying alive, Diamonds chips and Clubs driving. Three of one suit make your hand Suited, and
  hands like a Full House, a Rainbow or a Flush pay more on top.
- **Twelve new jokers** built for combining, from Double Tap, whose shots cut a wounded kart's
  grace, to Echo, which sometimes pays another joker's chips or mult again.
- **Slot machines.** Two on every map: drive onto one with 25 chips or more in your pot to bet a
  quarter of them, more of a big pot, and three sevens pay ten times the bet with lights, fireworks and
  confetti. Bots have a go now and then too. More stand along the far rail, lighting up for a big
  cash-out or a full Jackpot pile emptied by one kart.
- **The catalog by suit.** Show one suit's jokers, or the wild cards, and lay the cards out by
  suit.
- **Reroll a joker.** Once a pick, deal the card under the cursor again for 50 banked points, on
  the nitro key or the Reroll button.
- **More statistics.** The Statistics page has six groups now, with new Cards and Mishaps groups,
  and shows near misses, bomb kills, chips out of the Jackpot, jokers taken and more. Your longest
  drift, best kill streak, bullets shot down, biggest pot and Suited hands are counted from now on.
- **Your kart.** Dress your kart in the Garage's bay: a pegboard hook for each part, a rack of every
  piece to try on, the kart shown from the side that part is best seen, and a shuffle of the lot.
  Get there from the Garage's lift, the pause menu's Clubhouse, the bay door peeking in beside the
  title's Clubhouse, or the Me page of the settings.
- **A demo for a booth.** Start the game with `--demo` and it plays Grand Prix after Grand Prix on
  its own, two seats with their corners driven by bots, every kart in random dress. Press a couple
  of buttons to take a seat, or choose Play the full game from its pause menu; a quiet minute
  brings the demo back.
- **A dyno and a speed trap in the Garage.** Hold the throttle on the dyno by the right
  wall, or drive through the trap on the front straight, and the test bench shows your speed, the
  best of the visit and your longest drift, in a close look that comes up as you go.
- **Close looks on camera.** The Showroom's and the test bench's close looks slide in as a camera's
  feed, with a blinking REC, a running timecode, scanlines, static and the odd glitch.

### Changed

- **Match settings without the scroll.** The rows sit in two columns, The floor and House rules,
  that fold away to a line of what they're set to, and four presets set the house rules in one press.
- **A random arena.** Pressing Quick match, or a preset in one, deals a different arena each time;
  pick one from the Arena row to choose it yourself.
- **The respawn pick leans toward your hand.** Half the time one card comes from the suit you hold
  most of, and bots now build their hands by suit too.
- **Curses go first.** On a death a cursed joker's terms apply before the rest, so Insurance Policy
  always banks your pot under High Roller.
- **Lucky Seven, Backfire and Odometer reach further.** Lucky Seven counts a gold chip as five,
  Backfire also aims back while you drift, and Odometer counts nitro meters twice.
- **Pencil tire marks look drawn.** Kit's pencil marks are scribbled in dark graphite now, back and
  forth with its grain, rather than a pale gray ribbon that read as a dashed line.
- **Me, for your tab.** The settings' first tab is called Me until the story names you, and with
  the story off.
- **The Garage dresses karts on its lift.** Its seven stalls are gone; the lobby keeps its own for
  a quick change between matches.
- **A quieter Garage.** The labels floating over its Junction, Jackpot, jokers and dummies are gone,
  and the lift has its name painted on its floor.
- **A new Garage floor.** The middle is open, with two rings painted round the Junction to drift
  round, and the rest is tidied round the walls: a range of targets, the dummies in numbered bays
  they come back to, and a pit with the crates.
- **A lived-in Garage.** Cones to knock round its rings, slot machines on the rail in for repair,
  a stopped clock, a pegboard of tools, and a kart on jack stands, a compressor and a soda machine
  round the room.
- **Finer confetti.** The confetti trail is smaller and thinner, in a few shades of your color.
- **Scattered pencil.** Kit's pencil trail leaves its scribbles lying every which way.
- **The slip's countdown in its button.** A watcher's slip that is about to turn the page fills a
  bar along the arrow down, or along Continue, rather than a small ring off to the side.

### Fixed

- **Kit's rag.** The flag's torn corner no longer cuts through the rag.
- **Rumble only where you drive.** Playing alone on the keyboard no longer shakes a pad lying on
  the table: only the pad you drive with is knocked.

## [0.16.0] - 2026-10-14

Play in teams, earn forty-seven achievements and settle a tied Grand Prix in a showdown, with the
loyalty program now a road atlas and the catalog a press proof. It doesn't play with 0.15.x.

### Added

- **Teams.** Play a match in two to four teams, the suits of a deck, whose karts bank one score
  and win together, with friendly fire yours to switch on. Pick a side in the lobby by stopping on
  your team's corner, or from your switch.
- **Achievements.** Forty-seven things worth doing once, from a kill off two walls to a lap of the
  roundabout, each struck on a commemorative chip, listed from the Clubhouse and tossed into the
  corner as you earn them, where a click opens it in the list. A seat linked to a profile earns its
  own, and the story keeps a few hidden.
- **A showdown for a tie.** A Grand Prix that ends with karts level on points settles it on a small
  map of their own: no respawns, no chips, the same three jokers each, and the last one standing
  wins. The Tie-breaker switch in the Grand Prix's settings turns it off, and the map is a quick
  match of its own as well.
- **Ties explained.** A line level with another on the payout slip or the run's standings says what
  put it ahead: the kills, the maps won, what was banked, or the showdown.

### Changed

- **The loyalty program as a road atlas.** The program's map lies on the cover of the House's road
  atlas, its details on a spiral-bound pad whose pages turn as you go, a landmark not open yet on
  a blueprint, and Kit's on a scrap of his graph paper. The words in the cover's foot, and on the achievements' table, change as the story
  goes on.
- **A quicker map on a pad.** A pad's triggers zoom the loyalty map and its right stick moves it
  faster than before.
- **The catalog as a press proof.** The catalog's cards lie on the House's proof sheet on a cutting
  mat, the ones you have not taken yet only their die lines and your first ringed in grease pencil.
  The motto in the sheet's foot changes as the story goes on.
- **A lighter catalog.** The catalog draws each card, tag and chip once and shows it from then on,
  so it costs a twentieth of what it did to have up. The loyalty program costs about half.
- **A clearer note mark.** While one of Kit's notes lies in the map, the scrap beside the clock
  wears a magnifying glass, until the note is taken and ticked off.
- **Full screen on a phone.** On a small screen the loyalty program and the catalog fill the screen,
  giving the map and the cards more room.
- **The loyalty map to the edge.** The map runs right to the edge of its sunken panel, shaded all
  round, and the details beside it take less room. Zoomed all the way out, a little room is left
  round the map, and zoomed in it can be dragged a little past its edge.

- **The Final Hand's seal on the title.** The flyer by Play while the Final Hand is due wears the seal
  from the top of its invitation, not the game's logo.

- **Your card back on show.** A card back won in the loyalty program is worn by the cards lying face
  down in every room and the decks round the table. Cards in your back drift up the title, a hand
  of them ripples on the loading screen, and a joker leaving your hand turns over to it.

- **A full sky clicks.** With your bullets already in the air the trigger no longer takes the oldest
  one out; it clicks dry with a puff of smoke at the muzzle until one is gone, as before.

- **Keep nothing.** Choosing which joker to keep for the next map of a Grand Prix can be skipped, to
  start the map with an empty hand.

- **The same keys in every dialog.** The loyalty program, the catalog and the achievements share
  their keys: Q and E or the shoulders turn pages, Tab or Y changes the view, F or X is the second
  option, and WASD moves the cursor too. Q and E turn the settings' tabs as well, and the page keys
  stand right beside the tabs everywhere.
- **Awards worth having.** An award on the payout slip is only given for doing enough of a thing to
  be worth saying, such as two flushes or a x6 multiplier, and the winner is dealt theirs first.
- **Smarter bots.** Bots shoot out of the back with Backfire, take shots off the walls with bouncing
  bullets, and duck behind cover in a showdown when they are losing.
- **Jokers keep count.** The catalog says how many times a joker went off for you, such as the tolls
  Toll Booth collected or the pockets Pickpocket picked.

- **Miles an hour.** The speedometer can read in mph, chosen under Speed in the settings. Until you
  choose, it follows your system's region, and stays in km/h where that cannot be told.
- **A livelier speedometer.** The dial has a pointer that swings onto your speed, a mark that holds
  your top speed for a moment, and a track that shows where only nitro takes you.

- **A Clubhouse in the pause menu.** The pause menu's loyalty program button is now a Clubhouse with
  the loyalty program, the catalog and the achievements in it.
- **Gentler music at the top heat.** The music swells by about half as much at the hottest by
  default, and the Intense music slider now runs up to twice as loud.
- **Your tab in the settings.** The License tab is named for what the House calls you, Guest to
  start with, and changes as the story goes on.

### Fixed

- **Steadier karts online.** After a bump, the host goes back to following your kart at once
  instead of holding it back until the correction has eased in.
- **Fewer ways to cheat online.** The host refuses a kart claimed through a wall, a team changed
  mid-match, and messages a modified client sends too long or too fast, showing that client out.
- **Safer saves.** Settings and profiles are written whole before they replace the old file, which
  is kept as a backup. A file damaged by a crash is read from the backup instead of being reset.
- **The catalog's tabs under the cursor.** A tab with the cursor on it is ruled round in gold, so it
  can be seen there.
- **The driving school on a small screen.** Its pages fit the screen at a big UI scale, shrinking
  to fit rather than running off the bottom.
- **Emotes at the finish.** Emotes work past the whistle again, and pop up over the karts on the
  podium of the photo finish.
- **Kit's torn sheet.** The top of Kit's map is torn along its own edge, without a straight dark
  band over it.
- **The catalog's rows.** Holding left or right along the catalog's cards stops at the row's end
  instead of jumping to the tabs.
- **Sharper notes.** Kit's notes taken out for a closer look are drawn at your screen's own
  resolution, no longer blurred at a big UI scale or on a large screen.
- **The loyalty map follows your pick.** Choosing the Jackpot, or leaving it, no longer leaves the
  map looking at where you set off from, most of all at a big UI scale.
- **The loyalty card under a long slip.** With the Jackpot's long details up, the program's card is
  put away, instead of sliding out of sight while its photo corners and its key stayed behind.

## [0.15.3] - 2026-10-12

A new loyalty map with the Jackpot on its island over the districts, and a camera that keeps the HUD
off your kart. It plays with 0.15.0 to 0.15.2.

### Changed

- **A new loyalty map.** The Jackpot sits on its island over the districts and the slip road just
  under them, a road into each; past its first landmark, every bet on the way to a keystone can be
  gone round.
- **A loyalty map with character.** Landmarks stand on curving, uneven streets in built-up districts
  with a fountain and a test track, and a river runs out of the Jackpot's moat down between them
  through two lakes, among woods, farms and named places.
- **A picture for every landmark.** Each loyalty landmark's sign shows a picture of the place itself,
  so no two look alike.
- **Clearer wins on the loyalty map.** A won Strip landmark wears a gold seal with red ribbons and
  glows; Kit's are ticked and circled in pencil.
- **Progress on a ticket.** An open landmark's bet hangs from its sign on a ticket, a little gold road
  showing how far it has come.
- **The compass by the legend.** The loyalty map's compass stands beside the legend, out of the way.
- **Marquee lights.** The bulbs of the Strip sign you have selected chase round it, once it is open.
- **Kit's way in.** Kit's map has a back road onto it, leading to his first landmark.
- **The blueprint.** Kit's blueprint note is drawn as the loyalty map is now laid out, the Jackpot
  on its island over the districts.
- **See where you are going.** The camera keeps the floor a moment ahead of each kart you drive on
  screen and out from under the HUD, and gives fast karts room before they reach a panel.
- **A lighter camera.** Keeping karts clear of the HUD costs a fraction of what it did, for phones,
  and the clearance overlay is drawn once and moved rather than drawn every frame.
- **A smaller Skip.** Skipping a joker pick is a small framed chip at the end of the pick's hints,
  not a big button.
- **The joker pick stays off your hand.** Alone, your hand tucks into the bottom edge under the
  pick; sharing a screen, the pick shrinks to keep its pane beside its cards.
- **The HUD keeps off the karts.** The camera goes back or slides its aim to keep karts out from
  under a player's corner, the standings, the clock and the hands of jokers, at every UI scale.
- **A shared screen's joker pick lies low.** With more than one player on a screen, a joker pick is
  a strip along the foot of its owner's share, in place of their hand, out of the others' way.
- **Smaller standings.** The list down the right is shorter and narrower.
- **Match settings start at the top.** The cursor starts on the first setting, not on Done; Escape
  or a pad's B is Done, and the Done button shows it.
- **A plainer selection on the loyalty map.** The landmark you have selected wears a gold edge with
  chevrons, cased in ink, and lifts off the paper, so it shows on the Strip's gold signs too. The
  roundabout's ring is drawn the same.
- **A plainer closed bet.** A closed landmark says its bet is hidden until it is unlocked.
- **Go any way on the loyalty map.** The arrows or a stick go to the nearest landmark that way even
  where no road leads there, unless it lies far more to one side.
- **The cursor stays on the map.** In the loyalty program the card no longer takes the cursor; E or
  a pad's X shows it in full, its bind drawn on its corner, and a click still does.
- **A pin on the Pin button.** The loyalty program's Pin button carries a map pin.
- **Addressed to you.** The very first invitation's envelope is addressed simply to you.

### Added

- **A hand over a landmark.** On the loyalty map the mouse turns into a pointing hand over anything a
  click chooses.
- **Read your hand during a joker pick.** Hold Tab or a pad's Y to look at the jokers you
  already hold; the pick steps aside until you let go.
- **See what the camera keeps clear.** A Debug page switch, or `--show-clearance`, draws the HUD's
  panels and each kart's clearance over a match.
- **Hold to keep moving on a pad.** In the menus, holding the stick or the D-pad moves once, then after a
  moment keeps moving quickly, as a held key does.
- **A word on the loyalty program.** When the loyalty program first opens after you activate its
  card, a short note says what it is: your objectives, what counts toward them, and pinning one.
- **No countdown for automation.** `--no-countdown` starts every map at once, for scripts and
  screenshots that would otherwise wait out the lamps.

### Fixed

- **Quick turns on the loyalty map.** Choosing back and forth faster than the kart drives no longer
  freezes the choice until it gets where it was going.
- **The Jackpot in view.** Clicking the Jackpot on the loyalty map brings it into view, rather than
  where the kart set off from.
- **Closed keystones.** A locked keystone's star is as pale as its sign, and the landmarks next to a
  keystone no longer say it would open them.
- **The loyalty map's tabs.** They stand clear of the map's cut corner.
- **The loyalty program at 200%.** Its key hints no longer push the dialog off the screen; the ones
  that don't fit are left out, and the subtitle stands beside the title where there is room.
- **Turning back on the loyalty map.** Sending the kart back the way it came just after it set off
  no longer raises an error; it turns round and stops before the sign it left.
- **The loyalty card on a short screen.** Where the loyalty program leaves its card out, at a big UI
  scale say, the card drops away rather than flying to a place that isn't there.
- **A pad unplugged under the menu.** A player whose gamepad disconnects while the room's menu is
  up no longer stops the game; their switch over their corner goes with them.

## [0.15.2] - 2026-10-11

Two fixes: the photo finish's curtains on a phone, and a new color in the standings. It plays with
0.15.0 and 0.15.1.

### Fixed

- **A new color in the standings.** A player who changes color mid-match has their strip in the
  standings edged in the new one at once, not only its chip and name.
- **Curtains on a phone.** The photo finish's curtains fill the picture on a phone, or at any UI
  scale over 100%; they stood smaller in its top left corner.

## [0.15.1] - 2026-10-11

Auto throttle for simple driving, harder keystones, a dressed-up photo finish and a lot of polish
for pads and phones across the loyalty program, the payout slip and the settings. It plays with
0.15.0.

### Added

- **Auto throttle.** Simple driving on a pad or a touch screen now leaves the gas and brake to you,
  the stick only steering while held, so aiming at a standstill is easy; switch Auto throttle on to
  have it drive for you as before. The keyboard always drives for you.
- **Aim guide settings.** Accessibility sets the aim guide's length, dot size, opacity and color,
  with a Reset beside them and your kart under the switch showing the guide as it is set.

### Changed

- **A tidier License page.** The settings' License page is headed with whose license it is, and
  lays the plate, the driving school, the loyalty program, the catalog and the story out in titled
  sections, with a way to the program's map beside the catalog's.
- **Seats and Profiles centered.** The Seats and Profiles pages of the settings are laid down the
  middle under a heading, as the License, Statistics and About pages are.
- **A met pin says so.** Once you meet a pinned bet in a map, its count by the clock and in the
  room's menu turns green with a tick.
- **Pin from the slip.** The bets you came nearest to on the payout slip have a pin, so you can pin
  one there and then.
- **Rewards by name on the slip.** Each bet won on the payout slip's loyalty page says what it paid,
  not only that a reward was issued.
- **A photo finish with a stage.** The slip's photo finish is taken on a stage between velvet
  curtains, the casino's lights twinkling far behind, two soft spotlights on the winner.
- **Grand Prix standings without a photo.** The slip's Grand Prix standings page leaves the photo
  finish to the map's page; the run ends on its own podium.
- **Harder keystones.** The Grand Salon asks for three Grand Prix won, and the Showroom for three
  maps won in a row, one in each of the three rooms.
- **Swipe between notes.** On a touch screen, a note taken out for a closer look can be swiped
  to the one beside it, as well as stepped to with the arrows.
- **The loyalty map on a pad.** The triggers zoom the map smoothly for as long as they are held,
  and the right stick moves it about.
- **Quieter oil.** Spinning out on an oil stain is a good deal quieter.
- **Bots marked.** In the standings on the right and on the payout slip, a bot has a little robot's
  head after its name.
- **Sparks that look like sparks.** The sparks trail throws hot streaks that arc down and cool
  from white to your color.
- **Bigger horns.** The horns hat is bigger, curls up at the tips, and comes in your color.
- **Poker chips that look like chips.** The poker chips trail throws real chips, notched round the
  rim, tossed up and flipping over before they fall, rather than discs that looked like confetti.
- **Driving between the maps.** On the loyalty map, a road that runs on to the other map brings the
  kart driving in over its edge, rather than setting it down at the landmark.
- **The drive hint once.** The drive and fire hint over your kart shows once for each player, in
  the first room they play, rather than at every map; Always show drive hints in Accessibility
  brings it back.
- **Two loyalty bets, harder.** One now asks for a map won without ever taking a joker rather than
  with an empty hand at the end, and another for a full hand of jokers dropped in one map, not three.
- **NEW on the catalog's tabs.** A catalog tab wears NEW while a card on its page is new, so you
  see there is something on the other page.
- **The Showroom on film.** The Showroom's panel shows the bay itself, your kart on the turntable,
  through a camera that cuts between moving shots like a car advert.
- **Readable small print.** The fine print along the foot of each player's corner is a little
  larger, and larger again on a phone, where it could not be read at all.
- **Extras is the Clubhouse.** The title's Extras button is now the Clubhouse, home to the loyalty
  program and the catalog, and it lists the Catalog above the Garage.
- **Guardian Angel's items marked.** While you hold Guardian Angel, a Shield or Bullet Wipe it will
  spend for you wears its halo, beside your kart as you pick it up and in your corner.

### Fixed

- **Solid black marker.** Lines blacked out in marker are solid black, without the gray streaks
  that ran through them.
- **WON stamps closed.** The WON stamp on the loyalty map and the payout slip has a whole ring; the
  gap in it looked like a mistake.
- **Karts on the ground.** Karts stood a little above the floor; their wheels are on it now, which
  shows most in the Showroom.
- **Flags that fly.** The windsock rises and falls smoothly with your speed instead of jittering,
  the tape measure's tape winds in when you stop, and the fuzzy dice swing back, forward and out
  as you speed up, brake and turn.
- **The Jackpot's ring stands out.** On the loyalty map the ring round the Jackpot stands a little
  further out, edged in ink, so it no longer disappears into the gold roads.
- **Readable stall names.** On a dressing stall a card over your kart names what it wears and,
  smaller, what the fire button puts on next, so going through them quickly no longer piles the
  names on top of each other.
- **The Showroom's turntable carries the kart.** A kart standing anywhere on the turntable rides
  round with it, rather than turning on the spot while the disc goes round under it.
- **Cards turn over smoothly.** The license, a note or the loyalty card turned over while tilted
  comes to rest where the turn leaves it, rather than jumping to a new tilt.
- **Five-figure scores.** A banked score of five figures or more is set a little smaller in your
  corner rather than losing its last figures off the edge.
- **Activate card in the clear.** The loyalty letter is a little smaller and higher, so its corner
  no longer comes over the Activate card button under it.
- **Scroll the payout slip with a finger.** A finger dragged anywhere on the slip scrolls it, and a
  swipe carries it on a little; before, it only scrolled from the few spots between the lines.
- **The slip's arrows on a phone.** On a touch screen the arrows beside the payout slip are there
  whenever it runs off the screen, and step down it a screen at a time.
- **More of the slip on a small screen.** On a short screen the payout slip's lines are compact and
  its podium smaller, so three or four players fit where two did.
- **Swipe through the catalog.** On a touch screen a swipe scrolls the catalog's cards and only a
  tap picks one; before, touching a card to scroll picked it.
- **The Grand Prix in the menu.** In a map of a Grand Prix the foot of the room's menu says which
  map of how many it is and how the run is played.
- **The Driving School under the Clubhouse once licensed.** With your license earned, the Driving
  School moves off the title's own buttons into the Clubhouse.
- **Fire on the menu's controls card.** The card beside a player's switch in the room's menu shows
  the fire button as well as how to drive.
- **The menu fits a phone.** Where the room's menu is taller than the screen, as a host's is on a
  phone, its buttons scroll under the heading, staying as big as ever.
- **Pin from the slip on a pad.** The pins by the nearest bets on the payout slip take the cursor,
  up from the buttons under the slip.
- **Scroll the slip with a pad.** A pad's right stick scrolls the payout slip smoothly.
- **No pinned bet over the slip.** The pinned bet by the clock steps aside while the payout slip
  is up.
- **The pinned note on a pad.** In the pause menu, the cursor goes down to the pinned bet's note,
  and pressing it opens the loyalty program there, as a click does.
- **Settings follow the cursor.** Moving the cursor past the foot of a settings page, as on a pad,
  scrolls the page along instead of leaving the selection out of sight.
- **The License page's cursor.** On a pad or the keyboard, up and down on the License page go to
  the row over or under, no longer sideways to the section beside.
- **Matched spotlights.** The two spotlights on the opening invitation and the loyalty welcome
  fade out evenly at their edges; one beam's edge was softer than the other's.
- **No pinned bet over a phone's arena.** On a touch screen the pinned bet hangs by the clock only
  where it fits beside it; under the clock it covered the arena, and the pause menu shows it, live.

## [0.15.0] - 2026-10-09

The House signs you up to its loyalty program, a road map of bets whose rewards are new jokers,
power-ups and dress for your kart, with Kit's own map beside it. It doesn't play with 0.14.x.

### Added

- **A loyalty program.** After your first map the House signs you up to its loyalty program, a road
  map of bets whose rewards are new jokers, power-ups and dress for your kart, opened from the title
  and the pause menu.
- **Bets won as they happen.** A bet met in a match is stamped there and then, and the results have
  a page for what the program paid and what came nearer.
- **Lost Property.** Four things lost in the rooms turn up on their floors once their bets are open,
  with a tag by the clock while one lies in the map; drive over it to claim it.
- **Kit's map.** Kit keeps a map of his own bets off the books, in pencil on graph paper, and three
  more of his notes come from them, kept in the back of the folder.
- **The Showroom.** Winning its keystone opens a bay behind the Garage with a turntable that shows
  your kart from all round.
- **The roundabout and editions.** Past both keystones a ring of seven bets pays an edition each lap,
  giving a piece of dress you have won a Foil, Holographic or Polychrome finish.
- **Pin a bet.** Pin a bet of the loyalty program to see how far it has come on a note under the
  pause menu and, on a wide screen, by the match's clock.

### Changed

- **Panes come up once they are drawn.** A big pane, such as the loyalty program's, now slides in
  rather than just being there, and the Catalog button wears NEW while a card in it is unseen.
- **A smooth loyalty map.** The map is drawn once and moved, so scrolling it and the kart driving on
  it keep the frame rate up.

### Fixed

- **Pinch a note closer on a phone.** Two fingers now pinch a note in Kit's folder closer and
  further on Android, where the pinch did nothing.

## [0.14.2] - 2026-10-08

The invitation that brought you to Jackpot Junction, waiting on the table the first time you start,
and a calmer lobby, catalog and touch screen. It plays with 0.14.0 and 0.14.1.

### Added

- **An invitation.** The first time a profile comes to the title, the invitation that brought it
  to Jackpot Junction is waiting on the table, and it is kept with Kit's notes once accepted.
- **Something to find in a Grand Prix too.** What turns up on the tables after your license can
  turn up in a map of a Grand Prix as well as in a quick match.
- **Something to find, by the clock.** When there is something of yours lying in a map, a small
  scrap of paper hangs beside the clock, ticked off in red pen once you pick it up.

### Changed

- **Extras on the title.** The Garage and the Catalog share one button on the title, Extras, which
  keeps the menu short enough for a phone.
- **The catalog from the settings.** The License page has a Catalog button, so the catalog can be
  opened from a match's pause menu too.
- **Gold that catches the light.** A card the House holds up turns toward the mouse, its gold
  catching the light as it does, and a stub torn off tears along its holes rather than all at once.
- **Settings start on the page.** The settings open with the cursor on the page, on your license
  first, rather than on Back.
- **Your license, picked like a button.** On the License page your license lights up under the
  cursor or the mouse and opens as it does on the title, and Kit's folder stands beside it once
  you have found a note.
- **An empty catalog says how to unlock it.** A catalog page with nothing found yet says how to
  unlock it, rather than showing a count of none and a page of face-down cards.
- **The catalog on a phone.** On a small screen the catalog's title moves to the top left and Back
  to the top right, as in the settings, leaving more room for the cards.
- **A roomier catalog.** Its cards are one size on both pages, in a sunken well that scrolls, with
  more room round the description and the gamepad's buttons beside the tabs.
- **Detailed in the catalog.** A switch under a joker's description shows how far it stacks, as
  holding the details key does in a match.
- **Stacks in the catalog.** A joker can be read as a stack of any size it reaches, beside the
  biggest you have held of it, and the selected card is shown large where there is room.
- **The catalog's cards stay still.** The card under the cursor wears the gold frame a button does,
  sliding from card to card, rather than lifting out of the page.
- **Power-ups count once used.** A power-up shows in the catalog once you have used one, rather
  than as soon as you picked it up; pickups counted before are dropped.
- **A bigger seal on About.** The game's mark on the settings' About page is larger.
- **Hold an arrow through Kit's notes.** A held arrow key steps from note to note in a closer look,
  as it already turns the folder's pages.
- **The magnifying glass finds the new note.** In Kit's folder the magnifying glass carries the
  pencil mark while a new note is open, and takes that note out.
- **Tidier stamps.** The stars on the PASSED, APPROVED and WINNER stamps sit in the gaps of the
  ring, and a small stamp is the big one scaled down, its words inside the ring.
- **Linen you can see.** The joker cards' linen is a crisp weave of crossing threads that shows on
  their dark face, even on a card drawn small.
- **Kick and Make host ask first.** In Manage players, kicking somebody or making them the host
  asks you to confirm, so a stray press no longer does it.
- **Backing out sounds the same everywhere.** Escape or B out of the settings, the menu, a dialog
  or a question gives the small buzz the title and the catalog already gave.
- **A quiet kart under the lobby's menus.** While a menu or a question is up in the lobby, your
  kart stays put and goes quiet instead of driving and revving on the keys that work the menu.

### Fixed

- **The license lifts off where it lies.** Shown in full, the license now rises from the card and
  goes back onto it exactly, rather than from a little up and to the left of it.
- **The cursor after the license.** Put away, the license has the cursor on it again, so the
  arrow keys carry on from there rather than doing nothing.
- **Tapping through Kit's notes.** On a touch screen, tapping the arrow onto the last note no
  longer puts the note back in the folder.
- **The final exam's second kart.** It comes out once you hold 300, in the bank and the pot
  together, so it still turns up for a driver who never banks.
- **Touch controls over the driving test's list.** On a touch screen the checklist hangs higher,
  with the menu button and the buttons on the right drawn over it rather than under it.

## [0.14.1] - 2026-10-07

A catalog of every joker and power-up you have taken, robot names for the bots and a calmer title.
It plays with 0.14.0.

### Added

- **A catalog of every joker and power-up taken.** Catalog on the title shows each one your profile
  ever took, the rest face down, with what it does and the numbers a match never shows, such as how
  long an item lasts.
- **A Mac icon of its own.** On macOS the game's icon is a rounded plate of the house's stock with
  the seal on it, drawn the way Mac icons are.
- **Robot names for bots.** Bots go by names of their own, robot slang like Clanker, Rusty, Tin
  Can and Droid, which no player is ever handed.
- **The title opens with the logo.** The first time the title comes up, the logo flies up from
  the middle of the screen into its place and the rest of the screen comes in around it. Any
  key, button, click or tap skips it.

### Changed

- **A crown for the bounty.** The standings mark the player with the bounty with a crown, the one
  their kart wears, rather than a dollar sign.
- **Your rows glow in your color.** In the standings, a player on your screen has a short wash of
  their color fading in from both ends of their row.
- **A vignette behind a closer look.** The license, Kit's folder and a note are shown over a shade
  that darkens toward the edges of the screen, rather than a flat one.
- **Menu, not Paused, while others play.** Online the pause menu is headed Menu, since the match
  goes on until everybody has theirs open, and Paused once it has stopped.
- **The cursor's glide in ink on paper.** On the payout slip the frame that slides with the
  cursor is black, like the slip's own buttons, rather than gold on the cream.
- **A calmer, lighter title screen.** The sunburst turns slower and fades out well before the sides
  of the screen, and the chips drifting up are the house's chips, slower and kept out at the edges.
  Nothing on it is drawn again every frame any more, which a phone's battery will notice.
- **More room in the settings.** The title and Back share the top of the screen so the page gets
  the rest, and the gamepad's tab buttons sit beside the tabs only while a gamepad is plugged in.
- **The payout slip is one long bill.** A Grand Prix's standings are printed under the map's
  results and scrolled down to; the arrows on its edge, up and down, or the shoulders turn its
  pages.

### Fixed

- **No stutter at the first closer look.** The license, Kit's folder and a note held up to the
  eye are ready behind the title, rather than compiling their look the first time.
- **Quieter wall crashes.** Driving into a wall is a lot less loud; a hard hit is still a bang, but
  no longer the loudest thing in a match.
- **A steady emote wheel.** The wheel over your kart follows it smoothly while you drive instead of
  jumping about.
- **No gap before the names on the Grand Prix standings.** When nobody's place changed, the
  standings no longer leave room for an arrow before every name.
- **No gold glide onto what can't be pressed.** The frame that slides with the cursor skips
  disabled buttons, such as the match settings locked for the Final Hand.

## [0.14.0] - 2026-10-07

Online rooms hold up to eight players, and the tables have more to say in the small print. It
doesn't play with 0.13.x.

### Added

- **Up to eight players online.** A host can set the player limit up to 8, still 4 to start
  with, and add up to 7 bots; one device still seats 4. Every map has four more spawn points,
  shown only when more than four karts play.
- **A roof marker for every color.** The seventh and eighth colors get their own marker shapes, a
  cone and a diamond, and a kart's marker now goes with its color.
- **Big rooms play the XL maps.** With more than four karts a normal map plays as its XL, unless
  you turn on Small maps for 5+ karts in the match settings.
- **The tables have more to say, in the small print.** Keep playing once you have your license,
  and read what the house prints. Story, on the License tab of the settings, turns it off.

### Changed

- **Bots drive differently from each other.** Every way of driving comes round once before any
  repeats, so three bots are three different ones.
- **Lighter online updates.** Names, statistics and kart dress are sent twice a second instead of
  with every update, so updates are about a fifth smaller.

### Fixed

- **Every player counts while a map waits.** "Waiting on" before a map counts each player at a
  machine, not one per machine.
- **The driving school's flyer holds still with Reduce flashing on.** Its headline no longer
  blinks.

## [0.13.4] - 2026-10-06

The game has a look of its own, House Print: menus, panes and the HUD are cut like tickets from
dark card with gold foil, under a new logo. It plays with 0.13.x.

### Changed

- **A look of its own.** Menus, buttons, boxes, lists, tabs, switches and sliders are cut like
  tickets from dark card with gold foil and fine engraved lines, the way the driver license is,
  and everything is set in Barlow, a face drawn after road signs and license plates.
- **A new logo.** The game's mark is an engraved gold seal with fine print round it and the
  crossroads chip in its middle; drawn small, it is the chip alone. On Android it fits whatever
  shape the launcher gives icons, tinted ones too.
- **A surface to everything.** Panes, buttons and the HUD are laminated card with fine scratches
  under a soft light, gold is brushed foil, the menus sit on felt, the payout slip is paper, joker
  cards have a linen finish and chips show their clay.
- **Panes torn like tickets.** The pause menu, questions, dialogs and the joker pane have a header
  torn off by a perforation, and the button that moves on is gold. A question that loses you
  something carries a yellow warning sign.
- **A payout slip.** The podium is a cream slip torn off the house's printer, with the podium as a
  photo finish, a receipt line per player, a red WINNER stamp and buttons printed in ink on a
  tear-off stub; on a phone its lines scroll, shaded at an edge with more past it.
- **Calls on plates.** The announcer's calls stand on a plate in the player's color, each kind
  dressed in its own way, a hand of cards, flames, chevrons, a checkered flag or hazard tape; Last
  Call lights up in neon, and the joker cards are engraved in their kind's color.
- **A title with a seal.** Rings turn slowly round the mark on the title, the name is set in a
  heavier cut over a line of fine print, and the touch controls are chips in your own color.
- **Menus that move.** Panes slide up as they open and drop away as they close, and a gold frame
  follows the cursor from one button to the next; Accessibility can switch the frame's glide off.
- **Hints over your kart.** The hints and the item beside your kart stand on small tickets, the
  words that float up off a kart are set in the HUD's own type, and emotes are chips in your color.
- **Printed plates.** License plates are printed on cream with an ink frame, bolts and the
  department's name over the letters.
- **One list of people.** Profiles, the seats at your screen and everybody in a game you host are
  the same row: a chip in their color, their name, their plate and what you can do with them. The
  Players tab in Settings is called Seats, and deleting a profile asks first.
- **Key bindings in sockets.** The Controls page shows each binding's keys and buttons at their own
  size in a sunken socket, and asks for a new one in gold.
- **A dashboard in your corner.** Your corner of the HUD runs off the edge of the screen with a
  speed dial, nitro cells and a pot that ends in a chip and a die; the clock hangs on an amber
  board like the one by the table, and the standings and kill feed are strips off the right edge,
  your own lines striped in your color.

## [0.13.3] - 2026-10-06

Dedicated servers can ask for a password, and your list of servers shows their own names. It plays
with 0.13.x.

### Added

- **A password for your server.** Start a dedicated server with `--password` or `JJ_PASSWORD` and
  Play Online asks for it before showing its games; its games turn away anybody without it.

### Changed

- **A tidier title screen.** The credits along its bottom are gone; who made the music, the models
  and the sounds is in Settings, About.
- **Grand Prix points on the standings.** A map's podium in a Grand Prix shows just the awards;
  the standings after it show what the map paid each player, beside their total.

### Fixed

- **Inspectors' hair.** The top of an inspector's head no longer shows through their hair in
  the driving test.
- **See your server's name.** Once you have connected to a server, Play Online's list shows the
  name it gives itself, and its games' lobbies say which server they are on; before, only the title
  over its games did.

## [0.13.2] - 2026-10-05

Games and dedicated servers can have names, and your servers drag into order. It plays with
0.13.x.

### Added

- **Name your game.** Lobby settings has a Game name, and the lists of games show it over a line
  saying whether it is in the lobby or which map it is on, and how many play; unnamed, it is
  still "Ann's game".
- **Name your server.** A dedicated server takes a name with `--name` or `JJ_NAME`, shown over its
  games in Play Online.

### Changed

- **Drag your servers into order.** Each server in Play Online has a grip of dots to drag it up or
  down the list with a mouse or a finger; with a pad, press A on the grip, move the server with up
  and down, and press A or B to put it down.

## [0.13.1] - 2026-10-05

Your profile keeps your favorite color, and everything you play now counts in its statistics. It
plays with 0.13.0.

### Added

- **Arrange and edit your servers.** Each server in Play Online has arrows to move it up and down
  the list and a pencil to change its name, address or port.
- **Your favorite color.** The color you pick in the pause menu or from the row of colors on the
  Players page is kept in your profile, and you get it in every game where it's free, on your
  license's kart too, and on a seat linked to your profile.

### Changed

- **A clearer tap icon.** Hints on a phone show a proper tapping hand.
- **Shader compiling in plain sight.** The first start of a version shows a "Preparing" pane over
  the title with its progress and a Skip button, rather than a small line in the corner.
- **See which profile a seat is.** A linked seat shows the profile's name and plate on its pause
  menu panel, and the Players page says "Linked to" it.
- **The item button in touch hints.** A hint on a phone shows the item button with your item's
  picture on it, as the button looks, rather than the word ITEM.
- **Hold an emote to send it on a pad.** Hold the right stick on an emote until its ring fills, a
  quarter of a second, then let go; the stick snapping back no longer sends the one on the other side.
- **Everything you play counts.** What you do in the driving school, in the lobby and in a match
  left early, cut off online or got up from mid-map now adds to your statistics, linked seats' too.
- **Karts on show face you.** The kart in the license photo and on the podium starts turned toward
  the camera rather than away from it.
- **An easier final exam.** The driving test ends against two easy bots; the third, harder one is
  gone.

### Fixed

- **Leave while connecting.** Pressing Escape while a game is still connecting now opens the
  pause menu over the "Connecting" pane, so you can disconnect.
- **A retake earns endorsements.** Passing the driving test again puts what you earned that time on
  your license; before, it kept only the first pass's.
- **The license screen fits a phone.** The card comes first, then the plate and the ways on in its
  place, and each shrinks to fit rather than scrolling behind it.
- **Your new license, up close.** Once you stamp it, the license is shown in full, as on the title;
  put it away to choose your plate and where to go.
- **No more spaces in a server address on a phone.** Address boxes use the phone's keyboard for
  addresses, which stopped adding a space after each dot, and port boxes the number keyboard.
- **No freeze making a profile in a game.** Profiles are only listed in the settings inside a game;
  make, edit, switch and delete them from the title screen.
- **Gold tracks you can see.** The trail of a kart one cash-out from winning is bright now; it was
  too faint to notice, above all on the driving school's floor.
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

[Unreleased]: https://github.com/timvisee/jackpot-junction/compare/v0.19.0...HEAD
[0.19.0]: https://github.com/timvisee/jackpot-junction/releases/tag/v0.19.0
[0.18.0]: https://github.com/timvisee/jackpot-junction/releases/tag/v0.18.0
[0.17.0]: https://github.com/timvisee/jackpot-junction/releases/tag/v0.17.0
[0.16.0]: https://github.com/timvisee/jackpot-junction/releases/tag/v0.16.0
[0.15.3]: https://github.com/timvisee/jackpot-junction/releases/tag/v0.15.3
[0.15.2]: https://github.com/timvisee/jackpot-junction/releases/tag/v0.15.2
[0.15.1]: https://github.com/timvisee/jackpot-junction/releases/tag/v0.15.1
[0.15.0]: https://github.com/timvisee/jackpot-junction/releases/tag/v0.15.0
[0.14.2]: https://github.com/timvisee/jackpot-junction/releases/tag/v0.14.2
[0.14.1]: https://github.com/timvisee/jackpot-junction/releases/tag/v0.14.1
[0.14.0]: https://github.com/timvisee/jackpot-junction/releases/tag/v0.14.0
[0.13.4]: https://github.com/timvisee/jackpot-junction/releases/tag/v0.13.4
[0.13.3]: https://github.com/timvisee/jackpot-junction/releases/tag/v0.13.3
[0.13.2]: https://github.com/timvisee/jackpot-junction/releases/tag/v0.13.2
[0.13.1]: https://github.com/timvisee/jackpot-junction/releases/tag/v0.13.1
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
