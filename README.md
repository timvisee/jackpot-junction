# Jackpot Junction

A top-down arena kart game in which every life is a hand of cards. Drive a
drifty toy kart through a bullet-filled diorama, collect poker-chip coins and
multipliers, and decide when to cash out at the Junction before someone shoots
you.

Made with Godot 4.7 and GDScript. `GAME.md` holds the design, `PLAN.md` the
implementation plan with the status of every milestone.

## Playing

- **Single-player**: Play, pick match length, target score, bots and
  difficulty, start. Bots use the same karts, items and jokers you do.
- **Local multiplayer**: in the lobby or mid-match, press Start on a gamepad or
  J on the keyboard to join. Steer left or right in the lobby to change colour.
- **Online**: Play online, host on a port or join a friend's address directly.
  The host runs the match; joining players take over bot karts.

Default controls, all rebindable in Settings:

| Action               | Keyboard        | Gamepad          |
|----------------------|-----------------|------------------|
| Drive, brake, steer  | W, S, A, D      | Triggers, stick  |
| Fire                 | Space           | RB               |
| Handbrake            | Shift           | LB               |
| Use item             | E               | A                |
| Joker menu           | Tab, 1 to 5     | Y, D-pad         |
| Pause                | Escape          | Start            |

## Development

Requires a Godot 4.7 binary. `tools/godot` finds it through `$GODOT`, the Steam
install, or `godot4` on the path. Lint and format use
[gdtoolkit](https://github.com/Scony/godot-gdscript-toolkit): `pipx install gdtoolkit`.

```
make run        # start the development scene
make check      # import, lint, format check, unit tests, smoke runs
make test       # unit tests only (gdUnit4, headless)
make export     # release builds for Linux, Windows and macOS in build/
```

A tag `v*` makes the release workflow build and publish the three exports.

## License

The source code is licensed under the GPL-3.0, see `LICENSE`. Assets made for
the game are licensed under CC-BY-4.0. Third-party assets and libraries keep
their own licenses and are listed in `THIRD_PARTY.md`. The music is licensed
from Ovani Sound to this game's developer and is not covered by either
license.
