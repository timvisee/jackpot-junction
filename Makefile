# Common commands. Requires a Godot 4.7 binary (see tools/godot) and gdtoolkit (pipx install gdtoolkit).
GODOT ?= tools/godot
GDLINT ?= gdlint
GDFORMAT ?= gdformat
GD_DIRS := scenes scripts tests

.PHONY: import test lint format format-check smoke run drive jokers logo textures bench bots changelog check export

# Godot keeps its import cache and its register of every class_name in .godot. Without them
# nothing runs: no class_name is known, so every script that names another fails to parse and the
# autoloads never load, which is what a fresh clone and a cleared .godot both look like. The game
# itself never writes them -- only an import or the editor does -- so the targets that start it
# ask for them first. The register is the marker rather than the directory, so a warm tree pays
# nothing and a cold one imports itself once.
CACHE := .godot/global_script_class_cache.cfg

$(CACHE):
	$(GODOT) --headless --path . --import

import:
	$(GODOT) --headless --path . --import

test: | $(CACHE)
	$(GODOT) --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests -c --ignoreHeadlessMode

lint:
	$(GDLINT) $(GD_DIRS)

format-check:
	$(GDFORMAT) --check $(GD_DIRS)

format:
	$(GDFORMAT) $(GD_DIRS)

smoke: | $(CACHE)
	tools/smoke res://scenes/ui/title.tscn 30
	tools/smoke res://scenes/ui/lobby.tscn 30
	tools/smoke res://scenes/ui/settings_screen.tscn 30
	tools/smoke res://scenes/match/match_scene.tscn 120
	# Past the countdown, so the run does not end with a beep still sounding.
	tools/smoke res://scenes/garage/garage.tscn 240
	tools/smoke res://scenes/dev/playground.tscn
	tools/smoke res://scenes/dev/driving.tscn
	tools/smoke res://scenes/dev/joker_sheet.tscn 30

dev: | $(CACHE)
	$(GODOT) --path . res://scenes/dev/playground.tscn

run: | $(CACHE)
	$(GODOT) --path . res://scenes/ui/title.tscn

drive: | $(CACHE)
	$(GODOT) --path . res://scenes/dev/driving.tscn

# What the game runs at, as a number: a match of four bots on each map, 600 frames after the
# warm-up. A change that costs frames should be caught here rather than in a play session.
bench: | $(CACHE)
	$(GODOT) --path . --disable-vsync res://scenes/dev/playground.tscn -- --clean=1 --bots=3 --map=lucky_crossing --bench=720
	$(GODOT) --path . --disable-vsync res://scenes/dev/playground.tscn -- --clean=1 --bots=3 --map=vault --bench=720
	$(GODOT) --path . --disable-vsync res://scenes/dev/playground.tscn -- --clean=1 --bots=3 --map=crossfire --bench=720

# The surfaces the rooms of GAME.md 8.1 are made of: felt, wood, paint and concrete, generated
# rather than painted. Needs numpy and pillow.
textures:
	python3 tools/make_textures.py

# The game's own mark, drawn by LogoArt and written out as the icon the project wears.
logo: | $(CACHE)
	$(GODOT) --path . res://scenes/dev/logo_export.tscn

# Every icon in the game at once, to see the pictures of GAME.md 8.3a as one set.
jokers: | $(CACHE)
	$(GODOT) --path . res://scenes/dev/joker_sheet.tscn

# Whole matches of bots, reported as numbers. Minutes rather than seconds, so it is its own
# target rather than part of check.
bots: | $(CACHE)
	tools/bot_arena

# The changelog parses, and the version the game reports has notes to go with it.
changelog:
	tools/changelog

check: import lint format-check changelog test smoke

export: | $(CACHE)
	mkdir -p build/linux build/windows build/macos
	$(GODOT) --headless --path . --export-release "Linux" build/linux/jackpot-junction.x86_64
	$(GODOT) --headless --path . --export-release "Windows" build/windows/jackpot-junction.exe
	$(GODOT) --headless --path . --export-release "macOS" build/macos/jackpot-junction.zip
