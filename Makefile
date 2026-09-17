# Common commands. Requires a Godot 4.7 binary (see tools/godot) and gdtoolkit (pipx install gdtoolkit).
GODOT ?= tools/godot
GDLINT ?= gdlint
GDFORMAT ?= gdformat
GD_DIRS := scenes scripts tests

.PHONY: import test lint format format-check smoke run drive check export

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
	# Past the countdown, so the run does not end with a beep still sounding.
	tools/smoke res://scenes/garage/garage.tscn 240
	tools/smoke res://scenes/dev/playground.tscn
	tools/smoke res://scenes/dev/driving.tscn

run:
	$(GODOT) --path . res://scenes/dev/playground.tscn

drive:
	$(GODOT) --path . res://scenes/dev/driving.tscn

check: import lint format-check test smoke

export:
	mkdir -p build/linux build/windows build/macos
	$(GODOT) --headless --path . --export-release "Linux" build/linux/jackpot-junction.x86_64
	$(GODOT) --headless --path . --export-release "Windows" build/windows/jackpot-junction.exe
	$(GODOT) --headless --path . --export-release "macOS" build/macos/jackpot-junction.zip
