extends Node3D
## The Garage, GAME.md 9.4: a practice room with the floor kept open to drive and drift on. Two
## rings painted round the Junction in the middle, the Royal Flush pads on the outer one; a range of
## targets at the back left with item pads at its firing line, two dummy karts parked in their bays
## at the back right carrying a pot and an item so that shooting one is worth something, and the
## joker pad between; a pit among the crates on the left and the Jackpot across from it, a slot
## machine, a straight along the front with a turbo pad at either end and coins on it, and the lift
## in the front left corner. Nothing has a sign over it: the paint on the floor says what each part
## is for, see [GarageFloor]. The driving school of 9.4a, which teaches the controls a lesson at a
## time, is the title's to open, and leads here at its end.
##
## It runs an ordinary match with no bots and no clock, so there is nothing to lose and nothing
## to win.

## Given once the room is up and the match in it started, GAME.md 8.6.
signal loaded

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const LAYOUT: ArenaLayout = preload("res://data/maps/garage.tres")
const RULES: MatchRules = preload("res://data/match/garage.tres")
## How much floor the camera leaves round the karts in the garage. The rig frames every one of
## them with four meters of floor round it, which is the band a crowd sits in; there is none in
## here, so the bay is held tighter and the karts come out bigger for it, GAME.md 9.4. It frames
## the players' karts only: the dummies stand parked in their bays, and a shot held wide enough to
## keep them in it left the player small wherever they drove.
const BAY_MARGIN := 1.0
## Where the lift the kart is dressed on stands, GAME.md 4.4: the top left cell of its bay, on the
## open floor along the front wall under the left of the room, well off the side wall.
const LIFT := Vector2i(5, 15)
## Karts nobody is driving, parked on the floor as practice targets.
const DUMMIES := 2
## The pot a dummy carries, so a kill drops chips worth picking up.
const DUMMY_COINS := Vector2i(8, 25)
const DUMMY_MULT := Vector2(1.0, 3.0)

var match_node: Match
## The paint on the floor.
var floor_paint: GarageFloor
## The lift, and the kart dialog while it is up from it.
var lift: KartLift
var _kart: KartDialog


func _ready() -> void:
	ArenaEnvironment.add_to(self)
	match_node = MATCH_SCENE.instantiate()
	match_node.name = "Match"
	match_node.rules = RULES
	# With the Showroom open, GAME.md 8.9, the Garage has its bay behind the back wall.
	var showroom := Loyalty.showroom_open(Game.settings.profile)
	match_node.arena_layout = Showroom.LAYOUT if showroom else LAYOUT
	# Every item and card the profile playing's loyalty program has, GAME.md 8.9.
	Loyalty.deal_table(match_node, load("res://data/powerups/all.tres"), false)
	add_child(match_node)
	# Put up behind a loading screen, the way a map is.
	await LoadingScreen.put_up(self, match_node, "Garage")
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.ANY, 0)]
	for i: int in DUMMIES:
		inputs.append(DummyInput.new())
	# The player drives the kart they dressed, in the finishes their program has it in, and answers to
	# the name they gave, GAME.md 4.4.
	var names: Array[String] = [Game.settings.seat_name(0)]
	var colors := MatchConfig.favorite_first(Game.settings.seat_color(0), inputs.size())
	match_node.start(inputs, 0, colors, names, [Game.settings.seat_style(0)])
	_stock_dummies()
	_park_dummies()
	Events.kart_respawned.connect(_on_kart_respawned)
	# A room for learning the controls in, not a nightclub.
	match_node.arena.disco.enabled = false
	match_node.arena.crowd.enabled = false
	match_node.arena.billboards.visible = false
	_close_the_shot()
	# What each part of the floor is for, painted on it, see [GarageFloor].
	floor_paint = GarageFloor.add_to(match_node)
	# The kart is dressed in here on the lift along the front wall, GAME.md 9.4: stopped on it, the
	# kart dialog comes up, see [KartDialog].
	lift = KartLift.add_to(match_node, LIFT + Vector2i(0, Showroom.BAY if showroom else 0))
	lift.stopped.connect(_on_lift)
	# The Showroom's roller door in the back wall, shut until it is won, and its bay once it is.
	Showroom.add_to(match_node, showroom)
	# The slot machines on the rail in for repair, a stopped clock by the door and the tools' board.
	GarageRail.add_to(match_node)
	# What is taken in here goes into the catalog, GAME.md 8.8, though nothing else counts, and the
	# achievements of a record are earned here as anywhere, the dress worn and the cards found, 8.10.
	CatalogRecord.add_to(match_node)
	AchievementRecord.add_to(match_node, false)
	DebugOverlay.add_to(self, match_node)
	var menu := PauseMenu.add_to(self)
	menu.names_and_colors = true
	menu.offer_kart(match_node)
	loaded.emit()


func _exit_tree() -> void:
	if Events.kart_respawned.is_connected(_on_kart_respawned):
		Events.kart_respawned.disconnect(_on_kart_respawned)


## Brings the camera in, by leaving less floor round what it is framing, and by framing the
## players' karts and not the dummies.
func _close_the_shot() -> void:
	match_node.camera_rig.follow_margin = BAY_MARGIN
	for slot: PlayerSlot in match_node.slots:
		if slot.is_dummy():
			match_node.camera_rig.targets.erase(slot.kart)


## A player here stopped on the lift, GAME.md 9.4: the kart dialog up on their seat's tab, the room
## stopped under it the way the pause menu stops it, and going again once it is put away.
func _on_lift(slot: PlayerSlot) -> void:
	if _kart != null or PauseMenu.is_open_in(get_tree()):
		return
	var player := slot.input as PlayerInput
	_kart = KartDialog.open(self, match_node, player.seat if player != null else 0)
	get_tree().paused = true
	_kart.put_away.connect(
		func() -> void:
			_kart = null
			get_tree().paused = false
	)


## A dummy that has been shot comes back with something new in it, so the next one is worth
## shooting too.
func _on_kart_respawned(slot: int, _at: Vector3) -> void:
	if slot < match_node.slots.size() and match_node.slots[slot].is_dummy():
		_stock(match_node.slots[slot])


func _stock_dummies() -> void:
	for slot: PlayerSlot in match_node.slots:
		if not slot.is_dummy():
			continue
		_stock(slot)


## Each dummy parked in its bay, where it starts, backed in and facing out into the room, and put
## back there whenever it comes back rather than at whichever spawn is farthest from the player.
func _park_dummies() -> void:
	for slot: PlayerSlot in match_node.slots:
		if not slot.is_dummy():
			continue
		var at := slot.kart.global_position
		match_node.parked[slot.index] = Transform3D(Basis.looking_at(Vector3.BACK), at)
		slot.kart.face(Vector3.BACK)


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


## Pressing join on a device nobody is using brings a second player in, the same as in a match.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(InputActions.JOIN) or get_tree().paused:
		return
	var device := DeviceInput.KEYBOARD if event is InputEventKey else event.device
	if match_node.join_human(device) != null:
		get_viewport().set_input_as_handled()
