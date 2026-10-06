# Common commands. Requires a Godot 4.7 binary (see tools/godot) and gdtoolkit (pipx install gdtoolkit).
GODOT ?= tools/godot
GDLINT ?= gdlint
GDFORMAT ?= gdformat
GD_DIRS := scenes scripts tests
# Handed to the game after `--`, for the targets that start it: `make run ARGS=--touch=1` plays with
# the touch controls on a desktop, the mouse standing in for a finger, GAME.md 4.2.
ARGS ?=

.PHONY: import test test-serial lint format format-check smoke run drive jokers logo textures bench profile probe warmup-check bots multiplayer multiplayer-lag server-check changelog check export docker android android-install android-release server

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

# A suite per process, several at once: about a minute rather than several. JOBS=n sets how
# many; test-serial runs the lot in one process, as a tie-breaker for a result that differs.
test: | $(CACHE)
	GODOT=$(GODOT) tools/test_parallel

test-serial: | $(CACHE)
	$(GODOT) --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests -c --ignoreHeadlessMode

lint:
	$(GDLINT) $(GD_DIRS)

format-check:
	$(GDFORMAT) --check $(GD_DIRS)

format:
	$(GDFORMAT) $(GD_DIRS)

smoke: | $(CACHE)
	# The first scene a player's game starts on, on its way to the title.
	tools/smoke res://scenes/boot/boot.tscn 30
	tools/smoke res://scenes/ui/title.tscn 30
	tools/smoke res://scenes/ui/settings_screen.tscn 30
	tools/smoke res://scenes/match/match_scene.tscn 120
	# Past the countdown, so the run does not end with a beep still sounding.
	tools/smoke res://scenes/garage/garage.tscn 240
	tools/smoke res://scenes/tutorial/tutorial.tscn 240
	tools/smoke res://scenes/waiting/waiting_room.tscn 60
	tools/smoke res://scenes/dev/playground.tscn
	tools/smoke res://scenes/dev/driving.tscn
	tools/smoke res://scenes/dev/joker_sheet.tscn 30

dev: | $(CACHE)
	$(GODOT) --path . res://scenes/dev/playground.tscn -- $(ARGS)

run: | $(CACHE)
	$(GODOT) --path . res://scenes/ui/title.tscn -- $(ARGS)

drive: | $(CACHE)
	$(GODOT) --path . res://scenes/dev/driving.tscn -- $(ARGS)

# A dedicated server, GAME.md 9.3a, headless on port 7777 and holding up to 8 games on the ports
# after it: `make server ARGS="--port=7790 --games=4"` for others. Players reach it with Play
# Online.
server: | $(CACHE)
	$(GODOT) --headless --path . -- --server $(ARGS)

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

# The game's own mark, drawn by LogoArt and written out as the icon, the splash and assets/logo.
logo: | $(CACHE)
	$(GODOT) --path . res://scenes/dev/logo_export.tscn

# Every icon in the game at once, to see the pictures of GAME.md 8.3a as one set.
jokers: | $(CACHE)
	$(GODOT) --path . res://scenes/dev/joker_sheet.tscn

# Whole matches of bots, reported as numbers. Minutes rather than seconds, so it is its own
# target rather than part of check.
# Where a frame goes: the script functions, server passes and GPU passes that take the most time,
# from Godot's own profilers, over a match against bots. FRAMES=n runs longer; ARGS goes to the
# playground, as with make dev.
profile: | $(CACHE)
	tools/profile $(FRAMES) $(ARGS)

# What a frame is made of: mesh instances by the script that built them, triangles, materials,
# lights, and the draw calls and primitives of each pass; ARGS="--ablate" also hides one group at
# a time and says what each costs.
probe: | $(CACHE)
	$(GODOT) --path . --disable-vsync -s tools/scene_probe.gd -- --clean=1 --bots=3 --frames=200 $(ARGS)

