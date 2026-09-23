extends Node3D
## The two practice rooms, GAME.md 9.4, which are one scene on two maps a portal apart.
##
## The Garage is a room with everything in it: a straight to wind the kart out on, turbo pads at
## either end, crates to slalom and shoot, coin pads, the Junction, a Jackpot, a pit, Royal Flush
## pads, item pads, a joker pad that keeps handing out cards, a row of targets to shoot at for
## coins, and two dummy karts nobody is driving, standing there carrying a pot and an item so
## that shooting one is worth something. Signs name every area, since a player arriving here has
## not read anything.
##
## The test track is the room before that one: a road with corners on it, a wall of boxes to
## shoot through, a straight to open the bottle on, a chicane to drift, and a room at the end to
## keep drifting in. Nothing to collect and nothing to bank; six signs, each of them telling the
## player what to press and what it does. The first visit to the Garage from the title goes here,
## and the portal at the end leads to the Garage proper.
##
## Either room runs an ordinary match with no bots and no clock, so there is nothing to lose and
## nothing to win.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const LAYOUT: ArenaLayout = preload("res://data/maps/garage.tres")
const TRACK: ArenaLayout = preload("res://data/maps/test_track.tres")
const RULES: MatchRules = preload("res://data/match/garage.tres")
const SIGN_HEIGHT := 2.7
## The test track's signs, which are drawn pictures on a card rather than floating words: how big
## the lettering is, how big that picture is in the world, and what colour the line under the
## heading is.
const SIGN_TITLE_SIZE := 34
const SIGN_SIZE := 26
const SIGN_PIXEL := 0.011
const SIGN_INK := Color(0.86, 0.86, 0.90)
## How far back the camera sits on the test track. The track is a road rather than an arena, and
## framing all 65 m of it at once leaves the kart too small to learn a control from, GAME.md 9.4a,
## so the camera comes down onto the player the way the driving room's does in 9.5.
const TRACK_CAMERA := 26.0
## How much floor the camera leaves round the karts in the garage. The rig frames every one of
## them with four metres of floor round it, which is the band a crowd sits in; there is none in
## here, so the bay is held tighter and the karts come out bigger for it, GAME.md 9.4. What is
## framed is unchanged: both dummies stay in the shot, since driving up to one is half of what
## the room is for.
const BAY_MARGIN := 1.0
## The test track's signs: the cell one stands on, the name of the lesson, the line under it, and
## the actions whose bindings fill that line in. A word and a key named the button a stretch was
## about but never said what it did, so each line is an instruction instead. Still short on
## purpose: a player reading a wall is a player not driving.
const TRACK_SIGNS: Array[Array] = [
	[Vector2i(6, 3), "DRIVE", "%s to go", [InputActions.THROTTLE]],
	[Vector2i(21, 3), "STEER", "%s to turn", [InputActions.STEER_LEFT, InputActions.STEER_RIGHT]],
	[Vector2i(11, 17), "SHOOT", "%s to break the boxes", [InputActions.FIRE]],
	[Vector2i(22, 17), "NITRO", "hold %s to go faster", [InputActions.NITRO]],
	[Vector2i(49, 23), "HANDBRAKE", "%s to lock the wheels", [InputActions.HANDBRAKE]],
	[Vector2i(50, 26), "DRIFT", "handbrake and turn", []],
]
## Karts nobody is driving, parked on the floor as practice targets.
const DUMMIES := 2
## The pot a dummy carries, so a kill drops chips worth picking up.
const DUMMY_COINS := Vector2i(8, 25)
const DUMMY_MULT := Vector2(1.0, 3.0)

var match_node: Match
## Whether this is the test track rather than the Garage proper.
var on_track := false


func _ready() -> void:
	ArenaEnvironment.add_to(self)
	on_track = Game.garage_room == Game.ROOM_TRACK
	match_node = MATCH_SCENE.instantiate()
	match_node.name = "Match"
	match_node.rules = RULES
	match_node.arena_layout = TRACK if on_track else LAYOUT
	# The track says what every button does on the signs along it, so the kart does not say it
	# again over the player's shoulder, GAME.md 9.4a.
	match_node.with_kart_hints = not on_track
	match_node.power_ups = load("res://data/powerups/all.tres")
	add_child(match_node)
	var inputs: Array[KartInput] = [PlayerInput.new()]
	# Nobody is standing about on the test track: it is a road, and a kart parked on it is in
	# the way of the one lesson each stretch is there to teach.
	for i: int in 0 if on_track else DUMMIES:
		inputs.append(DummyInput.new())
	# The player drives the kart they dressed and answers to the name they gave, GAME.md 4.4.
	var names: Array[String] = [Game.settings.player_names[0]]
	match_node.start(inputs, 0, [], names, [Game.settings.kart_styles[0]])
	_stock_dummies()
	Events.kart_respawned.connect(_on_kart_respawned)
	# A room for learning the controls in, not a nightclub.
	match_node.arena.disco.enabled = false
	match_node.arena.crowd.enabled = false
	match_node.arena.billboards.visible = false
	_wire_portals()
	if on_track:
		# A kart is pointed at the middle of the map when it is put down, which on a road is a
		# wall two cells away. The track runs one way out of the start, so face it down the road.
		for slot: PlayerSlot in match_node.slots:
			slot.kart.face(Vector3(1.0, 0.0, 0.0))
		match_node.camera_rig.follow_close(TRACK_CAMERA)
		_add_track_signs()
	else:
		_close_the_shot()
		_add_signs()
	DebugOverlay.add_to(self, match_node)
	PauseMenu.add_to(self)


