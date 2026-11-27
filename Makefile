# Common commands. Requires a Godot 4.7 binary (see tools/godot) and gdtoolkit (pipx install gdtoolkit).
GODOT ?= tools/godot
GDLINT ?= gdlint
GDFORMAT ?= gdformat
GD_DIRS := scenes scripts tests
# Handed to the game after `--`, for the targets that start it: `make run ARGS=--touch=1` plays with
# the touch controls on a desktop, the mouse standing in for a finger, GAME.md 4.2.
ARGS ?=

.PHONY: import test test-serial lint format format-check strings strings-check smoke run demo demo-soak jokers achievements achievement-art steam-achievement-art steam-timeline-icons itch-art steam-art steam-supporter-art screenshots trailer trailer-draft dialog-bench ui-bench logo card-backs textures bench profile probe warmup-check bots multiplayer multiplayer-lag server-check changelog check export docker android android-install android-release server private-assets steam-addon steam-input steam-presence steam-run steam-check steam-export

# Godot keeps its import cache and its register of every class_name in .godot. Without them
# nothing runs: no class_name is known, so every script that names another fails to parse and the
# autoloads never load, which is what a fresh clone and a cleared .godot both look like. The game
# itself never writes them -- only an import or the editor does -- so the targets that start it
# ask for them first. The register is the marker rather than the directory, so a warm tree pays
# nothing and a cold one imports itself once. It is made again whenever a script is newer than it:
# a class added by somebody else's merge is unknown until the project is imported again, and every
# script naming it fails to compile. Touched after, since an import that adds no class leaves it.
CACHE := .godot/global_script_class_cache.cfg

$(CACHE): $(shell find scenes scripts tests tools -name '*.gd' 2>/dev/null)
	tools/private_assets --if-present
	$(GODOT) --headless --path . --import
	touch $@

# The licensed music is linked in first when its private checkout is there, see private-assets.
import:
	tools/private_assets --if-present
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

# The words for translators, GAME.md 10.9: every word marked in the code and held by the data, into
# the template and each language's .po file in data/locale, keeping every translation made.
strings:
	python3 tools/strings.py update

# Fails when the template or a language's file is behind the code, or a string that looks like text
# is not marked for translation, and says which.
strings-check:
	python3 tools/strings.py check

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
	tools/smoke res://scenes/dev/joker_sheet.tscn 30

dev: | $(CACHE)
	$(GODOT) --path . res://scenes/dev/playground.tscn -- $(ARGS)

run: | $(CACHE)
	$(GODOT) --path . res://scenes/ui/title.tscn -- $(ARGS)

# The demo for a booth, GAME.md 9.8: Grand Prix after Grand Prix on its own, on user://demo.cfg and
# the profiles beside it, for anybody walking past to pick up a pad and play.
demo: | $(CACHE)
	$(GODOT) --path . -- --demo $(ARGS)

# The demo played for several runs on end with short maps, headless, failing if anything piles up
# from one run to the next: `make demo-soak ARGS=--runs=8` for more. A few minutes; not in check.
demo-soak: | $(CACHE)
	$(GODOT) --headless --fixed-fps 60 --path . -s tools/demo_soak.gd -- --demo \
		--settings=demo-soak.cfg --demo-map-seconds=10 $(ARGS)

# A dedicated server, GAME.md 9.3a, headless on port 7777 and holding up to 8 games on the ports
# after it: `make server ARGS="--port=7790 --games=4"` for others. Players reach it with Play
# Online.
server: | $(CACHE)
	$(GODOT) --headless --path . -- --server $(ARGS)