# Whether the shader warm-up behind the title compiles everything a match, the results and the
# finale draw, in a user directory of its own: a shader it misses is a stutter the first time a
# player meets it. Needs a display.
warmup-check: | $(CACHE)
	tools/warmup_check

bots: | $(CACHE)
	tools/bot_arena

# A whole Grand Prix played through the real scenes: two online games, the host and its clients
# as processes on this machine, and two players on one screen. About a minute and a half.
multiplayer: | $(CACHE)
	tools/multiplayer_check

# The same over a 50 ms round trip between every end, as a slow LAN would put there.
multiplayer-lag: | $(CACHE)
	MPCHECK_PING=50 tools/multiplayer_check

# A game on a dedicated server, GAME.md 9.3a, played through the real scenes: the server and three
# clients of it as processes on this machine, making, joining and watching one. About half a minute.
server-check: | $(CACHE)
	tools/server_check

# The changelog parses, and the version the game reports has notes to go with it.
changelog:
	tools/changelog

check: import lint format-check changelog test smoke multiplayer multiplayer-lag server-check

# The three desktop builds, and the dedicated server's for Linux, GAME.md 9.3a: the game exported as
# a server, headless and serving by itself, its visual data stripped and its sound left out.
export: | $(CACHE)
	# Emptied first: each folder is what goes in that platform's zip, and nothing else.
	rm -rf build/linux build/linux-server build/linux-arm64 build/linux-server-arm64 build/windows build/macos
	mkdir -p build/linux build/linux-server build/linux-arm64 build/linux-server-arm64 build/windows build/macos
	$(GODOT) --headless --path . --export-release "Linux" build/linux/jackpot-junction
	$(GODOT) --headless --path . --export-release "Linux Server" build/linux-server/jackpot-junction-server
	$(GODOT) --headless --path . --export-release "Linux ARM64" build/linux-arm64/jackpot-junction
	$(GODOT) --headless --path . --export-release "Linux Server ARM64" build/linux-server-arm64/jackpot-junction-server
	$(GODOT) --headless --path . --export-release "Windows" build/windows/jackpot-junction.exe
	$(GODOT) --headless --path . --export-release "macOS" build/macos/jackpot-junction.zip

# The dedicated server's container image, docker/Dockerfile, for this machine alone: the server
# exported for this machine's architecture and the image built from it, tagged DOCKER_IMAGE. The
# release workflow builds it for x86_64 and ARM together and publishes it, GAME.md 10.5.
DOCKER_IMAGE ?= timvisee/jackpot-junction-server:dev
DOCKER_ARM := $(filter aarch64 arm64,$(shell uname -m))
DOCKER_SERVER := build/linux-server$(if $(DOCKER_ARM),-arm64)
docker: | $(CACHE)
	mkdir -p $(DOCKER_SERVER)
	$(GODOT) --headless --path . --export-release "Linux Server$(if $(DOCKER_ARM), ARM64)" $(DOCKER_SERVER)/jackpot-junction-server
	docker build -f docker/Dockerfile -t $(DOCKER_IMAGE) build

# A debug build for Android phones and tablets in build/android, signed with the debug keystore
# the Godot editor's own settings name, next to the Android SDK and the JDK it builds with,
# GAME.md 10.5. Those live on this machine and not in the project. The second puts it on whatever
# phone adb can see.
android: | $(CACHE)
	mkdir -p build/android
	$(GODOT) --headless --path . --export-debug "Android" build/android/jackpot-junction.apk

android-install: android
	adb install -r build/android/jackpot-junction.apk

# The release build for Android in build/android, the APK every release publishes, GAME.md 10.5:
# Godot's release template, signed with the release key and checked to be, see
# tools/android-release. At a terminal it asks for the key's password; the release workflow sets
# it, with the rest of the key, from the repository's secrets. The SDK and the JDK are the
# editor's, or ANDROID_HOME's and JAVA_HOME's where it has none.
android-release: | $(CACHE)
	GODOT="$(GODOT)" tools/android-release
