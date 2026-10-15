# Steam

Everything to set up on [Steamworks](https://partner.steamgames.com) for the
Steam builds of GAME.md 10.8, once the game has an app of its own. Until then the
game plays as Spacewar, app 480, and none of this is needed. Each part says what
in the repository it goes with.

## The app

1. Pay the Steam Direct fee for an app (100 US dollars, paid back once the game has
   made 1,000 on Steam) and wait for it to be set up.
2. Set the repository variable `STEAM_APP_ID` to its id (Settings > Secrets and
   variables > Actions > Variables). From then on `.github/workflows/steam.yml`
   uploads every tag, see [Builds](#builds).
3. Under Installation > General, turn on "Use launch command line", so a friend's
   game Steam starts for an invite or a Join game reaches the game.

## Builds

`.github/workflows/steam.yml` makes the Steam builds on every `v*` tag, and by hand
from the Actions tab for any branch or tag. Until `STEAM_APP_ID` is set it only
keeps them, as the run's artifact for 30 days, made as Spacewar. With it set, it
uploads them with [game-ci/steam-deploy](https://github.com/game-ci/steam-deploy)
and sets the build live on the beta branch `staging`, or the branch a run by hand
names. Making a build the one everybody gets, on the default branch, is done by
hand on Steamworks: Steam does not let a script do it.

1. **Depots** (SteamPipe > Depots), one per platform, at the app's id plus:

   | Depot | Platform | Folder in the build | Launch option, executable |
   |---|---|---|---|
   | +1 | Windows, 64-bit | `windows` | `jackpot-junction.exe` |
   | +2 | Linux + SteamOS | `linux` | `jackpot-junction` |
   | +3 | macOS | `macos` | `Jackpot Junction.app` |
   | +4 | Linux, ARM64 | `linux-arm64` | `jackpot-junction` |

   Depot 4 is uploaded only with the repository variable `STEAM_LINUX_ARM64` set to
   `true`, once Steamworks has a depot and a launch option for ARM64 Linux; until
   then ARM machines play the x86_64 build as Steam runs it. There is no Windows
   ARM64 build: neither GodotSteam nor Valve's SDK has a library for it.
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

Linux needs its own path because Godot's folder there is `godot` in lowercase. Only
`*.cfg` goes: the `.bak` beside each profile stays on the machine it was written on.

## Achievements

`make achievement-art` writes everything Steamworks asks for into
`build/achievements/`: `achievements.txt` to read, `achievements.csv` to work
from, and the pictures. Under Stats & Achievements:

1. **Stats** first, one per row of the table with a `steam_stat` (seven): type INT,
   API name as given, "Set By" Client, min 0, max the row's `bar`, "Increment only"
   on, so a profile with less never takes anything away, GAME.md 8.10.
2. **Achievements**, one per row (51): API name `store_name`, display name `name`,
   description `objective`, Hidden for the four whose `hidden` is yes. Achieved
   icon `256/<id>.png`, unachieved `256/<id>_locked.png`. For a row with a
   `steam_stat`, set it as the progress stat, from 0 to the row's `bar`.
3. Publish the changes.

A bar's target grows with the game: when a release adds jokers, power-ups or
dress, the table's `bar` changes, and so must the stat's max and the
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
