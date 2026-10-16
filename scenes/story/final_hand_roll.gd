class_name FinalHandRoll
extends Node
## Who is through the Final Hand online, STORY.md 8.1 and 8.6: every screen in the room plays it to
## its end for its own player, the evaluation, the stamp, the last lines and the license, or is
## through at the whistle where it plays an ordinary match instead; and once every player in the
## room is through, the host, a dedicated server's game included, takes the room back to its lobby,
## see [method Game.back_to_the_room]. Whoever is through first waits on the slip. Kept by the
## [NetSession], so its calls find it at the same place at every machine.

var session: NetSession

## At the host: the machines through, by their peer, the host's own as 1, and whether the whistle
## has gone for the room, which is when the roll is called.
var _through: Dictionary[int, bool] = {}
var _calling := false


static func of(owner: NetSession) -> FinalHandRoll:
	var made := FinalHandRoll.new()
	made.name = "FinalHand"
	made.session = owner
	# Called while the room may be stopped, the slip up.
	made.process_mode = Node.PROCESS_MODE_ALWAYS
	return made


## At the host, a Final Hand begun: nobody through yet.
func open() -> void:
	_through.clear()
	_calling = false


## At the host, the whistle gone: the roll is called from here on, a dedicated server through from
## the first, having nobody of its own playing it.
func begin() -> void:
	_calling = true
	if session.dedicated:
		_through[1] = true
	_call()


## This machine is through: its player has put the license away, or it never played the Final
## Hand's own part, see the class.
func through() -> void:
	if session.is_host:
		_mark(1)
	elif session._connected():
		_through_here.rpc_id(1)


@rpc("any_peer", "call_remote", "reliable")
func _through_here() -> void:
	if session.is_host:
		_mark(multiplayer.get_remote_sender_id())


func _mark(peer: int) -> void:
	_through[peer] = true
	_call()


# A player who leaves meanwhile is no longer waited for.
func _process(_delta: float) -> void:
	if _calling:
		_call()


func _call() -> void:
	if not _calling or not all_through(_through, session._player_peers()):
		return
	_calling = false
	Game.back_to_the_room()


## Whether the host, peer 1, and every one of [param players] are in [param through].
static func all_through(through: Dictionary[int, bool], players: PackedInt32Array) -> bool:
	if not through.has(1):
		return false
	for peer: int in players:
		if not through.has(peer):
			return false
	return true
