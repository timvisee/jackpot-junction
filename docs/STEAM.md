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
