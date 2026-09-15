# Jackpot Junction

A top-down arena kart game in which every life is a hand of cards. Drive a
drifty toy kart through a bullet-filled diorama, collect poker-chip coins and
multipliers, and decide when to cash out at the Junction before someone shoots
you.

Made with Godot 4.7 and GDScript. Early development: see `GAME.md` for the
design and `PLAN.md` for the implementation plan and status.

## Running

Requires a Godot 4.7 binary. `tools/godot` finds it through `$GODOT`, the Steam
install, or `godot4` on the path.

```
make run        # start the development scene
make check      # import, lint, format check, unit tests, smoke run
make test       # unit tests only (gdUnit4, headless)
```

Linting and formatting use [gdtoolkit](https://github.com/Scony/godot-gdscript-toolkit):
`pipx install gdtoolkit`.

## License

The source code is licensed under the GPL-3.0, see `LICENSE`. Assets made for
the game are licensed under CC-BY-4.0. Third-party assets and libraries keep
their own licenses and are listed in `THIRD_PARTY.md`.
