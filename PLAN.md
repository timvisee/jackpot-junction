# Implementation plan

GAME.md is the design and the source of truth for rules and numbers. This file
is the order of work: what gets built when, in which files, and how each step
is verified. Tick tasks off as they land. When implementation forces a design
change, change GAME.md first, then the code.

## Environment

| Item             | State                                                                                     |
|------------------|-------------------------------------------------------------------------------------------|
| Godot            | 4.7.2 stable via Steam: `~/.local/share/Steam/steamapps/common/Godot Engine/godot.x11.opt.tools.64`. Runs headless. `~/bin/godot` is 4.4.1 and must not touch this project |
| Export templates | The Steam Godot ships its own under `editor_data/export_templates`, so `make export` works locally; the release workflow downloads the official 4.7.2 templates |
| gdUnit4          | Not installed. Add to `addons/` in phase 0, pinned to a release that supports 4.7        |
| gdtoolkit        | Not installed. `pipx install gdtoolkit` for `gdlint` and `gdformat`                       |
| CI               | GitHub Actions, repo `timvisee/jackpot-junction`, branch `master`                         |
| Display          | A local display is available. Windowed runs from the agent sandbox render at about 1 frame per second, so screenshots use few frames: `tools/godot --path . --disable-vsync res://scenes/dev/playground.tscn ++ --screenshot=<png> --frames=8`. Handling feel still needs a human |

Headless commands used throughout, with `godot47` standing for the Steam binary:

```
godot47 --headless --path . --import                        # reimport assets, catch parse errors
godot47 --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests   # unit tests
godot47 --headless --path . res://scenes/dev/playground.tscn --quit-after 300  # scene smoke run
godot47 --headless --path . --doctool /tmp/godot-doc         # dump the 4.7 class reference when an API is in doubt
gdlint scenes scripts tests && gdformat --check scenes scripts tests
```

## Decisions fixed for implementation

These refine GAME.md without changing its rules.

- **Plane movement.** Karts are CharacterBody3D in floating motion mode with no
  gravity; all gameplay happens on the XZ plane. Falling into a pit is an
  animation, not physics. This keeps movement deterministic and easy to
  network.
- **Fixed tick.** All gameplay runs in `_physics_process` at 60 Hz. Rendering
  uses physics interpolation. Nothing gameplay-relevant reads `delta` from
  `_process`.
- **Arena from text.** The map is an `ArenaLayout` resource holding the ASCII
  grid from GAME.md 6.3. An `ArenaBuilder` turns it into geometry and markers at
  load: consecutive wall cells merge into segments, every letter becomes the
  matching element scene. Editing the map means editing text.
- **Identity by slot.** Players and bots are slots 0 to 3. Kills, ownership and
  scores reference slot ids, never node paths or instance ids.
- **One RNG.** All randomness goes through a RandomNumberGenerator owned by the
  Match and seeded at match start, so online play can replicate the seed.
- **Bullets step by cast.** Each tick a bullet casts a sphere from its previous
  to its next position against walls, karts, crates, turrets and other bullets,
  and resolves the first hit. No tunnelling at any speed.
- **Bots path on the grid.** AStarGrid2D over the 32 by 18 arena grid, cells of
  1.25 m, walls, crates and pits marked solid, with local steering and bullet
  dodging on top. No navmesh baking.
- **Physics layers.** 1 `world`, 2 `kart`, 3 `bullet`, 4 `pickup`, 5 `trigger`,
  6 `graze`, 7 `turret`. Spawn-protected karts move to a `protected` layer that
  bullets do not scan.
- **Events autoload.** Global signals: `coin_collected`, `mult_gained`,
  `grazed`, `kart_killed`, `kart_respawned`, `bank_started`, `bank_completed`,
  `jackpot_collected`, `jackpot_full`, `item_picked`, `item_used`,
  `joker_offered`, `joker_taken`, `match_state_changed`. HUD, audio, tally and
  jokers subscribe; gameplay code emits and never reaches into UI.
- **Resources.** `KartStats`, `CannonStats`, `PowerUp` and subclasses, `Joker`
  and subclasses, `BotTrait`, `BotDifficulty`, `ArenaLayout`. Every number in
  GAME.md lives in one of these or in an exported variable.
