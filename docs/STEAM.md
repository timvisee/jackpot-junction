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

To be filled in with M19's S6.

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

To be filled in with M19's S2.

## Rich presence

To be filled in with M19's S3.

## Testing with app 480

- `make steam-addon` once, then `make steam-run`, or `make steam-check` to see what
  the Steam client answers. Steam has to be running and logged in.
- The game always tells Steam which app it is, so a game run from an editor that
  Steam itself started (Godot is app 404790 there) is not taken for the editor.
- Steam's overlay seldom comes up over a game run from the editor: try invites
  from an export, `make steam-export`, started with Steam running.
