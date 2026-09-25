class_name NetLine
extends RefCounted
## How a connection is set up, GAME.md 10.3: packed, patient enough, and no more. Kept apart from
## [NetSession] so that file stays about what is said over the connection rather than about the
## connection itself.

## How long a client tries an address nobody answers at before giving up, in milliseconds, and
## the patience the connection is given back once it is made. Left to itself ENet keeps trying
## for half a minute, which is half a minute of a player looking at a room that is not coming.
const CONNECT_TIMEOUT_MIN := 1000
const CONNECT_TIMEOUT_MAX := 5000
const TIMEOUT_LIMIT := 32
const TIMEOUT_MIN := 5000
const TIMEOUT_MAX := 30000


## Snapshots are mostly the same words over and over, GAME.md 10.3: every dictionary key of
## every kart, bullet and pickup, thirty times a second. A busy one runs to about fourteen
## kilobytes written out and a tenth of that packed, so it is worth packing.
##
## This does not stop a big snapshot being broken up: the packet is split against the MTU before
## the datagrams carrying it are compressed, which is what the engine warns about. Fitting one
## in a single datagram means a smaller snapshot, not a smaller wire. Both ends have to agree on
## the compressor, so both are set from here.
static func compress(peer: ENetMultiplayerPeer) -> void:
	peer.host.compress(ENetConnection.COMPRESS_RANGE_CODER)


## A client trying to reach [param server]: given up on after a few seconds of nobody answering.
static func trying(server: ENetPacketPeer) -> void:
	server.set_timeout(TIMEOUT_LIMIT, CONNECT_TIMEOUT_MIN, CONNECT_TIMEOUT_MAX)


## [param connection] made: the usual patience back, which a moment of a busy network should not
## cost anybody.
static func made(connection: ENetPacketPeer) -> void:
	connection.set_timeout(TIMEOUT_LIMIT, TIMEOUT_MIN, TIMEOUT_MAX)