- **Joker menu selection** uses D-pad left and right to cycle slots on a
  gamepad, 1 to 5 on keyboard.

## Phase 0: project setup

Goal: a project that imports, lints, tests and runs headless with an empty
scene, plus the repository basics.

- [x] `project.godot`: name "Jackpot Junction", main scene, 1920 by 1080
      window, MSAA 2x, physics interpolation on, 60 Hz physics, Jolt, layer
      names, `untyped_declaration` warning as error, autoloads `Game`, `Events`,
      `Audio`.
- [x] Input map: `steer_left`, `steer_right`, `throttle`, `brake`, `fire`,
      `handbrake`, `use_item`, `joker_menu`, `joker_prev`, `joker_next`,
      `joker_select_1` to `joker_select_5`, `joker_drop`, `joker_destroy`,
      `aim_x`, `aim_y`, `pause`, bound as in GAME.md 4.2.
- [x] Folder layout from GAME.md 10.2, autoload scripts with empty bodies.
- [x] `LICENSE` with GPL-3.0, `README.md` with a paragraph, how to run, and the
      license split for code and assets.
- [x] gdUnit4 in `addons/`, row in `THIRD_PARTY.md`, one smoke test.
- [x] gdtoolkit installed, `.gdlintrc` with the project conventions.
- [x] `.github/workflows/ci.yml`: checkout, fetch Godot 4.7.2, import, lint,
      format check, run tests.
- [x] Dev harness `scenes/dev/playground.tscn`: empty floor, camera, loads in
      one command.

Verify: import, lint, tests and the smoke run all pass headless; CI is green
on the first push.

## M0: grey-box, camera, kart feel

Goal: drive a kart around Lucky Crossing and enjoy it. Everything here is a
grey box.

- [x] `ArenaLayout` resource and parser: grid validation, element positions,
      wall segment merging, symmetry check. `data/maps/lucky_crossing.tres`.
- [x] `ArenaBuilder`: floor, merged wall segments as StaticBody3D with box
      shapes and meshes, placeholder pads and zones as flat coloured discs,
      spawn markers, pits as holes with a trigger, turbo pads with an arrow
      mesh and direction.
- [x] `KartStats` resource with every handling number from GAME.md 4.1;
      `data/kart/default.tres`.
- [x] `Kart` scene: CharacterBody3D, box collision, placeholder body and wheels
      tinted per slot, `KartMotor` implementing throttle, brake, reverse,
      speed-dependent yaw, grip model, drift entry and exit, exit boost, wall
      speed loss, kart bump response, turbo pad response.
- [x] `KartInput` base with fields for every action; `PlayerInput` reading the
      input map for one device.
- [x] `CameraRig`: fit the arena bounds at 55° pitch and 35° FOV, pan and zoom
      toward tracked karts within the limits in GAME.md 8.2, smoothing, a
      `shake(strength)` entry point.
- [x] Trails: tire mark ribbons per rear wheel with fade and a segment cap,
      exhaust smoke particles scaled by throttle with bursts on drift and boost.
- [x] Debug overlay on F3: speed, drift state, grip, arena crossing timer.
- [x] Optional tuning panel on F4 that edits the active `KartStats` live and
      can write it back to the resource.

Verify: tests for the layout parser, wall merging and the symmetry of the map;
tests for the motor's pure functions such as yaw rate by speed and drift entry.
Smoke run of the playground. Then a handling session with a gamepad and a
keyboard: crossing time close to 3 s, drift feels controllable, exit boost
noticeable. Expect two or three tuning rounds; write the final numbers into
GAME.md.

Status: built and checked headless (32 tests, smoke run, screenshot). The
handling session is still open: run `make run`, F3 shows the readout, F4 the
tuning panel, and Save writes the numbers back to `data/kart/default.tres`.

## M1: combat

Goal: two karts on one machine can kill each other, and every death has a
clear cause.

- [x] `CannonStats` resource and `Cannon` component: cooldown, live bullet
      count, muzzle offset, forward-only fire; `data/cannons/default.tres`.
- [x] `Bullet`: sphere-cast stepping, one bounce with reflection, lifetime,
      owner slot, tint and trail, bullet against bullet cancel, aim assist
      steering inside the cone until the first bounce.
