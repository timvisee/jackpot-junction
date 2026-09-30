# syntax=docker/dockerfile:1
#
# The dedicated server, GAME.md 9.3a, as a container: the server export, the C library it runs on,
# an init to run it under and a shell for the engine to ask one thing of, and nothing else. No
# package manager, and not root.
#
# Built from the exports rather than from the source, with build/ as its context, after
# `make export` or `make docker`:
#
#   docker buildx build --platform linux/amd64,linux/arm64 -f docker/Dockerfile build
#
# Each platform's server comes out of its own folder, and a build for one platform needs only that
# one's. Nothing here runs a program, so an ARM image is built on an x86 machine without emulating
# anything. See README.md, Running a server, for starting it.

FROM scratch AS server-amd64
COPY linux-server/jackpot-junction-server /

FROM scratch AS server-arm64
COPY linux-server-arm64/jackpot-junction-server /

# The first process in a container is the one the stop signal goes to, and the kernel delivers it
# only to a process that has asked for it, which the engine has not: `docker stop` waited out its
# ten seconds and killed the server. tini runs it instead, hands the signal on to it and to its
# games, and reaps what ends. Its static build, checked against the release's own sums.
FROM scratch AS tini-amd64
ADD --checksum=sha256:c5b0666b4cb676901f90dfcb37106783c5fe2077b04590973b885950611b30ee \
	https://github.com/krallin/tini/releases/download/v0.19.0/tini-static-amd64 /tini

FROM scratch AS tini-arm64
ADD --checksum=sha256:eae1d3aa50c48fb23b8cbdf4e369d0910dfc538566bfd09df89a774aa84a48b9 \
	https://github.com/krallin/tini/releases/download/v0.19.0/tini-static-arm64 /tini

FROM server-${TARGETARCH} AS server
FROM tini-${TARGETARCH} AS tini

# The one shell, busybox's, statically linked. The engine asks `/bin/sh -c xdg-user-dir DESKTOP`
# where the desktop is as it starts, which a server has no use for, and with no shell to ask it
# logs an error: once for the server and once again for every game it starts. With one, it is told
# there is none and says nothing.
FROM busybox:1.37.0-musl AS shell

# The server needs the C library and the dynamic loader: `ldd` names libc, libm, libdl, libpthread
# and librt, and nothing more. This is those, with the time zones, a nonroot user to run as and a
# home for its user:// folder.
FROM gcr.io/distroless/base-nossl-debian12:nonroot

COPY --from=tini --chmod=755 /tini /tini
COPY --from=shell /bin/busybox /bin/sh
COPY --from=server --chmod=755 /jackpot-junction-server /jackpot-junction-server

# The server's port, and the eight games' ports after it: the defaults, which JJ_PORT, JJ_GAMES and
# JJ_GAME_PORTS, or --port, --games and --game-ports, change.
EXPOSE 7777/udp 7778-7785/udp

# Whatever follows the image's name on `docker run` is the server's own arguments, `--port=7777`
# and the rest, which go after the `--` that tells the engine's from the game's. tini's -g hands a
# signal to the games as well as to the server, and -s lets it do its job under `docker run --init`
# too, where another init is the first process.
ENTRYPOINT ["/tini", "-g", "-s", "--", "/jackpot-junction-server", "--"]
