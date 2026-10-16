extends RefCounted
## Ports for a test's sessions, GAME.md 10.2: a block of them nobody on this machine is using, at a
## place of its own every time, so two runs of the suites at once, from two checkouts or two
## sessions, never host on each other's ports, which failed both with ERR_CANT_CREATE (20).
##
##   const FreePorts := preload("res://tests/free_ports.gd")
##   port = FreePorts.take()

## How many ports a block holds, enough for the furthest a suite reaches past its first, and the
## range blocks are dealt from, clear of the ports the game and its checks use by default.
const SPAN := 64
const LOWEST := 20000
const HIGHEST := 60000
const TRIES := 50


## The first port of a block of [constant SPAN] that is free for UDP, which every session, server
## and beacon speaks on: dealt at random, and looked at port by port.
static func take() -> int:
	var dice := RandomNumberGenerator.new()
	dice.randomize()
	for attempt: int in TRIES:
		var base := dice.randi_range(LOWEST / SPAN, HIGHEST / SPAN - 1) * SPAN
		if _free(base):
			return base
	push_error("no free block of %d ports found" % SPAN)
	return LOWEST


static func _free(base: int) -> bool:
	for offset: int in SPAN:
		var probe := PacketPeerUDP.new()
		var bound := probe.bind(base + offset)
		probe.close()
		if bound != OK:
			return false
	return true
