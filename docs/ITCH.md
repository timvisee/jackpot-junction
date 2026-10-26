# itch.io

What the game's page on [itch.io](https://timvisee.itch.io/jackpot-junction) needs
for the release workflow to publish every release there as well, GAME.md 10.5.
Until it has it, releases go to GitHub and Docker Hub only, and nothing fails.

## Turning it on

Set two repository secrets (Settings > Secrets and variables > Actions):

- `ITCH_GAME`: the page, as `user/game`: `timvisee/jackpot-junction`.
- `ITCH_BUTLER_API_KEY`: an API key of the account that owns the page, made under
  Settings > API keys on itch.io. It can do anything the account can, so it is
  kept nowhere else; a key that leaks is revoked there and made again.

From then on `.github/workflows/release.yml` pushes every tag GitHub marks the
latest release to the page with `tools/itch`, after the GitHub release. A
pre-release is never pushed, and nor is a fix to an older version published
after a newer one: each download on the page holds one build, and that would put
the older one back over the newer.

## The downloads

Each file of a release goes to a channel of its own, which is one download on the
page. butler unpacks the zips, so the itch app installs the game and patches it
from one version to the next; the website still hands out a zip. Each download
says the release's version.

| # | Name to give it | Channel | Platform | From the release |
|---|---|---|---|---|
| 1 | Jackpot Junction for Linux (x86_64) | `linux` | Linux | `…-linux.zip` |
| 2 | Jackpot Junction for Linux (ARM64) | `linux-arm64` | Linux | `…-linux-arm64.zip` |
| 3 | Jackpot Junction for macOS | `mac` | macOS | `…-macos.zip` |
| 4 | Jackpot Junction for Windows | `windows` | Windows | `…-windows.zip` |
| 5 | Jackpot Junction for Android | `android` | Android | `…-android.apk` |
| 6 | Dedicated server for Linux (x86_64) | `server-x86_64` | none | `…-linux-server.zip` |
| 7 | Dedicated server for Linux (ARM64) | `server-arm64` | none | `…-linux-server-arm64.zip` |

itch.io tags a download's platform from its channel's name, once, as the channel
is made: `win`, `linux`, `mac` or `android` in it. It has no tag for an
architecture and no icons of its own, so the two Linux builds both show the
Linux icon and their names tell them apart. The servers are tagged nothing, so
the itch app never installs one as the game.

## After the first push

A channel's download goes at the foot of the list the first time something is
pushed to it, and `tools/itch` pushes them in the order of the table. Once, on
the page's Edit game screen, under Uploads:

1. Delete the files uploaded by hand before: butler cannot take them over.
2. Check the order is the table's, and drag it there if not.
3. Give each download its name from the table (the pencil beside it, Display
   name), and check its platforms: the two Linux builds Linux only, the servers
   nothing.
4. Download the Android build from the page once, to check it comes as an APK.

butler never touches a name, a tag or the order again: every release after
replaces the files and leaves the rest as it is.

## The page's look

The page wears the game's own look, House Print, GAME.md 8.1a: the house's dark
stock and its gold foil, the buttons foil with dark words as the game's button
that moves things on is. Set under Edit theme on the page:

| Setting | Value | What it is |
|---|---|---|
| Background color | `#131218` | the house's stock |
| Background image | `build/itch/background.jpg`: not repeated, centered at the top, fixed | what is behind the title screen, its sunburst fanning out round the top of the column |
| Inner background (BG2) | `#1b1a22`, about 95% opaque | the stock raised, the column the page is read on |
| Text | `#ebe8f0` | the house's words |
| Links | `#f2c14e` | the foil |
| Headers | `#f2c14e` | the foil, as the game's own headings |
| Buttons | `#f2c14e` | the foil of the game's main button; check its words come out dark |
| Borders | `#37343f` | the house's rule |
| Header font | Barlow Condensed | the game's display cut, on Google Fonts |
| Body font | Barlow | the game's own text |
| Banner | `assets/logo/banner.png` | the seal and the name, 952 pixels across for the 960 of the column; it stands in for the page's title |

The cover is `build/itch/cover.png`, 630 by 500, under Edit game, Cover image:
the Vault with three karts drifting round its Junction, the seal and the name
over it. The screenshots are the README's, `docs/screenshots/`.

