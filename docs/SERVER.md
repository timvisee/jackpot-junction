# Running a server

A dedicated server holds games for players over the internet, so nobody's own
machine has to host, see GAME.md 9.3a. Every release has a Linux server build
for it, `jackpot-junction-server`: the game exported as a server, headless and
serving by itself, with its pictures and models stripped to their sizes and no
sound at all. The game itself serves too, told to, and then loads no sound
either:

```
./jackpot-junction-server                                             # the server build
./jackpot-junction-server -- --port=7777 --games=8
./jackpot-junction --headless -- --server                             # the game, as a server
make server ARGS="--games=4"                                          # from this checkout
```

Players connect with Play Online, to the server's address and port. It
listens on 7777, as a LAN game does, unless given `--port`, and runs each game
in a process of its own on the ports after it, up to `--games` of them: 7778 to
7785 by default, so let UDP 7777 to 7785 through a firewall or router.
`--game-ports=9000-9015` puts the games on ports of their own instead. A LAN
game on the same machine needs another port. `--name="Friday night"` gives the
server a name, which players see over its games, and `--password=...` keeps it
to the people told: Play Online asks for it before it shows the server's games,
and the games turn away anybody who comes straight to their ports without it.

The same settings can be set in the environment, which the command line
overrides:

| Variable        | Argument       | Default                                  |
|-----------------|----------------|------------------------------------------|
| `JJ_PORT`       | `--port`       | `7777`                                   |
| `JJ_GAMES`      | `--games`      | `8`, or as many as `JJ_GAME_PORTS` holds |
| `JJ_GAME_PORTS` | `--game-ports` | the `JJ_GAMES` ports after `JJ_PORT`     |
| `JJ_NAME`       | `--name`       | none, so players see its address         |
| `JJ_PASSWORD`   | `--password`   | none, so anybody may come in             |
| `JJ_WEB_PORT`   | `--web-port`   | `JJ_PORT`'s number, on TCP; `0` for none |
| `JJ_WEB_ADDRESS` | `--web-address` | none, so the page uses the address a visitor came in by |
| `JJ_WEB_LINK`   | `--web-link`   | none, so the page links only itch.io and the source |
| `JJ_WEB_DESCRIPTION` | `--web-description` | none, so the page has no text of your own |

A game is about a quarter of a gigabyte of memory, and a server with no game
running about 90 MB and next to no processor: a game's process is only started
when somebody makes a game. Whoever makes a game has the host's say over it,
passed on to whoever has been in it longest when they leave, and a game ends by
itself once everybody playing has left it. The server logs where it listens as
it starts, every address of its machine, and then every player coming and going
and every game's state to its output, one line each, with the time and the game.

Anything that connects and does not say hello the way the game does is dropped
at once and logged with its address, `Dropped 1.2.3.4: said 18 bytes that are
not a Jackpot Junction hello`, and so are too many connections from one address;
a player who misbehaves once in is kicked, `Kicked Ann, from 1.2.3.4: ...`. A
flood of datagrams that are not the game's never reaches the game and cannot be
traced to a sender, so the server only logs that it is getting one, once a
minute: rate limiting UDP 7777 to 7785 in the firewall is the way to stop one.

## The web page

A browser pointed at the server gets a plain page with the server's name and
version, how to join it — get the game, open Play Online, choose the Servers tab
and Add a server or Direct connect, with the address and port each in a field of
its own to click and copy — the links to get the game, and the games being
played right now, their names, maps and how full they are. A little JavaScript
pulls the list in again every few seconds without a reload and does the copying;
without it the page still shows everything and reloads itself now and then. It is
served over HTTP from the server's own process, so there is nothing more to run.

Because the game is UDP, the page is served on TCP on the server's own number,
`7777` by default: point a browser at `http://that-address:7777/`. `--web-port`
or `JJ_WEB_PORT` moves it, and `--web-port=0` turns it off. `--web-address` or
`JJ_WEB_ADDRESS` is the address the page tells players to enter — a domain of
yours rather than the bare address they came in by. `--web-link` or `JJ_WEB_LINK`
adds a link of your own beside the itch.io and source links it always carries,
and `--web-description` or `JJ_WEB_DESCRIPTION` puts a line or two of your own at
the top — a welcome, the rules, when it is up. It also answers `/status.json`
with the list for tools, `/games.html` with the games on their own, and
`/health` with `ok`. In Docker the page's TCP port wants publishing to be
reached, see below; the host's own port 80 is usually already taken, so map it.

## With Docker

Every release also publishes the server as a Docker image for x86_64 and ARM,
[`timvisee/jackpot-junction-server`](https://hub.docker.com/r/timvisee/jackpot-junction-server),
tagged with its version, such as `0.11.0`, and the newest as `latest`. It holds
the server build and the C library it runs on, and runs as a user of its own
rather than root. To run it:

```
docker run -d --name jackpot-junction --restart unless-stopped \
  -p 7777-7785:7777-7785/udp timvisee/jackpot-junction-server
```

Or with Docker Compose, from [`docker/compose.yaml`](../docker/compose.yaml):

```
curl -O https://raw.githubusercontent.com/timvisee/jackpot-junction/master/docker/compose.yaml
docker compose up -d
docker compose logs -f                  # the server's log
docker compose pull && docker compose up -d     # to the newest release
```

The server is set with the environment variables above, `-e JJ_GAMES=4` or
`-e JJ_NAME="Friday night"`, or
with its arguments after the image's name,
`timvisee/jackpot-junction-server --games=4`. Publish every port as the same
number on the host as in the container, `-p 9000-9015:9000-9015/udp` for
`JJ_GAME_PORTS=9000-9015`: the server tells a player which port their game is
on, and they connect to that number. Players need the same major and minor
version as the server, so pin the tag, `:0.11.0`, to upgrade only when they do.
The log's times are UTC unless `TZ` is set, `-e TZ=Europe/Amsterdam`, and the
addresses it says it listens on are the container's own rather than the host's.
`make docker` builds the image from this checkout, for this machine.
