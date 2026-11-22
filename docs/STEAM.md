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
   itch.io keep their macOS build. The Linux ARM64 build is made and kept but not
   uploaded. There is no Windows ARM64 build: neither GodotSteam nor Valve's SDK
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
  turns them on for the game; the Steam Deck's startup movie; and a trailer.

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
| Controllers | Full controller support: Xbox and PlayStation controllers, which the game reads itself rather than through Steam Input, the buttons named as Xbox names them |
| Genres | Action, Casual, Indie, Racing, Free to Play |
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
12. Racing
13. Top-Down
14. Cartoony
15. Colorful
16. Funny
17. Fast-Paced
18. Controller
19. Casual
20. Indie

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
[b]Did someone say chaos?[/b] Drift, dodge bullets and scoop poker chips like your rent depends on it while trying not to turn into roadkill. Grab your license, hop in your tuned kart, and challenge up to eight friends to see who can make the biggest payday. Die before cashing in and you'll lose bank. Easy, right? Yeah, good luck with that.

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
[*]One minute or the full shabang: there's quick matches and grand prixes of several maps. Every kart for itself or in teams that bank one score together.
[*]Your own, personalized kart. From shark fin hats to confetti trails and a license plate with your name on it.
[*]Loyalty pays off. Just like your road map of bets getting you kart cosmetics or cards for your joker deck.
[*]New here? We'll show you around. Get your license at the driving school and practice your drifting skills at the garage.
[*]A storyline along the way letting you optimize your kart and card experience. Feel free to turn it off if it's holding you up.
[/list]

[img]{STEAM_APP_IMAGE}/extras/heading_never_play_alone.png[/img]
[list]
[*][b]Got one screen?[/b] Hit the road with up to four friends, joining whenever they like. Yes, even mid-match.
[*][b]LANning?[/b] Host your own game and invite your friends, your way.
[*][b]Playing online?[/b] Either make a dedicated server game or join an existing one with up to eight reckless drivers.
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
  nothing is generated while playing. The description Steam shows with it: "This
  game is fully built by generative AI, with some assistance of a human."
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
   can go in a package: add the DLC to the Developer Comp package, so the team's accounts own it,
   and start a Steam build: the pieces are worn, and the thank-you card comes on the title. An account
   without it sees them locked on the kart dialog's rack, picking one opens the DLC's page in the
   overlay, and buying it there unlocks them in place. `++ --supporter` and `++ --supporter=locked`
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