`make itch-art` renders the cover and the background from the game itself, the
arena, its room, the karts, the seal and the title's sunburst, so they follow the
game as it changes; `scenes/dev/itch_export.gd` says where everything stands. It
needs a display, or `GODOT_HIDDEN=1` in front of it to run in the background.

The theme editor gives a button its color and nothing else: itch.io's own shape,
a box with round corners. `docs/itch-buttons.css` cuts them as the game's own,
tickets of foil with their corners notched, a hairline inside the edge, and the
lane chevron under the cursor. It takes custom CSS, which itch.io turns on for an
account only when asked, through its support, saying what the theme editor
cannot do and that the changes stay inside the page. Once it is on, the file goes
into the page's CSS as it is. It reaches the buttons as `#wrapper .button`;
check that is still what itch.io's own CSS guide names them.

## Words for the page

Everything itch.io asks for under Edit game, written once here so the page and
the game say the same things. The numbers are the game's own as of 0.21.0: when
a release adds jokers, power-ups or dress, the counts here change with it.

### The fields

| Field | What to put |
|---|---|
| Title | Jackpot Junction |
| Project URL | `timvisee.itch.io/jackpot-junction` |
| Classification | Games |
| Kind of project | Downloadable |
| Release status | In development, while the version is 0.x |
| Pricing | Your choice: No payments, or $0 or donate |
| Genre | Action |
| Tags | `kart`, `arcade`, `local-multiplayer`, `multiplayer`, `top-down`, `shooter`, `casino`, `cards`, `party-game`, `godot` |
| AI generation disclosure | Yours to answer: itch.io asks whether the project holds content made with generative AI, and the commit history credits Claude on code and documentation |
| Custom noun | Leave it: "game" |
| Community | Comments |
| Visibility | Public, once the first push is checked, see [After the first push](#after-the-first-push) |

Under Metadata, where itch.io has them:

| Field | What to put |
|---|---|
| Platforms | Windows, macOS, Linux, Android: the downloads tag themselves, see [The downloads](#the-downloads) |
| Made with | Godot, Blender |
| Inputs | Keyboard, Mouse, Xbox controller, Playstation controller, Touchscreen |
| Accessibility | Color-blind friendly, Configurable controls, Interactive tutorial |
| Multiplayer | Local multiplayer, Ad-hoc networked multiplayer, Server-based networked multiplayer |
| Player count | 1 to 4 at one screen, up to 8 online |
| Average session | A few minutes: a map is five, a Grand Prix several |
| Languages | English |
| Links | Source code: `https://github.com/timvisee/jackpot-junction`; the server's Docker image: `https://hub.docker.com/r/timvisee/jackpot-junction-server` |

### Short description

Shown under the title wherever the game is listed. One of:

> Push your luck in a bullet-filled kart arena. Every life is a hand of cards.

> Drift, grab chips, and cash out before somebody shoots you.

> A top-down arena kart game where you bank your pot or lose half of it.

### Description

The page's main text. Pasted from this file as GitHub shows it, it keeps its
headings and lists.

---

**Did someone say chaos?** Drift, dodge bullets and scoop poker chips like your
rent depends on it while trying not to turn into roadkill. Grab your license, hop
in your tuned kart, and challenge up to eight friends to see who can make the
biggest payday. Die before cashing in and you'll lose bank. Easy, right? Yeah,
good luck with that.

**How the cards roll**

- **Collect** chips from the pads, crates, the Jackpot and the karts you knock
  out. Every chip goes in your pot.
- **Multiply** by taking out your fellow karts. Your pot is worth its chips times
  its mult.
- **Bend the rules** with jokers that twist the game. Go down and get lucky, or
  cursed... who knows.
- **Cash out** by driving your kart onto the junction. Die on the way and lose
  all your hard work.

**What's in the deck, you ask?**

- Casino tables are your arena. Drift around obstacles, fall into potholes and
  collect poker chips to win.
- 48 jokers. Think curveballs, drifting chips, bouncing bullets, and
  pick-pocketing. You'll get 27 jokers on The House and win the rest on the road.
- 21 power-ups. Shields, bombs, turrets, decoys, oil stains and more to mess with
  your friend's kart like your life depends on it (it does).
- One minute or the full shabang: there's quick matches and grand prixes of
  several maps. Every kart for itself or in teams that bank one score together.
- Your own, personalized kart. From shark fin hats to confetti trails and a
  license plate with your name on it.
- Loyalty pays off. Just like your road map of bets getting you kart cosmetics or
  cards for your joker deck.
- New here? We'll show you around. Get your license at the driving school and
  practice your drifting skills at the garage.
- A storyline along the way letting you optimize your kart and card experience.
  Feel free to turn it off if it's holding you up.

**You never play cards alone. Or do you?**

- **Got one screen?** Hit the road with up to four friends, joining whenever they
  like. Yes, even mid-match.
- **LANning?** Host your own game and invite your friends, your way.
- **Playing online?** Either make a dedicated server game or join an existing one
  with up to eight reckless drivers.

**Your ride, your way.**
Whether you're not impressed by the disco crowd on the sideline or playing with
that one friend needing aim assist: the game can be tuned to your needs.

Jackpot Junction is open source, under the GPL-3.0, made with Godot. Its own art
is CC BY 4.0.

---

### Installing

For the description's foot, or the page's install instructions where itch.io
offers a field for them. The same as the README's.

---

**The itch app** installs the game and keeps it up to date: open it, find
Jackpot Junction and press Install.

**Or download it** from this page:

- **Linux:** unzip it and run `./jackpot-junction`. ARM machines, a Raspberry Pi
  say, take the ARM64 download.
- **macOS:** unzip it and open the app. The first start asks once: allow it under
  System Settings, Privacy & Security, Open Anyway.
- **Windows:** unzip it and run `jackpot-junction.exe`. The first start asks
  once: choose More info, then Run anyway.
- **Android:** open the APK on your phone and allow the browser or file manager
  you opened it from to install apps.

There is nothing else to install. To play online, everybody needs the same minor
version.

**Running a server?** The dedicated server is a download of its own, for Linux
on x86_64 and ARM64, and a Docker image,
`timvisee/jackpot-junction-server`. How to run one is in
[SERVER.md](https://github.com/timvisee/jackpot-junction/blob/master/docs/SERVER.md).

---

### A devlog for a release

itch.io tells everybody following the game when a devlog is posted. One per
release, as the release workflow pushes it:

| Field | What to put |
|---|---|
| Title | Jackpot Junction X.Y.Z |
| Type | Major update, for a new minor version; Patch, for a fix |
| Body | The template below, its notes from `tools/changelog extract X.Y.Z` |

---

**Jackpot Junction X.Y.Z is out.** The itch app updates by itself; otherwise
download it from the page.

*The one paragraph at the top of the version's notes in the changelog.*

*The rest of `tools/changelog extract X.Y.Z`: its Added, Changed and Fixed.*

To play online, everybody needs X.Y.

---

## By hand

`tools/itch` pushes the files of a release from the directory it is run in, so a
release already on GitHub goes up with:

```sh
mkdir release && cd release
gh release download v0.20.0
ITCH_GAME=timvisee/jackpot-junction ITCH_BUTLER_API_KEY=… ../tools/itch v0.20.0
```

It fetches the pinned butler and checks its checksum, or uses the one `BUTLER`
names, and logs in with `ITCH_BUTLER_API_KEY`, handed to butler as its own
`BUTLER_API_KEY`, or with what `butler login` left on the machine. `--dry-run` before the tag lists what each channel would get and logs in
nowhere; the release workflow run by hand from the Actions tab does that too.

Every channel but macOS is pushed as the zip alone in a folder, which butler
unpacks as it goes up. The macOS zip is unpacked first and its `.app` pushed as
the directory it is: butler's one-zip-is-a-container shortcut mishandles the
`.app`'s nested bundle when it diffs a push against the last build, `lstat`-ing
the zip as though it were a folder and failing with `not a directory`, so from
macOS on every channel is left unpushed. A `--dry-run`, with no last build to
diff against, does not hit it, so the first that does is a real release;
`tools/itch --dry-run`, which the workflow runs, lists the `.app`'s files under
the `mac` channel rather than the zip.