- [x] Kart death and respawn: `die(cause, killer_slot)`, 3 s delay, spawn point
      farthest from enemies, 2 s protection on the protected layer with firing
      disabled, own bullets deadly.
- [x] Crates: one hit destroys, respawn after 30 s, drops come in M2.
- [x] Pits: 0.4 s uncontrollable fall then death, last bump attribution within
      2 s.
- [x] Kart bumps with the bump rule; a `ramming` flag on the kart for Boost to
      set in M3.
- [x] `Match` skeleton: slot list, spawns karts, Playing state only, emits
      `kart_killed` and `kart_respawned`.
- [x] Minimal `InputRouter`: two devices, two slots, enough to test with two
      humans.

Verify: tests for reflection, aim assist cone and turn limit, spawn selection,
live bullet accounting. Smoke run with two karts driven by a scripted input
that drives and fires. A two-player session on one machine.

Status: built and checked headless, including an integration test in which a
bullet kills the kart ahead and the victim respawns protected. The two-player
session is still open: `tools/godot --path . res://scenes/dev/playground.tscn
++ --players=2` puts the keyboard on slot 0 and the first gamepad on slot 1.

## M2: economy

Goal: a complete solo match with a score, the Junction, the Jackpot, HUD and
tally.

- [x] `scoring.gd`: pure functions for pot value, death split, bank rate,
      amount banked over a time span in closed form, coins remaining after a
      drain, Jackpot collection over a span. Golden tests reproduce the tables
      in GAME.md 3.4 and 3.5.
- [x] `Pot` component: coins, mult, signals, reset.
- [x] Pickups: chip, gold chip, mult die, dropped chip with lifetime;
      `PickupArea` on the kart with the 0.9 m radius.
- [x] Coin pads with the weighted spawn table and 5 s respawn; crate drops.
- [x] `GrazeArea`: enemy bullets entering and leaving without a hit award +0.5
      with the cooldown.
- [x] `JunctionPad`: per-kart channel, drain per tick from the closed form,
      partial banking on leave, completion reset, Last Call doubling, progress
      ring.
- [x] `JackpotZone`: two zones, accrual and cap, single collector channel,
      contested pause, empty and switch, traffic light state.
- [x] Full death sequence from GAME.md 3.6 except item drops.
- [x] Match flow: countdown, timer, Last Call, target score, time out with
      unbanked pots lost, basic results screen, rematch.
- [x] HUD: player block with banked score and pot line, timer, standings
      strip, floating graze text, `TallyPopup` first version.

Verify: scoring tests including the timing tables, a drain simulation test
that ticks at 60 Hz and matches the closed form within one tick, a Jackpot
contested test. A 5 minute solo match end to end, headless smoke run of the
match scene, and a play session.

Status: built and checked headless. Scoring tests reproduce the GAME.md
tables; integration tests cover the countdown to results flow, banking at the
Junction, the death sequence, Jackpot collection and hand-over, coin pads and
grazing. The play session is still open.

## M3: items and jokers

Goal: power-ups and jokers work in a solo match, with drops and floor pickups.

- [x] `PowerUp` base resource, `ItemHolder` on the kart, power-up pads with the
      weighted table, roulette flicker, hold one rule.
- [x] First set: Boost with ram kills, Shield, Turret scene with owner
      attribution and lifetime, Ricochet Cannon as a `CannonStats` override for
      8 shots, Coin Magnet with attraction.
- [x] `Joker` base resource with the hooks listed in GAME.md 10.2,
      `JokerHolder` with per-holder instances, hook dispatch from Pot, Cannon,
      KartMotor, JunctionPad and the death sequence.
- [x] Respawn offer: 3 weighted offers without duplicates, pick or skip,
      respawn waits, swap when holding 5; `JokerPick` UI.
- [x] `JokerMenu` in the arena: cycle, drop to floor, destroy, kart stays
      controllable.
- [x] Death drops of a joker and the held item, floor pickups with 15 s
      lifetime.
- [x] The 20 jokers from GAME.md 7.3, one script and one `.tres` each.

Verify: a test per joker where the effect is numeric or rule based, offer
weighting and no-duplicate tests, power-up table weights. Play session.

