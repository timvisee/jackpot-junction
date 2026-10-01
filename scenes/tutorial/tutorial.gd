class_name Tutorial
extends Node3D
## The tutorial, GAME.md 9.4a: a map of rooms in a row, each a lesson, joined by gates, with a
## checklist in the top right, a hint over the kart and the HUD arriving a piece at a time. The
## room is an ordinary match on the tutorial map with one player and no clock, the way the Garage
## of 9.4 is; the lessons run over it, see [TutorialRun]. A player who has never said how they
## drive is asked before the kart will move; the portal at the end leads to the Garage.

## Given once the room is up and the lessons running, GAME.md 8.6.
signal loaded

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const LAYOUT: ArenaLayout = preload("res://data/maps/tutorial.tres")
const RULES: MatchRules = preload("res://data/match/tutorial.tres")
## How far back the camera follows: a room framed whole puts the kart too far away to see what a
## control did, GAME.md 9.4a.
const CAMERA := 26.0
const SIGN_HEIGHT := 2.7

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
	# The line over the kart is the tutorial's own, a task at a time.
	match_node.with_kart_hints = false
	match_node.power_ups = load("res://data/powerups/all.tres")
	add_child(match_node)
	await LoadingScreen.put_up(self, match_node, "Tutorial")
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.ANY, 0)]
	# The player drives the kart they dressed and answers to the name they gave, GAME.md 4.4.
	var names: Array[String] = [Game.settings.player_names[0]]
	match_node.start(inputs, 0, [], names, [Game.settings.kart_styles[0]])
	# A room for learning in, not a nightclub, as the Garage is.
	match_node.arena.disco.enabled = false
	match_node.arena.crowd.enabled = false
	match_node.arena.billboards.visible = false
	match_node.camera_rig.follow_close(CAMERA)
	for portal: Portal in match_node.arena.portals:
		# Once the physics step that saw the kart arrive is over: the room it takes down is made of
		# the bodies that step is in the middle of.
		portal.entered.connect(func(_kart: Kart) -> void: Game.go_to_garage.call_deferred())
		_sign("GARAGE", portal.global_position, Palette.NEON_CYAN)
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
	menu.add_entry("Skip step", run.skip)
	_ask_how_to_drive()
	loaded.emit()


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


## The lessons so far are done: the portal in this room leads on to the Garage.
func _on_finished() -> void:
	var at := run.cell(TutorialShoot.END_SIGN)
	_sign("THAT'S ALL FOR NOW\nmore lessons are on the way", at, Palette.CHIP_GOLD)


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
