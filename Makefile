# Common commands. Requires a Godot 4.7 binary (see tools/godot) and gdtoolkit (pipx install gdtoolkit).
GODOT ?= tools/godot
GDLINT ?= gdlint
GDFORMAT ?= gdformat
GD_DIRS := scenes scripts tests

.PHONY: import test lint format format-check smoke run check

import:
	$(GODOT) --headless --path . --import

test:
	$(GODOT) --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests -c --ignoreHeadlessMode

lint:
	$(GDLINT) $(GD_DIRS)

format-check:
	$(GDFORMAT) --check $(GD_DIRS)

format:
	$(GDFORMAT) $(GD_DIRS)

smoke:
	tools/smoke res://scenes/ui/title.tscn 30
	tools/smoke res://scenes/ui/lobby.tscn 30
	tools/smoke res://scenes/ui/settings_screen.tscn 30
	tools/smoke res://scenes/match/match_scene.tscn 120
	tools/smoke res://scenes/dev/playground.tscn

run:
	$(GODOT) --path . res://scenes/dev/playground.tscn

check: import lint format-check test smoke
