class_name MatchStage
extends RefCounted
## Everything a match puts around the arena rather than in it, GAME.md 8.1: the camera watching
## it, the room's own light, the tanks and the clock standing on the table, and the record that
## goes on with it.
##
## Kept out of [Match] because none of it decides anything: a match played with the lights off
## and the camera somewhere else is the same match. It is here so that the presentation of a
## room is one thing in one place, and so the file that runs the rules stays about the rules.


## Puts the stage up around [param match_node]'s arena and hands the pieces back to it.
static func build(match_node: Match, camera_scene: PackedScene) -> void:
	var room := match_node.arena.room
	# A map is a place, GAME.md 8.1, and it says what it is lit by.
	ArenaEnvironment.dress_all(match_node.get_tree(), room)
	var rig: CameraRig = camera_scene.instantiate()
	rig.name = "CameraRig"
	match_node.add_child(rig)
	rig.frame_arena(match_node.arena.bounds())
	# How far past the karts the room goes soft is the room's call: a bright room wants very
	# little of it and a dark one wants the back of itself gone.
	rig.focus_margin = room.focus_from
	rig.focus_blur = room.focus_blur
	match_node.camera_rig = rig
	# The race to the target score, standing on the table, GAME.md 8.1. It reads the slots every
	# frame rather than being handed them, so it is right on a client filling up from snapshots
	# and after somebody joins mid-match.
	match_node.score_tanks = ScoreTanks.add_to(match_node)
	# And the clock goes up on a board over the crowd, GAME.md 8.1, which reads the match the
	# same way.
	match_node.led_clock = LedClock.add_to(match_node)
	# A record goes on as the room is built, GAME.md 8.4: three tracks, one of them at random, so
	# a run of matches is not the same loop over and over.
	Audio.pick_track()
