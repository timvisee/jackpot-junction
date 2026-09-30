class_name NetPeer
extends RefCounted
## Letting go of a connection, GAME.md 10.3: closed at once, and taken off its API a frame later.
##
## Godot keeps a cache of every node that has sent or heard a remote call, and ties itself to each
## one's tree_exited. Taking the peer off the API empties that cache, and in a release build the
## engine then tries to untie itself with the wrong callable and says, for every such node still
## in the tree, "Attempt to disconnect a nonexistent connection ... Signal: 'tree_exited'". The
## session, the host's say and the ping were still in the tree whenever a session let go from its
## own _exit_tree, since tree_exited is only raised after every _exit_tree has run: three errors
## at the end of every game on a dedicated server, and on a client leaving one. A frame later they
## have left, their own tie has emptied the cache, and there is nothing to untie.
##
## Nothing here names the game, so the dedicated server's hall, which runs without its autoloads,
## can use it too.


## Closes [param peer] now, and takes it off [param api] once the nodes that called through it have
## gone, unless another peer has been put on it in the meantime.
static func let_go(api: MultiplayerAPI, peer: MultiplayerPeer) -> void:
	if api == null or peer == null:
		return
	peer.close()
	_take_off.call_deferred(api, peer)


static func _take_off(api: MultiplayerAPI, peer: MultiplayerPeer) -> void:
	if is_instance_valid(api) and api.multiplayer_peer == peer:
		api.multiplayer_peer = null