# What the game runs at, as a number: a match of four bots on each map, 600 frames after the
# warm-up. A change that costs frames should be caught here rather than in a play session.
bench: | $(CACHE)
	JJ_SETTINGS=tests.cfg $(GODOT) --path . --disable-vsync res://scenes/dev/playground.tscn -- --clean=1 --bots=3 --map=lucky_crossing --bench=720
	JJ_SETTINGS=tests.cfg $(GODOT) --path . --disable-vsync res://scenes/dev/playground.tscn -- --clean=1 --bots=3 --map=vault --bench=720
	JJ_SETTINGS=tests.cfg $(GODOT) --path . --disable-vsync res://scenes/dev/playground.tscn -- --clean=1 --bots=3 --map=crossfire --bench=720

# The surfaces the rooms of GAME.md 8.1 are made of: felt, wood, paint and concrete, generated
# rather than painted. Needs numpy and pillow.
textures:
	python3 tools/make_textures.py

# The game's own mark, drawn by LogoArt and written out as the icon, the splash and assets/logo.
logo: | $(CACHE)
	$(GODOT) --path . res://scenes/dev/logo_export.tscn

# The card backs won in the loyalty program, drawn by CardBack and written out as the pictures the
# rooms' cards wear face down, GAME.md 8.9.
card-backs: | $(CACHE)
	$(GODOT) --path . res://scenes/dev/card_back_export.tscn

# Every icon in the game at once, to see the pictures of GAME.md 8.3a as one set.
jokers: | $(CACHE)
	$(GODOT) --path . res://scenes/dev/joker_sheet.tscn

# Every achievement's chip and pin, earned and not and hidden, to see GAME.md 8.10's as one set.
achievements: | $(CACHE)
	$(GODOT) --path . res://scenes/dev/achievement_sheet.tscn

# The pictures and words a store's page wants for the achievements, GAME.md 8.10: every chip and
# pin earned and not, and the hidden scrap, at 1024 pixels and cut to 256 and 64, with a text file
# and a table of every id, name and objective, into build/achievements.
achievement-art: | $(CACHE)
	$(GODOT) --path . res://scenes/dev/achievement_export.tscn

# The same for Steamworks' Bulk Import/Export, docs/STEAM.md: each icon earned and not at 256
# pixels, named as Steam pairs them with their achievements, the definitions and English words as
# Steam's own export writes them, named after STEAM_APP_ID, and the statistics to make first, into
# build/steam-achievements.
steam-achievement-art: | $(CACHE)
	$(GODOT) --path . res://scenes/dev/steam_achievement_export.tscn -- --app=$(STEAM_APP_ID)

# The game's own icons for the timeline of Steam's game recording, GAME.md 10.8, to upload by hand
# on Steamworks, docs/STEAM.md: each white on nothing at 256 pixels, named as the game calls it,
# into build/steam-timeline-icons, emptied first. Needs a display.
steam-timeline-icons: | $(CACHE)
	$(GODOT) --path . res://scenes/dev/steam_timeline_icon_export.tscn

# The pictures the game's page on itch.io wears, docs/ITCH.md: the cover, 630 by 500, and the
# page's background, both put up from the game's own arena, karts and seal, into build/itch. At a
# fixed frame rate, so the karts are where they are meant to be. Needs a display.
itch-art: | $(CACHE)
	JJ_SETTINGS=tests.cfg $(GODOT) --path . --fixed-fps 60 res://scenes/dev/itch_export.tscn

