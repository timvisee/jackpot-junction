class_name Tutorial
extends Node3D
## The tutorial, GAME.md 9.4a: a map of rooms in a row, each a lesson, joined by gates, with a
## checklist in the top right, a hint over the kart and the HUD arriving a piece at a time. The
## room is an ordinary match on the tutorial map, the way the Garage of 9.4 is: one player, two
## parked karts for the jokers lesson and two bots for the fight at the end, no clock, and no
## Cursed joker in the deck. The lessons run over it, see [TutorialRun]. A player who has never
## said how they drive is asked before the kart will move. It is the driving test of the driving
## school, see [DrivingSchool], and ends on the license, see [LicenseScreen].

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
## How long the fireworks over the room go on at the end, and how long after the bang the license
## comes up.
const FIREWORKS_FOR := 8.0
const LICENSE_AFTER := 2.4

var match_node: Match
var run: TutorialRun
var layer: CanvasLayer
var menu: PauseMenu
## The license, once the test is passed.
var license: LicenseScreen
## Whether the kart is held still for the question of how to drive, every tick, since the match
## lets its karts go as it gets going.
var holding := false
## What the player does in here, counted into their profile's statistics as they leave, GAME.md
## 8.5, though no map was played, see [method leave_record].
var record: MatchRecord
## The pause menu's Skip lesson, gone from the fight on: the fight is not skipped, and nothing
## after it is a lesson.
var _skip_entry: Button


func _ready() -> void:
	DrivingSchool.underway = true
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
	await LoadingScreen.put_up(self, match_node, "Driving test")
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.ANY, 0)]
	for i: int in TutorialJokers.DUMMIES:
		inputs.append(DummyInput.new())
	for i: int in TutorialFight.BOTS:
		inputs.append(BotInput.new())
	# The player drives the kart they dressed and answers to the name they gave, GAME.md 4.4.
	var names: Array[String] = [Game.settings.player_names[0]]
	var colors := MatchConfig.favorite_first(Game.settings.seat_color(0), inputs.size())
	match_node.start(inputs, 0, colors, names, [Game.settings.kart_styles[0]])
	# The driving school's dressing, GAME.md 9.4a: the cones, the signs and the rest of it, and the
	# L-plate on the back of the kart for the whole test.
	SchoolProps.add_to(match_node.arena)
	SchoolInspectors.add_to(match_node.arena, match_node.slots[0].kart)
	record = MatchRecord.add_to(match_node)
	record.maps = false
	KartVisuals.learner_plate(match_node.slots[0].kart)
	# A room for learning in, not a nightclub, as the Garage is.
	match_node.arena.disco.enabled = false
	match_node.arena.crowd.enabled = false
	match_node.arena.billboards.visible = false
	# The camera follows the player alone: the match frames every kart, and the parked karts and
	# the penned bots are rooms away.
	var followed: Array[Node3D] = [match_node.slots[0].kart]
	match_node.camera_rig.targets = followed
	match_node.camera_rig.follow_close(CAMERA)
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
	_skip_entry = menu.add_entry("Skip lesson", run.skip)
	# A debug build may skip the whole test, to the license coming up, to look at that end of it.
	if OS.is_debug_build():
		menu.add_entry("Skip to end", run.skip_to_end, _skip_entry)
	run.lesson_started.connect(_on_lesson_started)
	_ask_how_to_drive()
	loaded.emit()


func _exit_tree() -> void:
	Turret.hunts_targets = false
	DrivingSchool.underway = false
	leave_record()


## The school is left, for the next room or out of the game: what the player did in it goes into
## their profile, written once. Only the school the game is in, which a test's never is, and never
## headless, which a player never is and a smoke run of the school always is: a smoke run wrote
## its few seconds into the player's own statistics, and saved their settings.
func leave_record() -> void:
	if record == null or Game.is_headless() or not is_inside_tree():
		return
	if get_tree().current_scene == self:
		record.record()


## The deck without its Cursed cards, GAME.md 9.4a: a trap is no way to meet a mechanic.
static func catalog_without_cursed() -> JokerCatalog:
	var kept := JokerCatalog.new()
	for joker: Joker in CATALOG.jokers:
		if joker.kind != Joker.Kind.CURSED:
			kept.jokers.append(joker)
	return kept


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


## The fight is on: the pause menu's Skip lesson goes, for good.
func _on_lesson_started(index: int) -> void:
	if not run.lessons[index].skippable and is_instance_valid(_skip_entry):
		_skip_entry.visible = false


## Passed, GAME.md 9.4a: remembered, with a fanfare and fireworks over the room, and a moment
## after the bang the license comes up, see [LicenseScreen], numbered once and for good. What the
## exam earned is endorsed on it, on a retake added to what was endorsed before, nothing taken off.
func _on_finished() -> void:
	var settings := Game.settings
	settings.tutorial_done = true
	if settings.license_number.is_empty():
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		settings.license_number = LicenseCard.new_number(rng)
		settings.license_date = LicenseCard.today()
		settings.license_holder = run.slot().display_name()
		settings.license_endorsements.clear()
		settings.license_plate = LicensePlate.suggest(
			settings.license_holder, settings.license_number
		)
	var fight := run.lessons[run.lessons.size() - 1] as TutorialFight
	if fight != null:
		var earned := fight.endorsements()
		for word: String in earned:
			if earned[word] and word not in settings.license_endorsements:
				settings.license_endorsements.append(word)
	settings.save_to_disk()
	Audio.play_sfx(&"fanfare", -4.0, 0.0)
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
	var wait := create_tween()
	wait.tween_interval(LICENSE_AFTER)
	wait.tween_callback(issue_license)


## The license up over the room: the kart held, the checklist and the pause menu gone, since
## the test is over and the screen has the controls.
func issue_license() -> void:
	if license != null or run == null:
		return
	holding = true
	var kart := run.kart()
	kart.frozen = true
	run.list.visible = false
	run.hint.clear()
	if menu != null and is_instance_valid(menu):
		menu.queue_free()
		menu = null
	# Every endorsement the license carries, a retake's added to those from before.
	var earned: Dictionary[String, bool] = {}
	for word: String in TutorialFight.ENDORSEMENTS:
		earned[word] = word in Game.settings.license_endorsements
	license = LicenseScreen.add_to(
		layer,
		run.slot().display_name(),
		Game.settings.license_number,
		Game.settings.license_date,
		kart.color_index,
		kart.style,
		earned,
		Palette.player_color(kart.color_index)
	)
