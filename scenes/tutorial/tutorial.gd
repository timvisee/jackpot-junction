class_name Tutorial
extends Node3D
## The tutorial, GAME.md 9.4a: one open lot whose pieces rise out of the floor lesson by lesson,
## see [TestGround], with the examiner's clipboard in the top right, the control over the kart and
## the HUD arriving a piece at a time. The lot is an ordinary match on the tutorial map, the way the
## Garage of 9.4 is: one player, a parked kart for the jokers lesson and two bots for the exam at
## the end, no clock, and no Cursed joker in the deck. The lessons run over it, see [TutorialRun].
## A player who has never said how they drive is asked before the kart will move. It is the
## driving test of the driving school, see [DrivingSchool], and ends on the license, see
## [LicenseScreen].

## Given once the room is up and the lessons running, GAME.md 8.6.
signal loaded

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
const LAYOUT: ArenaLayout = preload("res://data/maps/tutorial.tres")
const RULES: MatchRules = preload("res://data/match/tutorial.tres")
const CATALOG: JokerCatalog = preload("res://data/jokers/catalog.tres")
const EASY: BotDifficulty = preload("res://data/ai/easy.tres")
## How long the fireworks over the room go on at the end, and how long after the bang the license
## comes up.
const FIREWORKS_FOR := 8.0
const LICENSE_AFTER := 2.4
## The menu's way to the end of the test in a debug build, said to be one, as the match's is.
const DEBUG_SKIP := "Debug: skip to end"

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
## 8.5, though no map was played, see [MatchRecord].
var record: MatchRecord
## The pause menu's Skip lesson, gone from the fight on: the fight is not skipped, and nothing
## after it is a lesson.
var _skip_entry: Button
## Whether the license about to be issued is this machine's first, rather than a retake's.
var _first_issue := false


func _ready() -> void:
	DrivingSchool.underway = true
	# Enrolled for the exam alone, the lessons before it are settled at once, GAME.md 9.4a.
	TutorialRun.express = DrivingSchool.express
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
	# Built without baking: the lot holds its pads, Junction and boxes back until their lessons,
	# see [RisingPiece], which takes each being a node of its own.
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
	CatalogRecord.add_to(match_node)
	LoyaltyRecord.add_to(match_node)
	# Its moments counted as any room's, but the license earned only as it is stamped, GAME.md 8.10.
	AchievementRecord.add_to(match_node, true, false)
	LostProperty.add_to(match_node, LostProperty.SCHOOL)
	KartVisuals.learner_plate(match_node.slots[0].kart)
	# A room for learning in, not a nightclub, as the Garage is.
	match_node.arena.disco.enabled = false
	match_node.arena.crowd.enabled = false
	match_node.arena.billboards.visible = false
	# The camera frames the player alone, as any room's frames its karts, GAME.md 8.2: it opens on
	# the hall and comes in on the kart, as close as it goes, keeps it out from under the HUD and
	# the clipboard and looks at nothing past the lot. The match frames every kart, and the parked
	# karts and the penned bots are not what the test is watching; the exam's bots join the shot
	# as they come up, see [method TutorialRun.release_bot], and the lesson's next spot as the kart
	# nears it, see [SpotFraming].
	var followed: Array[Node3D] = [match_node.slots[0].kart]
	match_node.camera_rig.targets = followed
	layer = CanvasLayer.new()
	layer.name = "TutorialLayer"
	# Over the HUD's layer, under the pause menu's.
	layer.layer = 6
	add_child(layer)
	run = TutorialRun.add_to(self, match_node, layer)
	# And the spot the arrow points at in the shot with it, as the kart nears it, see [SpotFraming].
	SpotFraming.add_to(run)
	run.finished.connect(_on_finished)
	DebugOverlay.add_to(self, match_node)
	DebugGrantMenu.add_to(self, match_node)
	menu = PauseMenu.add_to(self)
	menu.names_and_colors = true
	# Skip driving school where a room has Back to title, asking first, GAME.md 9.4a.
	menu.for_the_school(Game.go_to_title)
	_skip_entry = menu.add_entry("Skip lesson", run.skip)
	# A debug build may skip the whole test, to the license coming up, to look at that end of it.
	if OS.is_debug_build():
		menu.add_entry(DEBUG_SKIP, run.skip_to_end, _skip_entry)
	run.lesson_started.connect(_on_lesson_started)
	_ask_how_to_drive()
	loaded.emit()


func _exit_tree() -> void:
	Turret.hunts_targets = false
	DrivingSchool.underway = false
	DrivingSchool.express = false
	TutorialRun.express = false


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
## exam earned is endorsed on it, a retake's in place of what was endorsed before.
func _on_finished() -> void:
	var settings := Game.settings
	settings.tutorial_done = true
	_first_issue = settings.license_number.is_empty()
	if settings.license_number.is_empty():
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		settings.license_number = LicenseCard.new_number(rng)
		settings.license_date = LicenseCard.today()
		settings.license_plate = LicensePlate.suggest(
			run.slot().display_name(), settings.license_number
		)
	# The name enrolled under, a retake's as well: the card is stamped with it.
	settings.license_holder = run.slot().display_name()
	# The cones this exam knocked over, and its time, with the best kept.
	var profile := settings.profile
	profile.license_cones = run.cones
	profile.test_time = run.elapsed
	if profile.test_best <= 0.0 or run.elapsed < profile.test_best:
		profile.test_best = run.elapsed
	settings.license_endorsements.clear()
	var fight := run.lessons[run.lessons.size() - 1] as TutorialFight
	if fight != null:
		var earned := fight.endorsements()
		for word: String in earned:
			if earned[word]:
				settings.license_endorsements.append(word)
	settings.save_to_disk()
	Audio.play_sfx(&"fanfare", -4.0, 0.0)
	# Fireworks over the last room, in the player's color, the way a match won has them.
	var grid := match_node.arena.grid
	var lot := TestGround.LOT
	var across := Vector3(lot.size.x, 0.0, lot.size.y) * grid.cell_size
	var middle := grid.rect_center(lot)
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
	# Every endorsement the license carries, which is what this exam earned.
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
	# The first license turns over by itself once it is held up, so what is scratched into its
	# stripe is seen, STORY.md 6.7.
	license.shows_back = _first_issue and license.card.scratched
