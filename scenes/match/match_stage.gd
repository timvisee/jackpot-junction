class_name MatchStage
extends RefCounted
## Everything a match puts around the arena rather than in it, GAME.md 8.1: the camera watching
## it, the room's own light, the tanks and the clock standing on the table, and the record that
## goes on with it.
##
## Kept out of [Match] because none of it decides anything: a match played with the lights off
## and the camera somewhere else is the same match. It is here so that the presentation of a
## room is one thing in one place, and so the file that runs the rules stays about the rules.

## How hard the top excitement level thumps the camera on the beat, and how much harder on
## the first beat of the bar. This is the only effect that moves what the player is aiming
## through, so it is kept to a thump rather than a shake.
const BEAT_TREMBLE := 2.0
const BEAT_DOWNBEAT := 1.4


## Puts the stage up around [param match_node]'s arena and hands the pieces back to it.
static func build(match_node: Match, camera_scene: PackedScene) -> void:
	var room := match_node.arena.room
	# A map is a place, GAME.md 8.1, and it says what it is lit by.
	ArenaEnvironment.dress_all(match_node.get_tree(), room, match_node.arena.world_size())
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
	# Or in a showdown, with no score in it, a card for everybody in the fight, GAME.md 9.7a.
	ShowdownCards.add_to(match_node)
	# And the clock goes up on a board over the crowd, GAME.md 8.1, which reads the match the
	# same way.
	match_node.led_clock = LedClock.add_to(match_node)
	# A record goes on as the room is built, GAME.md 8.4: three tracks, one of them at random, so
	# a run of matches is not the same loop over and over.
	Audio.pick_track()


## A match opens on the room it is played in, GAME.md 8.2, and comes in on the karts from there.
## Called on every state change rather than at the places a countdown starts, so a rematch and a
## client following snapshots both open the same way without either of them having to know about
## the camera; the rig itself only takes the first of them.
static func watch(match_node: Match, state: Match.State) -> void:
	if match_node.camera_rig == null:
		return
	if state == Match.State.LOBBY or state == Match.State.COUNTDOWN:
		var room := match_node.arena.room if match_node.arena != null else null
		var toward := room.opening_toward if room != null else CameraRig.OPENING_TOWARD
		match_node.camera_rig.open_on_the_room(toward)


## The room answering the excitement meter, GAME.md 8.4: the lights, the crowd and the thump in
## the camera, every tick. A client runs a meter of its own off the same events the host's runs
## off, so it steps its room here too rather than waiting to be told; it used to set the lights
## alone, and its crowd stood still through the loudest match.
static func step(match_node: Match) -> void:
	if match_node.arena == null or match_node.intensity == null or match_node.camera_rig == null:
		return
	var level := match_node.intensity.level
	match_node.arena.disco.level = level
	match_node.arena.crowd.level = level
	match_node.camera_rig.tremble = beat_tremble(level)


## The camera's share of the top excitement level, GAME.md 8.4: at level 6 and nowhere else
## the room is felt as well as heard. A thump on every beat and a harder one on the first of
## the bar, each shaped so it has fallen away before the next arrives. The accessibility
## toggle in 8.5 turns all of it off, since this is the one effect that moves the whole view.
static func beat_tremble(level: int) -> float:
	if level < MatchIntensity.LEVELS:
		return 0.0
	var downbeat := BEAT_DOWNBEAT if Audio.music_beat_index() == 0 else 1.0
	return BEAT_TREMBLE * downbeat * pow(1.0 - Audio.music_beat(), 5.0)
