extends Node
## Who owns the connection, autoloaded as `Net`.
##
## A session used to be a child of the match scene, so the wire went down with the scene: the
## peer was closed in [method NetSession._exit_tree], and every client was dropped the moment the
## host changed rooms. That was survivable while a match was one scene from start to finish. It
## is not survivable with the waiting room of GAME.md 9.6 in front of it, where the host and
## everybody who has joined move from one room to another and expect to still be talking.
##
## So the connection outlives any one room. Scenes come and go under it; the peer, the slots and
## the clients stay until somebody leaves on purpose. It also fixes the node path the RPCs travel
## on: a session under a scene is at whatever that scene happens to be called, and both ends have
## to agree; under here it is always `/root/Net/Session`.
##
## The cost of a longer life is that nothing is cleaned up by a scene change any more. Whatever
## the session is holding is held until [method close] is called, so closing is somebody's job
## rather than something that happens by itself.

## The open session, or null when this machine is not talking to anybody.
var session: NetSession
## Play Online's line to a dedicated server's list of games, GAME.md 9.3a, or null. At the same
## place as the server's own, see [ServerLink], and closed with everything else.
var link: ServerLink


## Opens a session for [param match_node], closing any that was left open. Returns it, so a caller
## can wire up the signals it cares about.
func open(match_node: Match) -> NetSession:
	close()
	session = NetSession.new()
	session.name = "Session"
	session.match_node = match_node
	add_child(session)
	return session


## Points the open session at a new match. The room a session is playing in changes when the
## waiting room gives way to the arena; who it is connected to does not.
func attach(match_node: Match) -> void:
	if session != null:
		session.match_node = match_node


## A line to a dedicated server's list, closing whatever was open.
func open_link() -> ServerLink:
	close()
	link = ServerLink.new()
	link.name = ServerLink.NAME
	add_child(link)
	return link


## Closes the connection and forgets it.
##
## Freed on the spot rather than queued: the peer is a single global, and a session that was
## still waiting to be freed would close the next one's peer out from under it the moment the
## queue ran.
func close() -> void:
	if link != null:
		var line := link
		link = null
		remove_child(line)
		line.free()
	if session == null:
		return
	var going := session
	# A Steam game's host going hands its lobby to the player who has been in it longest, GAME.md
	# 10.8, who hosts it next; Make host has handed it already.
	if going.is_host and Store.steam_game() and Store.steam.lobbies.hosting:
		Store.steam.lobbies.hand_to(going.host_controls.successor_account())
	session = null
	remove_child(going)
	going.free()
	# A Steam game's lobby goes with it, GAME.md 10.8, and the players muted in it.
	Store.left_game()
	Muted.clear()


## The connection to the host of [param session]'s game gone, at a client: the game is handed to
## the next host rather than over, GAME.md 10.8, if there is one to hand it to, see [HostHandover].
## Says whether it is.
func hand_over(going: NetSession) -> bool:
	var handover := get_tree().get_first_node_in_group(&"host_handover")
	return handover != null and bool(handover.call(&"take", going))


## Whether this machine is talking to anybody.
func online() -> bool:
	return session != null


## Whether it is the one being talked to.
func hosting() -> bool:
	return session != null and session.is_host
