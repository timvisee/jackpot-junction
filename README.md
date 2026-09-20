# Jackpot Junction

A top-down arena kart game in which every life is a hand of cards. Drive a
drifty toy kart through a bullet-filled diorama, collect poker-chip coins and
multipliers, and decide when to cash out at the Junction before someone shoots
you.

Made with Godot 4.7 and GDScript. `GAME.md` holds the design, `PLAN.md` the
implementation plan with the status of every milestone, and `CHANGELOG.md` what
has changed in each release.

![Four karts on a felt-topped table arena, ringed by a crowd of onlookers several rows deep with tribunes built into it. A row of glass tanks filled to different levels and a DJ booth stand on the table at the far edge, the standings run down the right and a hand of joker cards along the bottom of the screen](docs/screenshot.png)

## Playing

- **Single-player**: Play, pick an arena, match length, target score, bots and
  difficulty, start. Bots use the same karts, items and jokers you do.
- **Local multiplayer**: in the lobby or mid-match, press Start on a gamepad or
  J on the keyboard to join. Steer left or right in the lobby to change colour,
  and give each seat a name and a kart to dress.
- **Online**: Play online, host on a port or join a friend's address directly.
  The host runs the match; joining players take over bot karts.
- **Garage**: a practice room with one of everything in it and two dummy karts to
  shoot at. The first visit goes to a test track that teaches the controls, and
  the two rooms have portals to each other.

Default controls, all rebindable in Settings:

| Action               | Keyboard        | Gamepad          |
|----------------------|-----------------|------------------|
| Drive, brake, steer  | W, S, A, D      | Triggers, stick  |
| Fire                 | Space           | A                |
| Handbrake            | Shift           | LB               |
| Nitro                | Ctrl            | RB               |
| Use item             | E               | X                |
| Joker menu           | Tab, 1 to 5     | Y, D-pad         |
| Pause                | Escape          | Start            |

## Development

Requires a Godot 4.7 binary. `tools/godot` finds it through `$GODOT`, the Steam
install, or `godot4` on the path. Lint and format use
[gdtoolkit](https://github.com/Scony/godot-gdscript-toolkit): `pipx install gdtoolkit`.

```
make dev        # start the development scene
make drive      # start the driving room, for handling work
make run        # start the game scene
make check      # import, lint, format check, changelog, unit tests, smoke runs
make test       # unit tests only (gdUnit4, headless)
make export     # release builds for Linux, Windows and macOS in build/
```

Anything a player would notice gets a line in the `## [Unreleased]` section of
`CHANGELOG.md` in the same commit, see GAME.md 10.4.

## Releasing

```
tools/changelog release 0.2.0     # cut Unreleased into a dated version, set project.godot
git commit -am "Release 0.2.0"
git tag -a v0.2.0 -m "Jackpot Junction 0.2.0" && git push --follow-tags
```

The tag starts the release workflow, which exports Linux, Windows and macOS
builds and publishes them with that version's changelog section as the release
notes. A tag whose version has no section fails rather than publishing a release
with nothing written on it. GAME.md 10.5 has the detail.

## License

The source code is licensed under the GPL-3.0, see `LICENSE`. Assets made for
the game are licensed under CC-BY-4.0. Third-party assets and libraries keep
their own licenses and are listed in `THIRD_PARTY.md`. The music is licensed
from Ovani Sound to this game's developer and is not covered by either
license.
