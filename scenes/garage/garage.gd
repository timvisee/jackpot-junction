extends Node3D
## The Garage, GAME.md 9.4: a practice room reached from the title screen. It runs an ordinary
## match on its own map with no bots and no clock, so there is nothing to lose and nothing to
## win. Everything the game does is somewhere on the floor: a straight to wind the kart out on,
## turbo pads at either end, crates to slalom and shoot, coin pads, the Junction, a Jackpot, a
## pit, Royal Flush pads, item pads, a joker pad that keeps handing out cards, and a row of
## targets to shoot at for coins.
##
## Signs name every area, since a player arriving here has not read anything.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const LAYOUT: ArenaLayout = preload("res://data/maps/garage.tres")
const RULES: MatchRules = preload("res://data/match/garage.tres")
const SIGN_HEIGHT := 2.7

var match_node: Match


func _ready() -> void:
	ArenaEnvironment.add_to(self)
	match_node = MATCH_SCENE.instantiate()
	match_node.name = "Match"
	match_node.rules = RULES
	match_node.arena_layout = LAYOUT
	match_node.power_ups = load("res://data/powerups/all.tres")
	add_child(match_node)
	var inputs: Array[KartInput] = [PlayerInput.new()]
	match_node.start(inputs)
	_add_signs()
	var overlay := DebugOverlay.new()
	overlay.name = "DebugOverlay"
	overlay.match_node = match_node
	overlay.visible = false
	add_child(overlay)
	var pause := PauseMenu.new()
	pause.name = "PauseMenu"
	add_child(pause)


## Pressing join on a device nobody is using brings a second player in, the same as in a match.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(InputActions.JOIN) or get_tree().paused:
		return
	var device := DeviceInput.KEYBOARD if event is InputEventKey else event.device
	if match_node.join_human(device) != null:
		get_viewport().set_input_as_handled()


## One floating label per area, placed from the arena's own furniture rather than from the map
## text, so moving something in the layout moves its sign with it.
func _add_signs() -> void:
	var arena := match_node.arena
	_sign("JUNCTION\nbank your pot here", arena.junction_position, Palette.NEON_MAGENTA)
	for position: Vector3 in arena.jackpot_positions:
		_sign("JACKPOT\ndrive in and wait", position, Palette.CHIP_GOLD)
	_sign_at("TARGETS\nshoot for coins", arena.targets, Palette.CHIP_RED)
	_sign_at("JOKERS\ntake one, TAB to manage", arena.joker_pads, Palette.NEON_MAGENTA)
	_sign_at("ITEMS", arena.power_pads, Palette.NEON_MAGENTA)
	_sign_at("TURBO", arena.turbo_pads, Palette.NEON_CYAN)
	_sign_at("PIT\nmind the hole", arena.pits, Color(0.75, 0.75, 0.8))
	_sign_at("COINS", arena.coin_pads, Palette.CHIP_GOLD)
	_sign_at("CRATES\nshoot them", arena.crates, Palette.BLOCK_EDGE)
	_sign_at("ROYAL FLUSH\nclaim all four", arena.flush_pads, Palette.CHIP_WHITE)


## Puts one sign over the first of a group of things, so a row of targets gets a single label.
func _sign_at(text: String, things: Array, color: Color) -> void:
	if things.is_empty():
		return
	var node := things[0] as Node3D
	if node != null:
		_sign(text, node.global_position, color)


func _sign(text: String, at: Vector3, color: Color) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 48
	label.outline_size = 12
	label.modulate = color
	label.outline_modulate = Color(0.04, 0.04, 0.05, 0.9)
	label.pixel_size = 0.009
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.position = Vector3(at.x, SIGN_HEIGHT, at.z)
	add_child(label)
