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
