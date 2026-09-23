extends GdUnitTestSuite
## Who owns the connection, GAME.md 10.3. It used to be the match scene, which meant the wire
## went down with the scene and every client was dropped the moment the host changed rooms. It
## belongs to the [Net] autoload now, so it outlives any one room.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")


func after_test() -> void:
	Net.close()


func _match() -> Match:
	var match_node: Match = auto_free(MATCH_SCENE.instantiate())
	match_node.rules = load("res://data/match/default.tres").duplicate()
	add_child(match_node)
	return match_node


## The session hangs off the autoload rather than off whatever scene asked for it. That is the
## whole of why it survives a scene change: nothing frees it when the scene goes.
func test_the_session_belongs_to_the_autoload_not_the_scene() -> void:
	var match_node := _match()
	var session := Net.open(match_node)
	assert_object(session).is_not_null()
	assert_object(session.get_parent()).is_same(Net)
	assert_object(Net.session).is_same(session)
	assert_bool(Net.online()).is_true()
	# And it is reachable by the same path on both ends of a wire, which is what the RPCs travel
	# on: a session under a scene is at whatever that scene happens to be called.
	assert_str(str(session.get_path())).is_equal("/root/Net/Session")


## Opening a second one closes the first on the spot. The peer is a single global, so a session
## left waiting to be freed would close the new one's peer out from under it.
func test_opening_again_closes_the_one_before_it() -> void:
	var first := Net.open(_match())
	var second := Net.open(_match())
	assert_bool(first == second).is_false()
	assert_bool(is_instance_valid(first)).is_false()
	assert_object(Net.session).is_same(second)
	assert_object(second.get_parent()).is_same(Net)


## Closing hangs up, and closing again is not an error: every way out of a match calls it, and
## some of them are reached twice.
func test_closing_hangs_up_and_can_be_asked_twice() -> void:
	Net.open(_match())
	Net.close()
	assert_object(Net.session).is_null()
	assert_bool(Net.online()).is_false()
	assert_bool(Net.hosting()).is_false()
	Net.close()
	assert_object(Net.session).is_null()


## The room a session is playing in changes when the waiting room of 9.6 gives way to the arena.
## Who it is connected to does not.
func test_the_session_can_be_pointed_at_another_room() -> void:
	var first := _match()
	var session := Net.open(first)
	assert_object(session.match_node).is_same(first)
	var second := _match()
	Net.attach(second)
	assert_object(session.match_node).is_same(second)
	assert_object(Net.session).is_same(session)
