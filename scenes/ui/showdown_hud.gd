class_name ShowdownHud
extends Control
## A showdown's own part of the HUD and of the room, GAME.md 9.7a. Over the lamps, the SHOWDOWN
## plate dressed in a pair with the names in it, the room dark with a head of the rig on each kart
## in it, the crowd still and the music hushed under the alarm pitched down. At the flag the plate
## goes, the light comes up and the crowd roars. All through it the tag under the clock, SHOWDOWN
## and how many are left. On every screen alike, the host's and a client's, from what each has.

## How much of its own light the room keeps while the lamps run, and how long it takes to come back
## up at the flag.
const DARK := 0.3
const LIGHT_UP := 0.6
## Long enough for any wait on the lamps: the plate is put away at the flag rather than timed.
const UNTIL_THE_FLAG := 3600.0

var match_node: Match

var _plate: CallBanner
var _clock: ClockBoard
## Whether the opening is up, and how many names its plate says.
var _open := false
var _named := -1
var _lights: Tween


## The showdown's part of [param hud], when its match is a showdown.
static func add_to(hud: MatchHud) -> void:
	if hud.match_node == null or not hud.match_node.rules.showdown():
		return
	var dressing := ShowdownHud.new()
	dressing.name = "Showdown"
	dressing.match_node = hud.match_node
	dressing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dressing.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.add_child(dressing)


## The tag under the clock, see [member ClockBoard.under].
static func tag(match_node: Match) -> String:
	return "SHOWDOWN  ·  %d LEFT" % Showdown.left(match_node)


func _ready() -> void:
	_plate = CallBanner.new()
	_plate.name = "Plate"
	_plate.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_plate.offset_top += MatchHud.CALL_DROP
	_plate.offset_bottom += MatchHud.CALL_DROP
	add_child(_plate)
	_clock = get_parent().get_node_or_null("Clock") as ClockBoard


func _process(_delta: float) -> void:
	var state := match_node.state
	var waiting := state == Match.State.LOBBY or state == Match.State.COUNTDOWN
	if waiting:
		_open_up()
	elif _open:
		_let_in()
	if _clock != null:
		_clock.under = tag(match_node) if state != Match.State.RESULTS else ""
		_clock.hot = _clock.hot or match_node.is_running()


## The room before the flag: dark, the rig's heads on the karts in the fight, the crowd still, the
## music hushed, and the plate up saying who it is between. Kept up every frame it lasts, since a
## client fills its seats in from snapshots as they come and the room is told to wake on every
## change of state.
func _open_up() -> void:
	Audio.hush_music(true)
	var fighting := _fighting()
	if not _open:
		_open = true
		_named = -1
		Audio.play_sfx(&"last_call", -1.0, 0.0, 0.78)
		_dim(true)
	if fighting.size() != _named:
		_named = fighting.size()
		var names: PackedStringArray = []
		var colors: Array[Color] = []
		var karts: Array[Node3D] = []
		for slot: PlayerSlot in fighting:
			names.append(slot.display_name())
			colors.append(slot.color())
			if slot.kart != null:
				karts.append(slot.kart)
		_plate.show_call("", "SHOWDOWN", HouseTheme.FOIL, false, UNTIL_THE_FLAG)
		_plate.show_names(names, colors)
		if match_node.arena != null:
			match_node.arena.disco.focus_each(karts)
	if match_node.arena != null:
		match_node.arena.crowd.still = true


## The flag: the plate goes, the room's light comes back up, the rig goes back to the room and the
## crowd roars.
func _let_in() -> void:
	_open = false
	_plate.let_go()
	Audio.hush_music(false)
	_dim(false)
	if match_node.arena != null:
		match_node.arena.disco.clear_focus()
		match_node.arena.crowd.applaud()


## The karts in the fight, in seat order.
func _fighting() -> Array[PlayerSlot]:
	var fighting: Array[PlayerSlot] = []
	for slot: PlayerSlot in match_node.slots:
		if not slot.benched:
			fighting.append(slot)
	return fighting


## Takes the room's light down to [constant DARK] of itself at once, or brings it back up to all
## of it over [constant LIGHT_UP].
func _dim(dark: bool) -> void:
	if _lights != null:
		_lights.kill()
		_lights = null
	for lighting: ArenaEnvironment in get_tree().get_nodes_in_group(&"arena_environment"):
		var room := lighting.lit_by
		if room == null or lighting.key == null or lighting.lamp == null:
			continue
		if dark:
			lighting.key.light_energy = room.key_energy * DARK
			lighting.lamp.light_energy = room.lamp_energy * DARK
			continue
		if _lights == null:
			_lights = create_tween().set_parallel()
		_lights.tween_property(lighting.key, "light_energy", room.key_energy, LIGHT_UP)
		_lights.tween_property(lighting.lamp, "light_energy", room.lamp_energy, LIGHT_UP)
