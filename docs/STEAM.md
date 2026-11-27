# Steam

Everything to set up on [Steamworks](https://partner.steamgames.com) for the
Steam builds of GAME.md 10.8, once the game has an app of its own. Until then the
game plays as Spacewar, app 480, and none of this is needed. Each part says what
in the repository it goes with.

## The app

The game's app is 5652730, made free: its store package, priced free, is the one
players get, and never shows on the store. Its store page is
<https://store.steampowered.com/app/5652730>, linked from the README, the game's About page
and a dedicated server's web page.

1. Set the repository variable `STEAM_APP_ID` to `5652730` (Settings > Secrets and
   variables > Actions > Variables). From then on `.github/workflows/steam.yml`
   uploads every tag, see [Builds](#builds).

## Builds

`.github/workflows/steam.yml` makes the Steam builds on every `v*` tag, and by hand
from the Actions tab for any branch or tag. Until `STEAM_APP_ID` is set it only
keeps them, as the run's artifact for 7 days, made as Spacewar. With it set, it
uploads them with `tools/steam-upload`, which runs Valve's steamcmd and shows all
it says, and sets the build live on the beta branch `staging`, or the branch a run
by hand names. Making a build the one everybody gets, on the default branch, is done by
hand on Steamworks: Steam does not let a script do it.

1. **Depots** (SteamPipe > Depots), as Steamworks numbered them:

   | Depot | Platform | Folder in the build | Launch option, executable |
   |---|---|---|---|
   | 5652732 | Linux + SteamOS, 64-bit | `linux` | `jackpot-junction` |
   | 5652733 | Windows, 64-bit | `windows` | `jackpot-junction.exe` |
   | 5652734 | macOS | none yet | none yet |

   Both uploaded depots go into the store package and the Developer Comp package
   (the app's page, All Associated Packages, DLC, Demos and Tools), or Steam
   installs an empty folder. The macOS depot waits: Steam takes a Mac build only
   notarized by Apple, which needs an Apple Developer account, so it stays out of
   the packages and has no launch option until then. The GitHub releases and
   itch.io keep their macOS build. The Linux depot holds both Linux builds, x86_64
   and ARM64, behind a launcher, see "Linux ARM64". There is no Windows ARM64 build: neither GodotSteam nor Valve's SDK
   has a library for it.
2. **Branches** (SteamPipe > Builds): the beta branch `staging`, with a password if
   only testers should see it. Steamworks lets a branch be made only once the
   default branch has a build, so the first goes up without one: run the Steam
   workflow by hand with the branch `none`, which uploads the build and sets it live
   nowhere. Set it live on `default` by hand, which before the release only the
   Developer Comp's accounts can install, then make `staging` with the "create" link
   that appears on the Builds page and set the build live on it as well; every run
   after sets its own. Publish the app's settings first (Edit Steamworks Settings > Publish): until
   the depots are published, Steam refuses a build with "Failed to initialize
   build on server (Access Denied)", however the builder account is set up. The
   first build, 26765952, went up on 2026-11-18 once they were.
3. **Linux runtime** (Installation > Linux Runtime): Steam Linux Runtime 4.0, as
   Valve recommends for a new native game.
4. **Builder account**: a Steam account of its own, added to the app's partner
   group with only "Edit App Metadata" and "Publish App Changes To Steam", with
   Steam Guard by email. Log in to it once with steamcmd on any machine
   (`steamcmd +login <name> +quit`, giving the code it is mailed), then set two
   repository secrets: `STEAM_USERNAME`, its name, and `STEAM_CONFIG_VDF`, the
   file steamcmd kept, `base64 -w0 ~/Steam/config/config.vdf`. When Steam asks
   for a new code, the upload fails: log in again and set the secret again.
5. **Variables**: `STEAM_APP_ID`, the app's id, turns the upload on;
   `STEAM_SUPPORTER_DLC`, the supporter pack's DLC once there is one (M19's S8),
   is written into the build for the game to ask Steam about.

The GitHub release builds never hold anything of Steam: `release.yml` fails if a
zip or the APK it would publish holds Valve's library or GodotSteam.

## Linux ARM64

Built on 2026-11-23, once the game had been released on Steam once (0.23.0),
PLAN.md M19's S10; Steamworks' side below is the user's.
Steam runs on one ARM64 Linux machine, the Steam Frame, which plays an x86_64
Linux build under FEX's emulation, so the game already runs there; a build of its
own would run without it.

Steam has nothing to pick a build by CPU: a depot's and a launch option's
architecture is 32 or 64-bit, nothing more, and Valve documents no ARM64 choice.
Factorio worked out a way with Valve, its [Friday Facts
#446](https://www.factorio.com/blog/post/fff-446) of 2026-09-18: both builds go to
every Linux player in the one Linux depot, and a shell script, the launch option,
starts the one for the machine. Half-Life: Alyx, Dota 2, Counter-Strike 2 and
Portal 2 have no ARM64 build at all; their app info lists x86_64 only.

**The depot.** Linux's, 5652732, holds both CPUs' binaries in one folder, on the
one copy of the game's data, a `.pck` beside them, and the launcher. Each binary
finds the data by its own name, `jackpot-junction` with its extension taken off,
which is how Godot names a Linux export's binary and its `.pck`. Godot's release
templates are built without path overrides: they take no `--main-pack`, and find
no `.pck` in the folder they are started in, so the data has to stand beside the
binary under that name. Only Valve's `libsteam_api.so` goes in a folder per CPU,
since both are called that and GodotSteam asks for it by that name: it looks
beside itself first, `$ORIGIN`, and then where the launcher points it,
`LD_LIBRARY_PATH`. No symlinks, which SteamPipe is not known to keep.

```text
jackpot-junction           the launcher, still the launch option
jackpot-junction.x86_64    the x86_64 binary
jackpot-junction.arm64     the ARM64 binary
jackpot-junction.pck       the game's data, the ARM64 export's, for both
libgodotsteam.linux.template_release.x86_64.so
libgodotsteam.linux.template_release.arm64.so
x86_64/libsteam_api.so
arm64/libsteam_api.so
```

**The launcher**, `tools/steam-launcher`, copied in by `make steam-export`:

```sh
#!/bin/sh
# The Linux Steam build's launch option, GAME.md 10.8 and docs/STEAM.md, "Linux ARM64": Steam has
# no way to pick a depot by CPU, so the Linux depot holds both CPUs' binaries,
# jackpot-junction.x86_64 and jackpot-junction.arm64, beside the game's data they share,
# jackpot-junction.pck, which each finds by its own name; and Valve's libsteam_api.so, the same
# name for both, in x86_64/ and arm64/. This starts the one for the machine with its
# libsteam_api.so in reach, GodotSteam looking beside itself first and there after, handing on what
# Steam passes, a friend's lobby among it. `make steam-export` copies it in as jackpot-junction.
here="$(dirname "$(readlink -f "$0")")"
case "$(uname -m)" in
aarch64 | arm64) cpu=arm64 ;;
*) cpu=x86_64 ;;
esac
LD_LIBRARY_PATH="$here/$cpu${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export LD_LIBRARY_PATH
exec "$here/jackpot-junction.$cpu" "$@"
```

`"$@"` hands on what Steam passes, `+connect_lobby <id>` for a friend's game among
it. Nothing else changes for the game: its saves go by the game's name, not the
binary's folder, and the only code that starts the binary again, the server hall,
is never in a Steam build.

**In the repository**, done:

1. `make steam-export` exports "Linux Steam" as
   `build/steam/linux/jackpot-junction.x86_64` and "Linux ARM64 Steam" as
   `jackpot-junction.arm64` beside it, the ARM64 export's
   `.pck` written over the x86_64 one's, moves each `libsteam_api.so` into its CPU's
   folder, and copies the launcher in as `jackpot-junction`, executable. Tried on
   2026-11-23: through the launcher the x86_64 binary runs on the shared `.pck` and
   GodotSteam finds its `libsteam_api.so` in `x86_64/`, and without the launcher's
   path it does not.
2. `steam.yml` checks for the binaries, the `.pck`, both `libsteam_api.so` files in
   their folders and none beside the binaries, and the launcher, and uploads `linux`
   as before; nothing else of the upload changes.
3. GAME.md 10.8 and this file say the Linux depot holds both.

**On Steamworks:**

1. The Linux launch option stays `jackpot-junction`, and the runtime Steam Linux
   Runtime 4.0, which has an ARM64 build of its own: Factorio's and Alyx's app info
   both map Linux to `steamrt4-any`.
2. Tell Steam the game runs on ARM64. Factorio's app info lists its CPUs as
   `x86,arm64`, but Valve documents no place to set it: look under Edit Store Page,
   Basic Info, by the supported operating systems, and under Installation. If it is
   in neither, ask Valve through Steamworks support, as Factorio did.

**Trying it.** The x86_64 path is tried as every build is, from `staging` on a
desktop, now through the launcher. The ARM64 path runs under Steam only on a
Steam Frame. Outside Steam, `./jackpot-junction --no-steam` in the folder runs on
any ARM64 Linux machine, a Raspberry Pi 5 for one. Put the first one on `staging`
before setting it live, as Factorio put theirs on its experimental branch first.

**The cost.** With the data shared, Linux players download 202 MB for both
binaries, measured on 2026-11-23: the x86_64 binary (74 MB), the ARM64 binary (67
MB), the one `.pck` (51 MB) and the libraries, rather than 231 MB for two whole
exports. It is the ARM64 export's `.pck`, which holds the ETC2/ASTC textures as
well, so x86_64 players get 11 MB they never use. "Windows Steam" keeps its data
beside its binary too, so every Steam build ships it the same way (the user,
2026-11-23): `jackpot-junction.pck` beside `jackpot-junction.exe`, which Godot finds
by its name, so the launch option stays as it is. It saves Windows players little,
at most a chunk per patch, see below.

**Patches.** Splitting the PCK out does not make Steam's updates smaller by itself,
measured on 2026-11-23 from the 0.23.0 and 0.23.1 builds and steamcmd's depot logs.
The binary part, Godot's own template, differs between releases only in the 3
header bytes that hold the PCK's size, and SteamPipe already reuses the rest:
0.23.1 went up as 12.0 MB for Linux and 13.1 MB for Windows, of 110 and 145 MB.
That is ~1 MB chunks dirtied by small changes scattered through the PCK. Of the
1.9 MiB that changed, 1.2 MiB had no source change behind it: the five kart `.glb`
imports, which every CI run imports anew and differently, and Godot's caches.
Caching `.godot/imported` in `steam.yml` should keep those the same. The user
parked both with this work.

## Steam Cloud

The profiles go to Steam Cloud, the settings stay with each machine. A Steam build
keeps both in a folder of the account's own, `steam/<SteamID64>/` in Godot's user
folder for the game, so the rule names the account with `{64BitSteamID}`. Under
App Admin > Cloud:

- Byte quota per user: 1048576 (a profile is a few kilobytes, at most 8 of them,
  each with its backup).
- Number of files allowed per user: 32 (at most 16 files, room to spare).
- Enable Auto-Cloud: two root paths, and two root overrides.

| Root | Subdirectory | Pattern | OS | Recursive |
|---|---|---|---|---|
| `WinAppDataRoaming` | `Godot/app_userdata/Jackpot Junction/steam/{64BitSteamID}/profiles` | `*.cfg` | All | No |
| `WinAppDataRoaming` | `Godot/app_userdata/Jackpot Junction/steam/{64BitSteamID}/profiles` | `*.cfg.bak` | All | No |

| Original root | OS | New root | Add/replace path | Replace path |
|---|---|---|---|---|
| `WinAppDataRoaming` | macOS | `MacAppSupport` | | No |
| `WinAppDataRoaming` | Linux + SteamOS | `LinuxXdgDataHome` | `godot/app_userdata/Jackpot Junction/steam/{64BitSteamID}/profiles` | Yes |

The macOS override is there for the Mac build, once Steam has one. Linux needs its
own path because Godot's folder there is `godot` in lowercase. The overrides go by
root, so they cover both paths. The `.bak` beside each profile, the one the last
save replaced, goes as well, so every machine has it to fall back on.

## Achievements

`make steam-achievement-art STEAM_APP_ID=<the app's id>` writes everything for
Steamworks' Bulk Import/Export into `build/steam-achievements/`, emptying it
first:

- `<app>-achievements-definitions.csv` and `<app>-achievements-localization.csv`,
  written as Steam's own export writes them: every achievement by its API name, a
  spoiler when hidden, set by the client, and each bar's statistic with its range;
  then its name and description in English and in every language the game speaks,
  the game's own translations, a column each under Steam's name for the language
  (`dutch`). Steam shows each player their own, and English where it has none.
- `<API_NAME>_ACHIEVED.png` and `<API_NAME>_UNACHIEVED.png` for each, at 256
  pixels, the names Steam pairs icons with their achievements by.
- `stats.txt`, the statistics the bars are drawn from. The importer does not take
  statistics, so they are made by hand.

Under Stats & Achievements:

1. **Stats** first, one per line of `stats.txt` (seven): type INT, API name as
   given, "Set By" Client, min 0, max as given, "Increment only" on, so a profile
   with less never takes anything away, GAME.md 8.10. A progress bar can only be
   drawn from a statistic that already exists.
2. **Achievements**, on the Bulk Import/Export tab: drop everything in the folder
   on the upload box at once, leave "Automatically generate unachieved icons" off,
   since the game has its own, check what it will change, and Save imported data.
3. Publish the changes.

`make achievement-art` is the same for any store: every picture at 1024, 256
and 64 pixels and the hidden scrap in `build/achievements/`, with
`achievements.txt` to read and `achievements.csv`, every id, name, objective and
bar.

When a language comes or the translations of the achievements change, run it again and import
what it writes again.

A bar's target grows with the game: when a release adds jokers, power-ups or
dress, run `make steam-achievement-art` again. Raise the stat's max by hand to
what `stats.txt` now says, then import the new definitions, which carry the
achievement's progress range. A debug build with the app's own id says at start
which names Steam and the game do not share. "Clear Steam's" on the Debug tab
takes everything back on the account, for trying it again.

## Rich presence

Under Community > Rich Presence, upload each of `docs/steam/rich_presence_<language>.vdf`
(UTF-8), one at a time, each naming its language inside: `rich_presence_english.vdf`, then
`rich_presence_dutch.vdf`. Then publish. They hold the words for every token the game sets,
GAME.md 10.8, in each language the game speaks, from its translations, and Steam shows each
friend their own, English where it has none. `make steam-presence` writes them, and a test fails
while they are behind the game: after a new map, or `make strings` with new words. Check what an
account says at https://steamcommunity.com/dev/testrichpresence while it plays.
Under app 480 nothing of ours can be uploaded, so the friends list shows nothing
of it, but the test page still lists the keys.

## Timeline icons

The game marks Steam's game-recording timeline, GAME.md 10.8, mostly with Steam's own icons, and
with three of its own: `jj_royal_flush`, `jj_777` and `jj_cards`. Draw them with
`make steam-timeline-icons` (needs a display), which writes each as a white PNG on transparency,
256 pixels square, to `build/steam-timeline-icons/`. Upload them at
https://partner.steamgames.com/apps/timelinemarkers/5652730, each under the name its file has
without `.png`, which is what the game asks Steam for; without them, Steam draws its plain marker.
Valve's documentation gives no size or format for these icons, and the 256-pixel PNGs were taken as
they are. All three were uploaded on 2026-11-23.

To see the markers, turn on Steam's game recording, play a map, and open the recording from the
overlay or from Recordings & Screenshots.

## Steam Input

A Steam build reads its controllers through Steam Input, GAME.md 10.8, with every
action of the game's named in Steam's controller settings. The action manifest and
the layout each kind of controller starts on are in `data/steam/input/`, written by
`make steam-input`, and `make steam-export` puts them in both depots as
`steam_input/`, beside the game. The actions' names are in every language the game speaks,
from its translations, and Steam shows each player their own: run `make steam-input` after
`make strings` whenever their words change.

1. **The template** (App Admin > Application > Steam Input): "Custom Configuration
   (Bundled with Game)", with the path `steam_input/action_manifest.vdf`, the same
   on Linux and Windows. Save, then publish (Edit Steamworks Settings > Publish).
   Not the Workshop's "Custom Configuration": Valve no longer recommends it for a
   new game, and the bundled files change with each build as the game does.
2. **Which controllers** (same page): tick PlayStation, Xbox, Switch, Generic, and
   Any Future Devices, as Valve asks of a game using Steam Input's API. A kind left
   unticked goes to the game as an ordinary pad, which still works, but without the
   game's actions in Steam for it, unless its player turns Steam Input on for it.
   Xbox is the one some games leave unticked; ticking it too keeps every controller
   the same.
3. **A build with `steam_input/`** live on `staging`: the Steam workflow's next
   upload. Steam reads the manifest from the depot once the template names it; the
   game hands Steam the same file itself as Steam Input starts, so it works on a
   branch before the template is published as well.
4. **A look on each controller** you have, from `staging`: Steam's controller
   settings for the game should be on "Official Layout for Jackpot Junction -
   Default", with every action of the set "Play" named. Start the build with `++ --pads` in its launch
   options (`%command% ++ --pads`, from a terminal to see what it prints) and push
   each stick all the way up: it prints what Steam said, and Steam's up should be
   "y more". If it says "y less", turn `SteamPads.UP_IS_MORE` off. Steam follows
   the window in front; `steam://forceinputappid/5652730` in a browser holds Steam
   Input on the game while another window has the focus, and
   `steam://forceinputappid/0` lets go. On each controller, too: the back buttons
   of a Deck or a Steam Controller do what A, X, Y and B do; an action moved to
   another button in Steam's settings moves in the game's hints, a back button or
   a trackpad drawn as Steam draws it; the Controls page's Gamepad column reads
   "Gamepad, in Steam" and opens Steam's settings; a DualSense's or DualShock's
   light takes the seat's color in a match and its own back after; and a friend
   joining by Remote Play Together, whose controller Steam always reads through
   Steam Input, takes a seat with Join as a pad of the game's.
5. **A layout made by hand**, should one need more than `SteamActions` writes, a
   radial menu of emotes say: in Big Picture, Settings > System, turn on Developer
   mode, then under Developer "Steam Input Layout Dev Mode"; change the layout in
   Steam's controller settings, export it from the gear menu, and open
   `steam://dumpcontrollerconfig?appid=5652730`, which writes the layout's `.vdf`
   (on Linux into `/tmp`). Keep it in `data/steam/input/` under the controller's
   name, and take that controller out of what `SteamActions.files` writes, or
   `make steam-input` writes over it.

6. **The store page** (Edit Store Page > Basic Info, Controller support), once the
   build reading the controllers through Steam Input is on the default branch: say
   in the controller survey that the game uses the Steam Input API, with full
   support for Xbox, PlayStation and other controllers, as the Controllers line of
   [Basic Info](#basic-info) has it, then publish the store page.

The 2026 Steam Controller's layout is `controller_triton.vdf`, Steam's own name for
it in the client's `controller_base`; Valve's list of controller names for the
manifest does not have it yet.

## Store and library art

`make steam-art` renders every picture Steamworks asks for but the achievements'
into `build/steam-art/`, emptying it first, each named after its field: the
game's own pieces, the Vault and the karts round its Junction, the seal, the
title screen's backdrop, cards, chips and drivers, so they follow the game as it
changes. `scenes/dev/steam_art_export.gd` says where everything stands, sharing
`scenes/dev/key_art.gd` with `make itch-art`; the screenshots come from
`tools/screenshots --steam`. It needs a display, or `GODOT_HIDDEN=1` in front of
it, and takes some minutes.

| File | Where it goes | Size |
|---|---|---|
| `store/header_capsule.png` | Store page, Graphical Assets: Header Capsule | 920 × 430 |
| `store/small_capsule.png` | Small Capsule | 462 × 174 |
| `store/main_capsule.png` | Main Capsule | 1232 × 706 |
| `store/vertical_capsule.png` | Vertical Capsule | 748 × 896 |
| `store/page_background.png` | Page Background | 1438 × 810 |
| `screenshots/*.png` | Screenshots, in the order of their numbers | 1920 × 1080 |
| `library/library_capsule.png` | Library Assets: Library Capsule | 600 × 900 |
| `library/library_header.png` | Library Header | 920 × 430 |
| `library/library_hero.png` | Library Hero | 3840 × 1240 |
| `library/library_logo.png` | Library Logo, placed bottom left | 1280 × 438 |
| `client/app_icon.jpg` | Steamworks settings, Community, Assets: App Icon | 184 × 184 |
| `client/shortcut_icon.png` or `.ico` | Shortcut Icon | 512, or 16 to 256 |
| `client/linux_icons.zip` | Linux Client Icons | 16 to 512 |
| `client/mac_icon.icns` | Mac Icon | 16 to 1024 |
| `event/event_cover.png`, `event_header.png` | Each announcement's cover and header | 800 × 450, 1920 × 622 |
| `community/avatar_*.jpg` | Avatars, where Steamworks takes still ones | 184 × 184 |
| `description/*.png` | The description's headings and pictures | 616 wide |

- **Screenshots**: mark every one suitable for all ages; Steam wants at least four
  so. They are play, but for the kart's bay, the payout slip, the House's
  invitation, the driver's license, the loyalty program and the catalog, the
  game's own screens.
- **Library logo**: its place over the hero is chosen in the preview after the
  upload: bottom left, where the hero leaves a shade for it.
- **Icons**: the seal from 64 pixels up and the foil chip under it, as the game's
  own window and desktop icon. Steam's library list draws an installed game with
  its client icon: the ICO for Windows, the Linux zip for Linux. Without the zip,
  Linux gets the App Icon there, and shortcuts there get no icon at all.
- **App Icon**: Steamworks takes only a JPEG, so it cannot be transparent. As is
  the custom, it is a square of the game's own: the foil chip as big as it goes on
  the engraved stock, since it is seen at 20 pixels. It shows where no client icon
  is installed, and in chat and notifications.
- **Mac Icon**: without it, a macOS shortcut wears Steam's logo. Not needed until
  macOS ships on Steam.
- **Description**: the headings and pictures of ITCH.md's description, also kept
  in `docs/description/`, each uploaded into the description where it stands
  there, with its words as its alt text.
- **Not made**: a bundle's header (707 × 232), only for a bundle; the Points Shop's
  animated avatars, frames, backgrounds and stickers; trading cards, once Steam
  turns them on for the game; and the Steam Deck's startup movie.

## The trailer

The store's trailer, 51 seconds at 60 frames a second, made by `tools/trailer`
from the game itself: each shot played and recorded on its own by Godot's movie
writer at a fixed frame rate, so it comes out the same every run, then cut to
the music's bars with ffmpeg.

- **The shots**: `scenes/dev/trailer.tscn` stages a match for one shot of play,
  `scenes/dev/trailer_posed.tscn` poses the invitation, the bay, the end card
  and the license; `trailer_caption.gd` prints the captions and racks up the run
  of features, and `trailer_drift.gd` scrolls the title's chips and cards over
  the shots. Every shot, its length, scene, arguments and the transition into
  it, is listed in `tools/trailer`. The scenes are left out of every export.
- **The music**: Ovani Sound's Deceased Rodent, which Ovani's terms allow in a
  game's trailer. Its three layers are crossfaded as the game does: the calm one
  muffled under the opening, the tense one on the drop for a bar settling into
  the calm one, the tense one from 14 s, its peak from 26 s, and the calm one
  muffled again under the license. The game's own sound plays quieter under it.
- **Making it**: `make trailer-draft` draws at 1920 × 1080 and writes
  `build/trailer/jackpot-junction-trailer-draft.mp4`. `make trailer` draws at
  7680 × 4320 and scales it down twice: `jackpot-junction-trailer-4k.mp4`,
  3840 × 2160 for YouTube, and `jackpot-junction-trailer.mp4`, 1920 × 1080 for
  the store. That takes about two hours and 21 GB of recordings, a shot at a
  time, as each needs 3 GB of video memory. Shots named after the command are
  the only ones recorded again, `tools/trailer --8k slot license`, and `--cut`
  cuts again from the recordings alone, in about a quarter of an hour.
  `GODOT_HIDDEN=1` in front records without a window.
- **Uploading**: Valve takes up to 1920 × 1080 at 30 or 60 frames a second,
  H.264 and AAC in an .mp4. The first trailer should be mostly play with the HUD
  shown, and must work muted: the captions carry it. Its thumbnail is a
  1920 × 1080 frame of it with no text. Steam cuts its 6-second microtrailer
  from it.

## Words for the store page

Everything Steamworks asks for in words, under Edit Store Page, written once here
so the store page, itch.io's and the game say the same things. ITCH.md's words
are the source, its numbers too: when a release adds jokers, power-ups or dress,
they change in both. Steam takes no links to
other sites in the description or in its pictures, not even a domain spelled
out: the links go in Basic Info's fields.

### Basic Info

| Field | What to put |
|---|---|
| Name | Jackpot Junction |
| Developer, publisher | timvisee, as on itch.io and GitHub |
| Supported languages | English: interface only, since nothing is voiced or subtitled |
| Platforms | Windows, and SteamOS + Linux; macOS once it is on Steam, see [Builds](#builds) |
| Controllers | Full controller support: Xbox and PlayStation controllers, and every other controller through Steam Input, with the game's actions named in Steam's controller settings; if the controller questions ask whether the game uses the Steam Input API, it does |
| Genres | Action, Casual, Indie, Free to Play |
| Website | `https://github.com/timvisee/jackpot-junction` |
| Support | The repository's issues: `https://github.com/timvisee/jackpot-junction/issues` |
| Release | A full release, not Early Access |

**Features**, the boxes Steam shows down the side of the page:
Single-player, Online PvP, LAN PvP, Shared/Split Screen PvP, Online Co-op, LAN
Co-op, Shared/Split Screen Co-op, Cross-Platform Multiplayer, Remote Play
Together, Steam Achievements, Steam Cloud, Stats, and Full controller support.
The co-op boxes are for teams, friends on one side against the bots. Cross-platform
because a Steam build plays with the GitHub, itch.io and Android builds over a
server or LAN. Remote Play Together suits a game four play at one screen: one
owner hosts and the others join from their own Steam, the game none the wiser.

**Tags**, set in the Tag Wizard, the most telling first: Steam weighs them in
this order, shows the first twenty, and filters some lists by the first fifteen.

1. Vehicular Combat
2. Party Game
3. Arena Shooter
4. Local Multiplayer
5. Top-Down Shooter
6. Free to Play
7. Online PvP
8. Arcade
9. 4 Player Local
10. Team-Based
11. Driving
12. Top-Down
13. Cartoony
14. Colorful
15. Funny
16. Fast-Paced
17. Controller
18. Casual
19. Indie
20. Multiplayer

### Short description

Plain text, a few hundred characters at most, shown beside the header capsule:

> A top-down kart arena where every life is a hand of cards. Scoop up poker chips,
> knock out the other karts, bend the rules with jokers and cash out at the
> Junction before somebody takes you down. Up to four at one screen, eight online.

### About This Game

ITCH.md's description in Steam's own markup, its headings and pictures those of
`docs/description/`. Upload the seven pictures first, with the editor's image
button: Steam writes each in as `[img]{STEAM_APP_IMAGE}/extras/` and its file's
name, which is what stands below; check the first it writes matches before
pasting the rest. Give each its alt text in the Description tab, the words ITCH.md
has for it:

| Picture | Alt text |
|---|---|
| `heading_how_the_cards_roll.png` | How the cards roll |
| `heading_whats_in_the_deck.png` | What's in the deck, you ask? |
| `picture_jokers.png` | A hand of five jokers: Loaded Dice, Curve Ball, Pickpocket, Guardian Angel and Wild Card |
| `picture_power_ups.png` | A hand of five power-ups: Rocket, Shield, Bomb, Turret and Decoy Kart |
| `heading_never_play_alone.png` | You never play cards alone. Or do you? |
| `heading_your_ride.png` | Your ride, your way |
| `picture_karts.png` | Five karts in a line, each in a body, paint and hat of its own |

```text
[b]Did someone say chaos?[/b] Drift, dodge bullets and scoop poker chips like your rent depends on it while trying not to turn into roadkill. Grab your license, hop in your tuned kart, and challenge up to seven friends to see who can make the biggest payday. Die before cashing in and you'll lose bank. Easy, right? Yeah, good luck with that.

[img]{STEAM_APP_IMAGE}/extras/heading_how_the_cards_roll.png[/img]
[list]
[*][b]Collect[/b] chips from the pads, crates, the Jackpot and the karts you knock out. Every chip goes in your pot.
[*][b]Multiply[/b] by taking out your fellow karts. Your pot is worth its chips times its mult.
[*][b]Bend the rules[/b] with jokers that twist the game. Go down and get lucky, or cursed... who knows.
[*][b]Cash out[/b] by driving your kart onto the junction. Die on the way and lose all your hard work.
[/list]

[img]{STEAM_APP_IMAGE}/extras/heading_whats_in_the_deck.png[/img]
[img]{STEAM_APP_IMAGE}/extras/picture_jokers.png[/img]
[img]{STEAM_APP_IMAGE}/extras/picture_power_ups.png[/img]
[list]
[*]Casino tables are your arena. Drift around obstacles, fall into potholes and collect poker chips to win.
[*]48 jokers. Think curveballs, drifting chips, bouncing bullets, and pick-pocketing. You'll get 27 jokers on The House and win the rest on the road.
[*]21 power-ups. Shields, bombs, turrets, decoys, oil stains and more to mess with your friend's kart like your life depends on it (it does).
[*]One minute or the full shebang: there are quick matches and Grand Prix runs of several maps. Every kart for itself or in teams that bank one score together.
[*]Your own, personalized kart. From shark fin hats to confetti trails and a license plate with your name on it.
[*]Loyalty pays off. Just like your road map of bets getting you kart cosmetics or cards for your joker deck.
[*]New here? We'll show you around. Get your license at the driving school and practice your drifting skills at the garage.
[*]A storyline along the way letting you optimize your kart and card experience. Feel free to turn it off if it's holding you up.
[/list]

[img]{STEAM_APP_IMAGE}/extras/heading_never_play_alone.png[/img]
[list]
[*][b]Got one screen?[/b] Hit the road with up to four friends, joining whenever they like. Yes, even mid-match.
[*][b]LANning?[/b] Host your own game and invite your friends, your way.
[*][b]Playing online?[/b] Quick Play drops you into a public game near you, or starts one with bots that make way for people as they join. Or host for your Steam friends, up to eight reckless drivers.
[/list]

[img]{STEAM_APP_IMAGE}/extras/heading_your_ride.png[/img]
[img]{STEAM_APP_IMAGE}/extras/picture_karts.png[/img]
Whether you're not impressed by the disco crowd on the sideline or playing with that one friend needing aim assist: the game can be tuned to your needs.

Jackpot Junction is open source, under the GPL-3.0, made with Godot. Its own art is CC BY 4.0.
```

### System requirements

Under Basic Info, for Windows and for SteamOS + Linux, "Requires a 64-bit
processor and operating system" ticked for both. Worked out from what Godot 4.7
needs of an exported game and what the game was seen to use: 1.5 GB of memory
with eight karts at 1080p, about 135 MB installed on Windows and 100 MB on Linux.
None of it was tried on a slow machine: a Steam Deck or an older laptop playing a
full match of eight is the test of the minimum.

| Field | Minimum | Recommended |
|---|---|---|
| OS, Windows | Windows 10 64-bit | Windows 10 or 11 64-bit |
| OS, Linux | Ubuntu 22.04 64-bit or the like, SteamOS 3 | Ubuntu 24.04 64-bit or the like, SteamOS 3 |
| Processor | Dual-core x86-64 with SSE4.2, 2.5 GHz (Intel Core i3-4130, AMD FX-4300) | Quad-core, 3 GHz (Intel Core i5-6500, AMD Ryzen 3 1200) |
| Memory | 4 GB RAM | 8 GB RAM |
| Graphics, Windows | Direct3D 12 at feature level 12_0, or Vulkan 1.0 (Intel UHD Graphics 620, AMD Radeon Vega 8, NVIDIA GeForce GTX 950) | NVIDIA GeForce GTX 1050 Ti, AMD Radeon RX 570 or better |
| Graphics, Linux | Vulkan 1.0, Mesa or NVIDIA's driver, the same cards | The same as Windows |
| DirectX, Windows | Version 12 | Version 12 |
| Network | Broadband Internet connection | Broadband Internet connection |
| Storage | 500 MB available space | 500 MB available space |

Additional notes, the same for both:

> An Internet connection is only needed for online play; single-player against
> bots, local play and LAN games work offline. Up to 4 players on one screen with
> controllers, up to 8 online. Lower the render scale and shadows in Settings on
> integrated graphics.

### Content and legal

- **Content survey**: no nudity, no sexual content, nothing for adults only. The
  violence is a cartoon's: karts shot, bombed and knocked out, nobody hurt, no
  blood. Simulated gambling, yes: casino tables, chips and slot machines, though
  nothing is ever staked, real or in the game.
- **AI disclosure**: pre-generated content, yes; live-generated, none, since
  nothing is generated while playing. The description Steam shows with it: "This game is built by generative AI, with some assistance from a human. AI wrote the code and the in-game text, and the art is drawn by that code, so no image, voice or music generators were used. The music, sound effects and fonts are made by people."
- **Legal notice**, the store page's own line: "Jackpot Junction is free software
  under the GPL-3.0, with an additional permission to link the Steamworks SDK. Its
  own art is CC BY 4.0. Music by Ovani Sound, licensed to the game's developer.
  Third-party assets are listed in the game's credits."

## The supporter pack

The supporter pack, GAME.md 10.8, is a DLC of the app: a purchase that lets its pieces be worn,
with nothing to download, since they are in every build already. The game asks Steam at every start
whether the account owns it, and again whenever a DLC is installed or the overlay closes, so one
bought in the overlay unlocks at once. A build that names no DLC offers none of it. To put it up:

1. **Make it** (the app's page, All Associated Packages, DLC, Demos and Tools: Add New DLC), named
   as in the words below. Steamworks gives it an app id of its own: the supporter pack is app
   5680650, made on 2026-11-22.
2. **No depot.** The DLC holds no files: for a DLC without content, Steam's answer to whether it
   is installed is whether the account owns it, which is all the game asks.
3. **Price**: about a euro or two, on the DLC's store package. Valve looks prices over before they
   go live.
4. **Store page** (the DLC's own Edit Store Page): the words and the pictures below. Steam reviews
   the page before the DLC can be released.
5. **The id in the build**: set the repository variable `STEAM_SUPPORTER_DLC` to the DLC's app id.
   The Steam workflow writes it into the build's `data/steam/app.cfg`, and from that build on the
   pack is offered. For a build by hand, `make steam-export STEAM_APP_ID=5652730
   STEAM_SUPPORTER_DLC=5680650`.
6. **Trying it**, once the store page has gone in for review, as Steamworks wants before the DLC
   can go in a package: add the DLC to the Developer Comp package, under Apps Included (Depots
   Included is for depots, which it has none of), so the team's accounts own it, and start a Steam
   build: the pieces are worn, and the thank-you card comes on the title. An account
   without it sees them locked on the kart dialog's rack, and the pack offered on a flyer in the
   bay, on the Me page and on the About page; picking a locked piece or any of those opens the
   DLC's page in the overlay, and buying it there unlocks them in place, the flyer turning into the
   card and the thank-you card coming up at once over the menu that is open. `++ --supporter` and `++ --supporter=locked`
   show both in a debug build without Steam.
7. **Release** it by hand on its Steamworks page once its store page is approved, on the game's
   release day or any day after.

### Its pictures

`make steam-supporter-art`, which `make steam-art` runs after the game's, renders the DLC's own
into `build/steam-art/supporter/`, apart from the game's: the same table and karts as the game's
capsules, every kart in the pack's pieces, the seal with the pack's name under it between two of
its star pins. `scenes/dev/supporter_art_export.gd` says where everything stands, and
`scenes/dev/supporter_art.gd` what the karts wear; the screenshots come from
`tools/screenshots --supporter`.

| File | Where it goes | Size |
|---|---|---|
| `store/header_capsule.png` | Store page, Graphical Assets: Header Capsule | 920 × 430 |
| `store/small_capsule.png` | Small Capsule | 462 × 174 |
| `store/main_capsule.png` | Main Capsule | 1232 × 706 |
| `store/vertical_capsule.png` | Vertical Capsule | 748 × 896 |
| `screenshots/*.png` | Screenshots, in the order of their numbers | 1920 × 1080 |
| `description/*.png` | The description's headings and pictures | 616 wide |

- **Screenshots**: the pack's karts round the Junction and three karts in its hats of character,
  close up, drawn as the capsules are, since at a match's own zoom the pieces cannot be told apart;
  then the game's own screens: the hat rack with the pack's pieces, the card back rack with Beacon
  tried, and the license with the endorsement. Never the thank-you card, which a player who bought
  the pack is to find for themselves on the title. Mark every one suitable for all ages.
  `++ --dress=supporter` on the playground puts every kart in the pack's pieces, to see them in
  play.
- **Description**: two headings, a row of five karts in the pack's pieces and a hand of its three
  card backs, also kept in `docs/description/supporter/`, each uploaded into the description where
  it stands below, with its alt text from the table under it.

| Picture | Alt text |
|---|---|
| `heading_supporter_thanks.png` | A thank-you you can wear |
| `picture_supporter_karts.png` | Five karts wearing the house of cards, the lucky cat, the lighthouse with its beam, the halo and the tip jar, with lanterns, pinwheels and the night sky paint |
| `heading_supporter_pieces.png` | Everything in the pack |
| `picture_supporter_backs.png` | A hand of three cards showing the Beacon, Constellation and Aurora card backs |

### Words for its store page

| Field | What to put |
|---|---|
| Name | Jackpot Junction - Supporter Pack |
| Type | DLC, cosmetic only |

Neither description names the thank-you card, which a player who bought the pack is to find for
themselves on the title.

Short description:

> A small thank-you for a free game. Eleven pieces of kart dress that glow, spin and answer to
> your pot, three card backs and a star for your license plate. Nothing that wins a match: just a
> way to show you chipped in.

About This Content, in Steam's own markup, its pictures uploaded first as the game's are, see
About This Game above:

```text
Jackpot Junction is free, and stays free. The Supporter Pack is for those who would like to give something back, and to show it at the table.

[img]{STEAM_APP_IMAGE}/extras/heading_supporter_thanks.png[/img]
[img]{STEAM_APP_IMAGE}/extras/picture_supporter_karts.png[/img]
Every piece glows, spins or answers to your pot, so the table can see who chipped in. A house of cards that grows with your pot and falls when you do, a lucky cat that beckons faster after chips, a lighthouse that sweeps the felt.

[img]{STEAM_APP_IMAGE}/extras/heading_supporter_pieces.png[/img]
[img]{STEAM_APP_IMAGE}/extras/picture_supporter_backs.png[/img]
[list]
[*][b]Lighthouse[/b] (hat): its lamp turns and sweeps a soft beam over the felt.
[*][b]Halo[/b] (hat): a ring of warm light over your helmet.
[*][b]House of cards[/b] (hat): a storey more as your pot grows; it wobbles as you drive and falls when you do.
[*][b]Lucky cat[/b] (hat): it beckons, faster after you pick up chips, and cheers when you cash out.
[*][b]Tip jar[/b] (hat): fills with chips as your pot grows.
[*][b]Lantern[/b] (flag): a paper lantern glowing in your color.
[*][b]Pinwheel[/b] (flag): spins with your speed.
[*][b]Prism[/b] (trail): a ribbon of light that leaves rainbow arcs in a drift.
[*][b]Stardust[/b] (trail): twinkles that hang where you have been.
[*][b]Night sky[/b] (paint): your color as a starry night sky.
[*][b]Starlight[/b] (finish): drifting stars, for any piece you wear.
[*][b]Beacon[/b], [b]Constellation[/b] and [b]Aurora[/b] (card backs) for your joker deck.
[*][b]A star[/b] for your license plate and a [b]Supporter[/b] endorsement on your driver's license.
[/list]

Everything in it is for looks. It changes nothing about how a match is played or won, and every joker, power-up and arena stays free for everyone.
```

## Testing with app 480

- `make steam-addon` once, then `make steam-run`, or `make steam-check` to see what
  the Steam client answers. Steam has to be running and logged in.
- The game always tells Steam which app it is, so a game run from an editor that
  Steam itself started (Godot is app 404790 there) is not taken for the editor.
- Steam's overlay seldom comes up over a game run from the editor: try invites
  from an export, `make steam-export`, started with Steam running.
- Steam's keyboard on the screen, GAME.md 10.8, comes up only on Steam's own hardware
  or with Steam in Big Picture, and it is drawn by the overlay, so the game has to be
  started by Steam: an export added to the library as a non-Steam game will do. On a
  Steam Deck, try it in gaming mode with the Deck's own controls and its screen;
  `make steam-check` says whether the machine is one where it comes up.