## Brings the camera in, by leaving less floor round what it is framing rather than by framing
## less of it.
func _close_the_shot() -> void:
	match_node.camera_rig.follow_margin = BAY_MARGIN


## Every portal leads to the other room, GAME.md 9.4, which is the only place there is to go.
func _wire_portals() -> void:
	var other := Game.ROOM_GARAGE if on_track else Game.ROOM_TRACK
	for portal: Portal in match_node.arena.portals:
		portal.entered.connect(func(_kart: Kart) -> void: Game.go_to_garage(other))
		_sign("GARAGE" if on_track else "TRACK", portal.global_position, Palette.NEON_CYAN)


## Six signs on the test track, each telling the player what to press on that stretch and what it
## does, with the button itself drawn on the sign, GAME.md 8.3. The bindings are read off the
## input map, so a player who has rebound something is shown what they bound it to.
func _add_track_signs() -> void:
	var grid := match_node.arena.grid
	var keyboard := Game.last_input_keyboard
	for entry: Array in TRACK_SIGNS:
		var at: Vector3 = grid.cell_center(entry[0])
		var sign := InputHint.billboard(InputHint.card(_track_board(entry, keyboard)), SIGN_PIXEL)
		sign.position = Vector3(at.x, SIGN_HEIGHT, at.z)
		add_child(sign)


## One sign: the name of the lesson over the line that teaches it, with the player's own buttons
## drawn into the line.
static func _track_board(entry: Array, keyboard: bool) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 6)
	var title := Label.new()
	title.text = entry[1]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.add_theme_font_size_override("font_size", SIGN_TITLE_SIZE)
	title.add_theme_color_override("font_color", Palette.CHIP_WHITE)
	column.add_child(title)
	var line := InputHint.row(entry[2], _track_glyphs(entry[3], keyboard), SIGN_INK, SIGN_SIZE)
	line.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(line)
	return column


## The buttons one sign names. Two actions are the two ends of a single control and are drawn as
## one, GAME.md 8.3, so steering is a stick on a pad rather than two halves of one.
static func _track_glyphs(actions: Array, keyboard: bool) -> Array:
	if actions.size() >= 2:
		return [InputHint.pair(actions[0], actions[1], keyboard, SIGN_INK, SIGN_SIZE)]
	if actions.size() == 1:
		return [InputHint.glyph(actions[0], keyboard, SIGN_INK, SIGN_SIZE)]
	return []


## A dummy that has been shot comes back with something new in it, so the next one is worth
## shooting too.
func _on_kart_respawned(slot: int) -> void:
	if slot < match_node.slots.size() and match_node.slots[slot].is_dummy():
		_stock(match_node.slots[slot])


func _stock_dummies() -> void:
	for slot: PlayerSlot in match_node.slots:
		if not slot.is_dummy():
			continue
		_label_dummy(slot.kart)
		_stock(slot)


## What a dummy is carrying: a pot with a mult on it and an item in the boot, rolled fresh. The
## death sequence does the rest, GAME.md 3.6, so a kill scatters chips and often the item too.
func _stock(slot: PlayerSlot) -> void:
	var kart := slot.kart
	var rng := match_node.rng
	kart.pot.reset()
	kart.pot.add_coins(rng.randi_range(DUMMY_COINS.x, DUMMY_COINS.y))
	kart.pot.add_mult(rng.randf_range(DUMMY_MULT.x, DUMMY_MULT.y) - 1.0)
	kart.held_item = match_node.power_ups.pick(rng)
	kart.item_reveal_left = 0.0


## A dummy wears its own sign, hung on the kart rather than on a spot on the floor, because it
## is the one piece of furniture here that moves when it comes back.
func _label_dummy(kart: Kart) -> void:
	var label := _make_sign("DUMMY\nshoot me", Palette.CHIP_WHITE)
	label.position = Vector3(0.0, SIGN_HEIGHT * 0.6, 0.0)
	kart.add_child(label)


## Pressing join on a device nobody is using brings a second player in, the same as in a match.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(InputActions.JOIN) or get_tree().paused:
		return
	var device := DeviceInput.KEYBOARD if event is InputEventKey else event.device
	if match_node.join_human(device) != null:
		get_viewport().set_input_as_handled()


## One floating label per area, placed from the arena's own furniture rather than from the map
## text, so moving something in the layout moves its sign with it.
##
## Only the things a player could not name by looking at them get one. A turbo pad, a crate, a
## target, a pit, a coin, an item pad and a royal flush pad are each the thing they are called,
## and a room with a label over every one of them is a room read rather than driven.
func _add_signs() -> void:
	var arena := match_node.arena
	_sign("JUNCTION\nbank your pot here", arena.junction_position, Palette.NEON_MAGENTA)
	for position: Vector3 in arena.jackpot_positions:
		_sign("JACKPOT\ndrive in and wait", position, Palette.CHIP_GOLD)
	_sign_at("JOKERS\ntake one, TAB to manage", arena.joker_pads, Palette.NEON_MAGENTA)


## Puts one sign over the first of a group of things, so a row of targets gets a single label.
func _sign_at(text: String, things: Array, color: Color) -> void:
	if things.is_empty():
		return
	var node := things[0] as Node3D
	if node != null:
		_sign(text, node.global_position, color)


func _sign(text: String, at: Vector3, color: Color) -> void:
	var label := _make_sign(text, color)
	label.position = Vector3(at.x, SIGN_HEIGHT, at.z)
	add_child(label)


func _make_sign(text: String, color: Color) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = 48
	label.outline_size = 12
	label.modulate = color
	label.outline_modulate = Color(0.04, 0.04, 0.05, 0.9)
	label.pixel_size = 0.009
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	return label
