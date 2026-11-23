class_name SteamTimeline
extends Node
## Where the game is, for the timeline of Steam's game recording, GAME.md 10.8: the color of its
## bar, Steam's game mode, and the words along it, the map and the leg being played, read off the
## room a few times a second and told to Steam when they change. Leaving the maps for anywhere else
## ends the game phase of the Grand Prix being played, see [Timeline]. Made by [Game] from its path
## with Steam on, so nothing it names is compiled with the autoloads.

## How often the room is read, in seconds.
const EVERY := 0.25

var _since := EVERY


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	_since += delta
	if _since < EVERY:
		return
	_since = 0.0
	if not Store.on():
		return
	var tree := get_tree()
	var scene := tree.current_scene
	var loading := scene == null or tree.get_first_node_in_group(LoadingScreen.GROUP) != null
	var place := SteamPresence.place_of(scene)
	var match_node: Match = scene.get("match_node") if scene != null else null
	var state := match_node.state if match_node != null else -1
	Store.steam.timeline_mode(mode_for(place["scene"], state, loading, tree.paused))
	Store.steam.timeline_tooltip(tooltip_for(place))
	# A Grand Prix goes from map to map with a room put up between; anywhere else is its end.
	if not loading and place["scene"] != Game.MATCH_SCENE:
		Timeline.end_phase()


func _exit_tree() -> void:
	Timeline.end_phase()


## Steam's game mode, [constant Timeline.PLAYING] and the rest, for the room [param scene], a
## scene's path, its match in [param state], -1 for none: a room being put up is loading, the pause
## menu of a game on this machine alone is the menus, and a match's lobby and podium are waiting,
## like the waiting room.
static func mode_for(scene: String, state: int, loading: bool, paused: bool) -> int:
	if loading:
		return Timeline.LOADING
	if paused:
		return Timeline.MENUS
	match scene:
		Game.MATCH_SCENE:
			if state == Match.State.LOBBY or state == Match.State.RESULTS:
				return Timeline.STAGING
			return Timeline.PLAYING
		Game.WAITING_SCENE:
			return Timeline.STAGING
		Game.GARAGE_SCENE, Game.TUTORIAL_SCENE, Game.DRIVING_SCHOOL_SCENE:
			return Timeline.PLAYING
	return Timeline.MENUS


## The words along the timeline for [param place], as [method SteamPresence.place_of] reads it: the
## map and the leg of a Grand Prix being played, and the place for the rooms between; none in the
## menus.
static func tooltip_for(place: Dictionary) -> String:
	match place.get("scene", ""):
		Game.MATCH_SCENE:
			if not place.has("map"):
				return ""
			var named := TimelineRecord.map_name(StringName(place["map"]))
			var legs := int(place.get("legs", 0))
			if legs > 0 and StringName(place["map"]) != ArenaMaps.SHOWDOWN:
				return "%s · leg %d of %d" % [named, int(place.get("leg", 1)), legs]
			return named
		Game.WAITING_SCENE:
			return "Waiting room"
		Game.GARAGE_SCENE:
			return "Garage"
		Game.TUTORIAL_SCENE, Game.DRIVING_SCHOOL_SCENE:
			return "Driving school"
	return ""
