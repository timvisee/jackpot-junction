extends Node3D
## The Garage, GAME.md 9.4: a practice room reached from the title screen. It runs an ordinary
## match on its own map with no bots and no clock, so there is nothing to lose and nothing to
## win. Everything the game does is somewhere on the floor: a straight to wind the kart out on,
## turbo pads at either end, crates to slalom and shoot, coin pads, the Junction, a Jackpot, a
## pit, Royal Flush pads, item pads, a joker pad that keeps handing out cards, and a row of
## targets to shoot at for coins.
##
## Two of the karts on the floor are dummies: nobody is driving them, so they never shoot back,
## and they stand there carrying a pot and an item so that shooting one is worth something. They
## come back after the usual respawn, restocked, which makes them a target a player can practise
## on all afternoon.
##
## Signs name every area, since a player arriving here has not read anything.

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const LAYOUT: ArenaLayout = preload("res://data/maps/garage.tres")
const RULES: MatchRules = preload("res://data/match/garage.tres")
const SIGN_HEIGHT := 2.7
## Karts nobody is driving, parked on the floor as practice targets.
const DUMMIES := 2
## The pot a dummy carries, so a kill drops chips worth picking up.
const DUMMY_COINS := Vector2i(8, 25)
const DUMMY_MULT := Vector2(1.0, 3.0)

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
	for i: int in DUMMIES:
		inputs.append(DummyInput.new())
	match_node.start(inputs)
	_stock_dummies()
	Events.kart_respawned.connect(_on_kart_respawned)
	# A room for learning the controls in, not a nightclub.
	match_node.arena.disco.enabled = false
	_add_signs()
	DebugOverlay.add_to(self, match_node)
	PauseMenu.add_to(self)


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
