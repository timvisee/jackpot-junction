# Steam

Everything to set up on [Steamworks](https://partner.steamgames.com) for the
Steam builds of GAME.md 10.8, once the game has an app of its own. Until then the
game plays as Spacewar, app 480, and none of this is needed. Each part says what
in the repository it goes with.

## The app

The game's app is 5652730, made free: its store package, priced free, is the one
players get, and never shows on the store.

1. Set the repository variable `STEAM_APP_ID` to `5652730` (Settings > Secrets and
   variables > Actions > Variables). From then on `.github/workflows/steam.yml`
   uploads every tag, see [Builds](#builds).

## Builds

`.github/workflows/steam.yml` makes the Steam builds on every `v*` tag, and by hand
from the Actions tab for any branch or tag. Until `STEAM_APP_ID` is set it only
keeps them, as the run's artifact for 7 days, made as Spacewar. With it set, it
uploads them with [game-ci/steam-deploy](https://github.com/game-ci/steam-deploy)
and sets the build live on the beta branch `staging`, or the branch a run by hand
names. Making a build the one everybody gets, on the default branch, is done by
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
   itch.io keep their macOS build. The Linux ARM64 build is made and kept but not
   uploaded. There is no Windows ARM64 build: neither GodotSteam nor Valve's SDK
   has a library for it.
2. **Branches** (SteamPipe > Builds): add the beta branch `staging`, with a password
   if only testers should see it.
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

## Linux ARM64, after the first release

Planned for once the game has been released on Steam once, PLAN.md M19's S10.
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

**The depot.** Linux's, 5652732, holds the launcher and a folder per CPU, each a
whole export. They cannot share a folder: both carry a `libsteam_api.so` of the
same name, which each binary finds beside itself.

```text
jackpot-junction             the launcher, still the launch option
x86_64/jackpot-junction      with libgodotsteam.linux.template_release.x86_64.so and libsteam_api.so
arm64/jackpot-junction       with libgodotsteam.linux.template_release.arm64.so and libsteam_api.so
```

**The launcher**, kept in the repository and copied in by `make steam-export`:

```sh
#!/bin/sh
# Starts the build for this machine's CPU, handing on Steam's arguments.
here="$(dirname "$(readlink -f "$0")")"
case "$(uname -m)" in
aarch64 | arm64) exec "$here/arm64/jackpot-junction" "$@" ;;
*) exec "$here/x86_64/jackpot-junction" "$@" ;;
esac
```

`"$@"` hands on what Steam passes, `+connect_lobby <id>` for a friend's game among
it. Nothing else changes for the game: its saves go by the game's name, not the
binary's folder, and the only code that starts the binary again, the server hall,
is never in a Steam build.

**In the repository:**

1. `make steam-export` exports "Linux Steam" into `build/steam/linux/x86_64/` and
   "Linux ARM64 Steam" into `build/steam/linux/arm64/`, copies the launcher in as
   `build/steam/linux/jackpot-junction`, executable, and stops making
   `build/steam/linux-arm64/`.
2. `steam.yml` checks for both `libsteam_api.so` files and the launcher, and
   uploads `linux` as before; nothing else of the upload changes.
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
Steam Frame. Outside Steam, `arm64/jackpot-junction --no-steam` runs on any ARM64
Linux machine, a Raspberry Pi 5 for one. Put the first one on `staging` before
setting it live, as Factorio put theirs on its experimental branch first.

**The cost.** Each binary carries the game's data, so Linux players download about
twice as much, some 200 MB rather than 100; Windows is unchanged. A shared `.pck`
beside the launcher, handed to the binary with `--main-pack`, would save the second
copy of the data, but only once the plain way has been seen to work.

## Steam Cloud

The profiles go to Steam Cloud, the settings stay with each machine. A Steam build
keeps both in a folder of the account's own, `steam/<SteamID64>/` in Godot's user
folder for the game, so the rule names the account with `{64BitSteamID}`. Under
App Admin > Cloud:

- Byte quota per user: 1048576 (a profile is a few kilobytes, at most 8 of them).
- Number of files allowed per user: 16.
- Enable Auto-Cloud: one root path, and two root overrides.

| Root | Subdirectory | Pattern | OS | Recursive |
|---|---|---|---|---|
| `WinAppDataRoaming` | `Godot/app_userdata/Jackpot Junction/steam/{64BitSteamID}/profiles` | `*.cfg` | All | No |

| Original root | OS | New root | Add/replace path | Replace path |
|---|---|---|---|---|
| `WinAppDataRoaming` | macOS | `MacAppSupport` | | No |
| `WinAppDataRoaming` | Linux + SteamOS | `LinuxXdgDataHome` | `godot/app_userdata/Jackpot Junction/steam/{64BitSteamID}/profiles` | Yes |

The macOS override is there for the Mac build, once Steam has one. Linux needs its
own path because Godot's folder there is `godot` in lowercase. Only
`*.cfg` goes: the `.bak` beside each profile stays on the machine it was written on.

## Achievements

`make steam-achievement-art STEAM_APP_ID=<the app's id>` writes everything for
Steamworks' Bulk Import/Export into `build/steam-achievements/`, emptying it
first:

- `<app>-achievements-definitions.csv` and `<app>-achievements-localization.csv`,
  written as Steam's own export writes them: every achievement by its API name, a
  spoiler when hidden, set by the client, and each bar's statistic with its range;
  then its English name and description.
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

A bar's target grows with the game: when a release adds jokers, power-ups or
dress, run `make steam-achievement-art` again. Raise the stat's max by hand to
what `stats.txt` now says, then import the new definitions, which carry the
achievement's progress range. A debug build with the app's own id says at start
which names Steam and the game do not share. "Clear Steam's" on the Debug tab
takes everything back on the account, for trying it again.

## Rich presence

Under Community > Rich Presence, upload `docs/steam/rich_presence.vdf` (UTF-8) and
publish. It holds the words for every token the game sets, GAME.md 10.8, and a
test holds it to the game: a new map needs its `#Map_<id>` line. Check what an
account says at https://steamcommunity.com/dev/testrichpresence while it plays.
Under app 480 nothing of ours can be uploaded, so the friends list shows nothing
of it, but the test page still lists the keys.

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