Status: built and checked headless. Tests cover every power-up in the first
set, stat rebuilding, all twenty jokers' effects, offers with take, skip,
replace and the full-hand rule, floor drops and pickups. The play session is
still open.

## M4: bots and flow, first release

Goal: a complete single-player game against 3 bots, with menus, settings,
audio and art, published as a GitHub Release.

- [x] Grid pathfinding with AStarGrid2D, updated when crates die and respawn.
- [x] `BotBrain`: utility goals from GAME.md 9.1, path following, bullet dodge
      prediction, firing with lead, reaction delay and aim error, traits and
      difficulty resources, `BotInput`.
- [x] Title screen, lobby with options and colour picking, countdown, control
      hints at match start, results with podium, settings with rebinding,
      audio, video and accessibility, persistence with ConfigFile.
- [x] `Audio` autoload with Master, Music and SFX buses; music loop and the
      sound set from GAME.md 8.4 from free sources, every file in
      `THIRD_PARTY.md`.
- [x] Art pass: kart model, blocks, chips, pad and zone visuals, palette,
      lighting, tally polish with flying chips and fanfare, camera shake.
- [x] Decoy Kart power-up once bots are stable, otherwise it slips to after
      the release.
- [x] `export_presets.cfg` for Linux, Windows and macOS, 4.7.2 templates
      installed, `.github/workflows/release.yml` building on tags and attaching
      the builds to a GitHub Release.
- [ ] Tag `v0.1.0`.

Verify: bot tests for goal selection with fixed inputs and for dodge
prediction; a full match against 3 bots on each difficulty; the performance
budget from GAME.md 10.1 checked with the profiler; export builds start on a
clean machine.

Status: built and checked headless. Bots, menus, settings, audio, the Kenney
kart model, the later power-up set and the export presets are in; `make
export` produces the three builds locally and the release workflow builds
them on a `v*` tag. Still open: the full match against bots on each
difficulty as a play session, the profiler pass, a clean-machine start of the
exports, and the `v0.1.0` tag itself, which is the user's call.

## M5: local multiplayer

- [ ] Full `InputRouter`: join in the lobby and mid-match by pressing a button
      on an unused device, keyboard and mouse as one device, bot takeover on
      join, hand back on leave.
- [ ] Four HUD blocks in the corners, joker pick inside the owner's block,
      pause freezing the match for everyone.
- [ ] Camera pan toward the centroid of all karts.

Verify: four devices on one machine, join and leave during a match.

## M6: online multiplayer

- [ ] Host and join screens with IP and port, ENet peer.
- [ ] MultiplayerSpawner for karts, bullets, pickups, turrets and decoys;
      MultiplayerSynchronizer on kart transform and velocity at 30 Hz with
      interpolation.
- [ ] `NetInput`: clients send input state per tick by unreliable ordered RPC;
      the host simulates, decides hits, pickups, banking and scoring, and
      replicates the RNG seed.
- [ ] Bots on the host, no pause, mid-match join by the local rule.
- [ ] Prediction and reconciliation for the local kart if latency tests call
      for it.

Verify: two machines on a LAN, then a WAN test over a direct IP.

## Working method

- **One milestone per branch**, small commits, GAME.md updated in the same
  commit as any rule or number change.
- **Playtests are the user's job**, handling and readability cannot be judged
  headless. Each tuning round ends with numbers written back into GAME.md.
- **Every asset gets a row** in `THIRD_PARTY.md` in the commit that adds it.
- **API doubts** are settled against the 4.7 class reference dumped with
  `--doctool`, not from memory.

## Risks

| Risk                                        | Mitigation                                                         |
|---------------------------------------------|--------------------------------------------------------------------|
| Kart handling does not feel right           | Every number in `KartStats`, live tuning panel, tuning rounds budgeted in M0 |
| Bullet cancel and bounce edge cases         | Sphere cast per tick resolves the first hit only; unit tests for reflection and ordering |
| Bots read as dumb or unfair                 | Traits and difficulty as data, reaction delay as an input queue, dodge as a probability |
| Performance with trails and 100 bullets     | Segment caps, pooled bullets, profiler check in M4                 |
| Godot 4.7 API differs from expectation      | Dump the class reference with `--doctool` and check before use     |
| Export templates for 4.7.2 missing          | Install before M4; the release workflow downloads its own copy     |
