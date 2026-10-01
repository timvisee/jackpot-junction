class_name Tutorial
extends Node3D
## The tutorial, GAME.md 9.4a: a map of rooms in a row, each a lesson, joined by gates, with a
## checklist in the top right, a hint over the kart and the HUD arriving a piece at a time. The
## room is an ordinary match on the tutorial map, the way the Garage of 9.4 is: one player, two
## parked karts for the jokers lesson and three bots for the fight at the end, no clock, and no
## Cursed joker in the deck. The lessons run over it, see [TutorialRun]. A player who has never
## said how they drive is asked before the kart will move; the portals at the end lead to Play
## and to the Garage.

## Given once the room is up and the lessons running, GAME.md 8.6.
signal loaded

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const LAYOUT: ArenaLayout = preload("res://data/maps/tutorial.tres")
const RULES: MatchRules = preload("res://data/match/tutorial.tres")
const CATALOG: JokerCatalog = preload("res://data/jokers/catalog.tres")
const EASY: BotDifficulty = preload("res://data/ai/easy.tres")
## How far back the camera follows: a room framed whole puts the kart too far away to see what a
## control did, GAME.md 9.4a.
const CAMERA := 26.0
const SIGN_HEIGHT := 2.7
## Which of the two portals at the end leads to Play; the other leads to the Garage.
const PLAY_PORTAL := Vector2i(34, 36)
## What the end says, and for how long, and how long the fireworks over the room go on.
const DONE := "TUTORIAL COMPLETE"
const DONE_SHOWN := 5.0
const FIREWORKS_FOR := 8.0

var match_node: Match
var run: TutorialRun
var layer: CanvasLayer
var menu: PauseMenu
## Whether the kart is held still for the question of how to drive, every tick, since the match
## lets its karts go as it gets going.
var holding := false


func _ready() -> void:
	ArenaEnvironment.add_to(self)
	match_node = MATCH_SCENE.instantiate()
	match_node.name = "Match"
	# A copy: the lessons turn the joker pick on when they get to it, GAME.md 9.4a.
	match_node.rules = RULES.duplicate()
	match_node.arena_layout = LAYOUT
	match_node.joker_catalog = catalog_without_cursed()
	match_node.bot_difficulty = EASY
	# The line over the kart is the tutorial's own, a task at a time.
	match_node.with_kart_hints = false
	match_node.power_ups = load("res://data/powerups/all.tres")
	add_child(match_node)
	# Built without baking: the last room holds its pads, Junction and boxes back until their
	# lessons, see [TutorialReveal], which takes each being a node of its own.
	match_node.prepare_arena(true).bake_scenery = false
	# A turret dropped in here shoots the targets too, GAME.md 9.4a.
	Turret.hunts_targets = true
	await LoadingScreen.put_up(self, match_node, "Tutorial")
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.ANY, 0)]
	for i: int in TutorialJokers.DUMMIES:
		inputs.append(DummyInput.new())
	for i: int in TutorialFight.BOTS:
		inputs.append(BotInput.new())
	# The player drives the kart they dressed and answers to the name they gave, GAME.md 4.4.
	var names: Array[String] = [Game.settings.player_names[0]]
	match_node.start(inputs, 0, [], names, [Game.settings.kart_styles[0]])
	# A room for learning in, not a nightclub, as the Garage is.
	match_node.arena.disco.enabled = false
	match_node.arena.crowd.enabled = false
	match_node.arena.billboards.visible = false
	# The camera follows the player alone: the match frames every kart, and the parked karts and
	# the penned bots are rooms away.
	var followed: Array[Node3D] = [match_node.slots[0].kart]
	match_node.camera_rig.targets = followed
	match_node.camera_rig.follow_close(CAMERA)
	_wire_portals()
	layer = CanvasLayer.new()
	layer.name = "TutorialLayer"
	# Over the HUD's layer, under the pause menu's.
	layer.layer = 6
	add_child(layer)
	run = TutorialRun.add_to(self, match_node, layer)
	run.finished.connect(_on_finished)
	DebugOverlay.add_to(self, match_node)
	menu = PauseMenu.add_to(self)
	menu.names_and_colors = true
	menu.add_entry("Skip lesson", run.skip)
	_ask_how_to_drive()
	loaded.emit()


func _exit_tree() -> void:
	Turret.hunts_targets = false


## The deck without its Cursed cards, GAME.md 9.4a: a trap is no way to meet a mechanic.
static func catalog_without_cursed() -> JokerCatalog:
	var kept := JokerCatalog.new()
	for joker: Joker in CATALOG.jokers:
		if joker.kind != Joker.Kind.CURSED:
			kept.jokers.append(joker)
	return kept


## The two portals at the end, behind their gate until the tutorial is done: one to Play, one to
## the Garage.
func _wire_portals() -> void:
	var play_at := match_node.arena.grid.cell_center(PLAY_PORTAL)
	for portal: Portal in match_node.arena.portals:
		var to_play := portal.position.distance_to(play_at) < 0.5
		# Once the physics step that saw the kart arrive is over: the room it takes down is made of
		# the bodies that step is in the middle of.
		if to_play:
			portal.entered.connect(func(_kart: Kart) -> void: Game.go_to_lobby.call_deferred())
		else:
			portal.entered.connect(func(_kart: Kart) -> void: Game.go_to_garage.call_deferred())
		_sign("PLAY" if to_play else "GARAGE", portal.global_position, Palette.NEON_CYAN)


## The first lesson faces north, up the corridor, and a player who has never said how they drive
## is asked first, GAME.md 9.4a, with the kart held until they have.
func _ask_how_to_drive() -> void:
	var kart := run.kart()
	kart.face(Vector3(0.0, 0.0, -1.0))
	var holder := Control.new()
	holder.name = "DriveQuestion"
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(holder)
	var begin := func() -> void:
		holding = false
		kart.frozen = false
		holder.queue_free()
		run.begin()
	if DriveChoice.first(holder, begin) != null:
		holding = true
		kart.frozen = true


func _physics_process(_delta: float) -> void:
	if holding and run != null:
		run.kart().frozen = true


## Done, GAME.md 9.4a: said so, with a fanfare, remembered, and the gate to the portals opened.
func _on_finished() -> void:
	Game.settings.tutorial_done = true
	Game.settings.save_to_disk()
	Audio.play_sfx(&"fanfare", -4.0, 0.0)
	run.open_gate(TutorialFight.PORTAL_GATE)
	# Fireworks over the last room, in the player's color, the way a match won has them.
	var grid := match_node.arena.grid
	var across := Vector3(TutorialPads.ROOM.size.x, 0.0, TutorialPads.ROOM.size.y) * grid.cell_size
	var middle := grid.rect_center(TutorialPads.ROOM)
	var kart := run.kart()
	Fireworks.celebrate(
		match_node,
		AABB(middle - across * 0.5, across),
		Palette.player_color(kart.color_index),
		FIREWORKS_FOR
	)
	var banner := Label.new()
	banner.name = "Done"
	banner.text = DONE
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.display(banner, Type.HERO, Palette.CHIP_GOLD)
	HudText.shadowed(banner, 3)
	banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	banner.offset_top = 120.0
	banner.offset_bottom = 120.0
	layer.add_child(banner)
	var fade := create_tween()
	fade.tween_interval(DONE_SHOWN)
	fade.tween_property(banner, "modulate:a", 0.0, 1.0)
	fade.tween_callback(banner.queue_free)


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