# The languages the game speaks besides English, by locale: a .po file each, GAME.md 10.9.
LANGUAGES := $(basename $(notdir $(wildcard data/locale/*.po)))

# Every picture Steamworks asks for but the achievements', docs/STEAM.md, into build/steam-art,
# emptied first, each named after its field: the store's capsules and background, the library's
# capsule, header, hero and logo, the icons, the avatars, the description's headings and pictures,
# an announcement's cover and header, all put up from the game's own pieces, and the store page's
# screenshots. Then, for the store page in each other language the game speaks, the screenshots and
# the description's pictures with words in them in it, in a folder named for it. Needs a display,
# or GODOT_HIDDEN=1 and gamescope.
steam-art: | $(CACHE)
	rm -rf build/steam-art
	JJ_SETTINGS=tests.cfg $(GODOT) --path . --fixed-fps 60 res://scenes/dev/steam_art_export.tscn
	tools/screenshots --steam
	for language in $(LANGUAGES); do \
		JJ_SETTINGS=tests.cfg $(GODOT) --path . --fixed-fps 60 \
			res://scenes/dev/steam_art_export.tscn -- --language=$$language && \
		tools/screenshots --steam --language=$$language || exit 1; \
	done
	$(MAKE) steam-supporter-art

# The supporter pack's DLC's own store art, GAME.md 10.8, docs/STEAM.md "The supporter pack", into
# build/steam-art/supporter, apart from the game's: its capsules, its description's headings and
# pictures, also kept in docs/description/supporter, and its screenshots; then its headings and
# screenshots in each other language the game speaks. Needs a display, or GODOT_HIDDEN=1 and
# gamescope.
steam-supporter-art: | $(CACHE)
	rm -rf build/steam-art/supporter
	JJ_SETTINGS=tests.cfg $(GODOT) --path . --fixed-fps 60 res://scenes/dev/supporter_art_export.tscn
	tools/screenshots --supporter
	for language in $(LANGUAGES); do \
		JJ_SETTINGS=tests.cfg $(GODOT) --path . --fixed-fps 60 \
			res://scenes/dev/supporter_art_export.tscn -- --language=$$language && \
		tools/screenshots --supporter --language=$$language || exit 1; \
	done

# The screenshots the README wears, into docs/screenshots, each drawn oversize and brought back down
# for smooth edges, GAME.md 10.7. Needs a display, or GODOT_HIDDEN=1 and gamescope.
screenshots: | $(CACHE)
	tools/screenshots

# The store trailer, docs/STEAM.md "The trailer": its shots recorded by the game's movie writer, one
# by one, and cut to the music, into build/trailer, drawn at 8K and scaled down to 4K for YouTube
# and 1080p for the store; a quicker draft at 1080p with trailer-draft. GODOT_HIDDEN=1 for no window.
# LANGUAGE=nl records it in another language the game speaks, into build/trailer/dutch.
trailer:
	tools/trailer --8k $(if $(LANGUAGE),--language=$(LANGUAGE))

trailer-draft:
	tools/trailer $(if $(LANGUAGE),--language=$(LANGUAGE))

# What the achievements dialog and the catalog cost a frame, GAME.md 10.7, and whether each is
# within its budget of draw calls: their chips and cards drawn once into pictures rather than as
# themselves every frame. Needs a display.
dialog-bench: | $(CACHE)
	tools/dialog_bench

# What the HUD, the pause menu, the title, the settings and the driving school cost a frame, GAME.md
# 10.7, and whether each is within its budget.
ui-bench: | $(CACHE)
	tools/ui_bench

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

check: import lint format-check strings-check changelog test smoke multiplayer multiplayer-lag server-check

# The three desktop builds, and the dedicated server's for Linux, GAME.md 9.3a: the game exported as
# a server, headless and serving by itself, its visual data stripped and its sound left out.
export: | $(CACHE)
	@tools/music_check || true
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
	@tools/music_check || true
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
	@tools/music_check || true
	GODOT="$(GODOT)" tools/android-release

# The licensed music, GAME.md 10.6, which may not be in this public repository: each track of the
# private checkout beside this one linked into assets/audio/music, which git leaves out, the
# checkout cloned first if it is missing and brought up to date if it is there. Only the game's
# developer has access; without it the game builds and plays with no music. The exports above and
# below warn without it and go on. See tools/private_assets for copying and unlinking.
private-assets:
	tools/private_assets

# GodotSteam, the GDExtension the Steam builds reach Steam through, GAME.md 10.8: the pinned release
# into addons/godotsteam, which git ignores, and the project imported again to know it.
steam-addon:
	tools/steam_addon
	$(GODOT) --headless --path . --import

# The game's actions for Steam Input, GAME.md 10.8: the action manifest and the layout each kind of
# controller starts on, into data/steam/input, from SteamActions. Run whenever an action comes or
# goes or a pad's default button changes: test_steam_actions fails until it is.
steam-input: | $(CACHE)
	$(GODOT) --headless --path . -s tools/steam_input.gd

# What the Steam friends list says, GAME.md 10.8: a file of the presence's words for each language
# the game speaks, into docs/steam, from SteamPresence, uploaded to Steamworks. Run whenever a token,
# a map or the words change: test_steam_presence fails until it is.
steam-presence: | $(CACHE)
	$(GODOT) --headless --path . -s tools/steam_presence.gd

# The game from this checkout with Steam on, as Spacewar, app 480, unless data/steam/app.cfg names
# another: Steam has to be running. Without --steam nothing ever talks to Steam, GAME.md 10.8. The
# gamepads plugged in are left to Steam Input, as Steam leaves them for a game it starts, see
# tools/steam-run.
steam-run: | $(CACHE)
	tools/steam-run $(GODOT) $(ARGS)

# What the Steam client on this machine answers about the app, the account, its keyboard on the
# screen, rich presence and a lobby, see tools/steam_check.gd. By hand: it needs Steam running, so
# it is not part of check.
steam-check: | $(CACHE)
	$(GODOT) --headless --path . -s tools/steam_check.gd -- --steam

# The Steam builds, GAME.md 10.8, into build/steam, a folder each, Windows and Linux, each with its
# game data in a .pck beside the binary rather than in it. Linux's holds both CPUs' binaries,
# jackpot-junction.x86_64 and .arm64, on the one .pck they share, the ARM64 build's, which has every
# texture format; Valve's libsteam_api.so, the same name for both, in x86_64/ and arm64/; and
# tools/steam-launcher, which starts the one for the machine, since Steam cannot pick a depot by
# CPU, docs/STEAM.md. Each has steam_input/ beside its game, Steam Input's action manifest and
# layouts, which Steamworks names, docs/STEAM.md. No macOS: Steam takes a Mac build only notarized by Apple, so it waits, its preset kept for then.
# STEAM_APP_ID is the app they start as, Spacewar's 480 when none is named, and STEAM_SUPPORTER_DLC
# the supporter pack's DLC, none until there is one. Fetches GodotSteam first if it is not here.
STEAM_APP_ID ?= 480
STEAM_SUPPORTER_DLC ?= 0
steam-export: | $(CACHE)
	@tools/music_check || true
	test -f addons/godotsteam/godotsteam.gdextension || $(MAKE) steam-addon
	mkdir -p data/steam
	printf '[steam]\n\napp_id=%s\nsupporter_dlc=%s\n' "$(STEAM_APP_ID)" "$(STEAM_SUPPORTER_DLC)" \
		> data/steam/app.cfg
	rm -rf build/steam
	mkdir -p build/steam/windows build/steam/linux/x86_64 build/steam/linux/arm64
	$(GODOT) --headless --path . --export-release "Windows Steam" build/steam/windows/jackpot-junction.exe
	$(GODOT) --headless --path . --export-release "Linux Steam" build/steam/linux/jackpot-junction.x86_64
	mv build/steam/linux/libsteam_api.so build/steam/linux/x86_64/libsteam_api.so
	$(GODOT) --headless --path . --export-release "Linux ARM64 Steam" build/steam/linux/jackpot-junction.arm64
	mv build/steam/linux/libsteam_api.so build/steam/linux/arm64/libsteam_api.so
	install -m 755 tools/steam-launcher build/steam/linux/jackpot-junction
	mkdir -p build/steam/windows/steam_input build/steam/linux/steam_input
	cp data/steam/input/*.vdf build/steam/windows/steam_input/
	cp data/steam/input/*.vdf build/steam/linux/steam_input/
