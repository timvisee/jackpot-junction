class_name ShaderWarmup
extends Node
## Compiles the game's shaders before a match needs them, GAME.md 10.7. Godot compiles a shader
## the first time something wearing it is drawn, which on a phone is tens to hundreds of
## milliseconds, and it happened mid-race: the first bomb, the first nitro, the first chip on
## the floor each cost a frame. So behind the title a match is started on a viewport a few
## pixels wide and one of everything the game draws is put into it, a step a frame: karts in
## every dress, every effect, every pickup, every room's light. Each shader is compiled while the
## title is up, and Godot keeps what it compiled on disk, so the first start pays and every start
## after it runs this in a moment.
##
## Nothing here waits. A step is taken each frame and the menu goes on answering in between, with
## a bar on the title saying how far along it is, see [method strip]. Leaving the title before it
## is done stops it; whatever was not compiled is compiled the old way, on first use.

signal finished

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
## The rooms, whose lights and air are each a shader of their own.
const ROOMS: Array[String] = ["workbench", "the_yard", "garage", "after_hours"]
## Frames left running after the last step, for what was put down to draw its first frames.
const SETTLE := 12
## The viewport's size: a shader compiles the same at any size, and pixels cost.
const SIZE := Vector2i(160, 90)
## How the karts are dressed, one of each trail and hat between them, GAME.md 4.4.
const STYLES: Array = [[0, 1, 1, 0], [1, 2, 2, 1], [2, 3, 3, 2], [3, 4, 0, 3]]
## Buses quiet while it runs: the karts idle and the fireworks go off in the viewport.
const QUIET: Array[StringName] = [Buses.SFX, Buses.KART]

## Whether this run has warmed up already: once a start, kept across the screens the title comes
## back from.
static var done := false
## Runs headless too, for the tests: nothing is drawn, but every step is taken.
static var force := false

## How far along it is, 0 to 1.
var progress := 0.0

var _viewport: SubViewport
var _lighting: ArenaEnvironment
var _match: Match
var _steps: Array[Callable] = []
var _at := 0
var _settle := SETTLE
var _muted := false


## Starts the warm-up under [param parent], once a run, and returns it, or null when there is
## nothing to compile here: headless, or done already this run.
static func add_to(parent: Node) -> ShaderWarmup:
	if done or (Game.is_headless() and not force):
		return null
	var warmup := ShaderWarmup.new()
	warmup.name = "ShaderWarmup"
	parent.add_child(warmup)
	return warmup


## The line on the title that says what is going on, GAME.md 3.8: "Compiling shaders" over a
## thin bar, bottom left above the credits, gone a moment after the bar is full.
static func strip(warmup: ShaderWarmup) -> Control:
	var strip := VBoxContainer.new()
	strip.name = "ShaderWarmupStrip"
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.add_theme_constant_override("separation", 4)
	var label := Label.new()
	label.text = "Compiling shaders"
	Type.text(label, Type.SMALL, Color(0.6, 0.6, 0.65))
	strip.add_child(label)
	var bar := HudBlock.bar(Vector2(220.0, 6.0), Palette.CHIP_GOLD)
	strip.add_child(bar)
	strip.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	strip.grow_vertical = Control.GROW_DIRECTION_BEGIN
	strip.offset_left = 16.0
	strip.offset_bottom = -44.0
	# The bar follows the progress as long as the warm-up is running, and stops with it.
	var follow := Timer.new()
	follow.wait_time = 1.0 / 30.0
	follow.autostart = true
	follow.timeout.connect(
		func() -> void:
			if is_instance_valid(warmup):
				bar.value = warmup.progress * 100.0
	)
	strip.add_child(follow)
	warmup.finished.connect(
		func() -> void:
			follow.stop()
			bar.value = 100.0
			var fade := strip.create_tween()
			fade.tween_property(strip, "modulate:a", 0.0, 0.5).set_delay(0.4)
			fade.tween_callback(strip.queue_free)
	)
	return strip


func is_done() -> bool:
	return _at >= _steps.size() and _settle <= 0


func _ready() -> void:
	_mute(true)
	_viewport = SubViewport.new()
	_viewport.name = "Behind"
	_viewport.size = SIZE
	_viewport.own_world_3d = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	# The same passes as the screen, so what is compiled here is what a match on it uses.
	var screen := get_viewport()
	_viewport.msaa_3d = screen.msaa_3d
	_viewport.screen_space_aa = screen.screen_space_aa
	_viewport.use_debanding = screen.use_debanding
	_viewport.scaling_3d_mode = screen.scaling_3d_mode
	_viewport.positional_shadow_atlas_size = screen.positional_shadow_atlas_size
	add_child(_viewport)
	_lighting = ArenaEnvironment.add_to(_viewport)
	# The match is put in now and its room built a phase a frame, the way the loading screen
	# builds one, GAME.md 8.6: built in one go it is a sixth of a second on a desktop and a
	# couple on a phone, which is long enough for the title to stop answering.
	_match = MATCH_SCENE.instantiate()
	_match.name = "Match"
	_match.arena_layout = ArenaMaps.layout(&"lucky_crossing")
	_match.hold_start = true
	_viewport.add_child(_match)
	_steps = _plan(_match.prepare_arena(true).build_steps())


func _exit_tree() -> void:
	_mute(false)


func _process(_delta: float) -> void:
	if _at < _steps.size():
		_steps[_at].call()
		_at += 1
	elif _settle > 0:
		_settle -= 1
	progress = float(_at + SETTLE - _settle) / float(_steps.size() + SETTLE)
	if is_done():
		_finish()


func _finish() -> void:
	set_process(false)
	done = true
	_mute(false)
	finished.emit()
	queue_free()


## The buses that would be heard from the viewport, quiet while it runs and back after.
func _mute(quiet: bool) -> void:
	if quiet == _muted:
		return
	_muted = quiet
	for bus: StringName in QUIET:
		var index := AudioServer.get_bus_index(bus)
		if index >= 0:
			AudioServer.set_bus_mute(index, quiet)


## One of everything, in the order it is put in: the room, [param building] it a phase a frame,
## then the match in it, then what happens in one, then the rooms it could be happening in.
func _plan(building: Array[Callable]) -> Array[Callable]:
	var steps: Array[Callable] = []
	steps.append_array(building)
	steps.append(_start_match)
	(
		steps
		. append_array(
			[
				_nitro,
				_drift,
				_explosion,
				_burst,
				_ring,
				_stain,
				_bomb,
				_turret,
				_shots,
				_marks,
				_chips,
				_item_box,
				_floor_joker,
				_die,
				_fireworks,
				_smoke_machine,
				_tracks,
				_dressed_karts,
				_hud,
			]
		)
	)
	for room: String in ROOMS:
		steps.append(_dress.bind(room))
	return steps


## The match on the home table, its room built, held in its lobby: karts standing, nothing
## moving that the steps do not move themselves. One human at the keyboard, so the HUD has a
## corner to draw.
func _start_match() -> void:
	var inputs: Array[KartInput] = [PlayerInput.new(DeviceInput.KEYBOARD, 0)]
	for i: int in 3:
		inputs.append(KartInput.new())
	_match.start(inputs, 7, [], [], STYLES)


func _kart(index: int) -> Kart:
	return _match.kart_of(index)


## A spot on the floor near the middle of the table, [param offset] from it.
func _spot(offset: Vector3) -> Vector3:
	return _match.arena.junction_position + offset


func _nitro() -> void:
	_kart(0)._flame.set_active(true)


func _drift() -> void:
	_kart(1)._sparks.set_state(true, true)
	_kart(1)._sparks.pop()


func _explosion() -> void:
	Explosion.spawn(_match, _spot(Vector3(4.0, 0.0, 3.0)), Bomb.RADIUS, Color.WHITE)


func _burst() -> void:
	Burst.spawn(_match, _spot(Vector3(-4.0, 0.0, 3.0)), Palette.player_color(1))


func _ring() -> void:
	SpawnRing.spawn(_match, _spot(Vector3(0.0, 0.0, 5.0)), Palette.player_color(2))


func _stain() -> void:
	var stain := OilStain.new()
	_match.add_child(stain)
	stain.global_position = _spot(Vector3(6.0, 0.0, -2.0))


func _bomb() -> void:
	var bomb := Bomb.new()
	bomb.color = Palette.player_color(3)
	_match.add_child(bomb)
	bomb.global_position = _spot(Vector3(-6.0, 0.0, -2.0))


func _turret() -> void:
	var turret := Turret.new()
	turret.owner_slot = 0
	turret.slot = 0
	turret.bullet_system = _match.bullets
	turret.cannon_stats = _kart(0).cannon.current_stats()
	turret.color = Palette.player_color(0)
	_match.add_child(turret)
	turret.global_position = _spot(Vector3(0.0, 0.0, -6.0))


func _shots() -> void:
	var kart := _kart(2)
	kart.cannon.fire(
		_match.bullets, 2, kart.global_position, Vector3.FORWARD, Palette.player_color(2)
	)


func _marks() -> void:
	BulletMark.spawn(_match.arena, _spot(Vector3(2.0, 0.5, -4.0)), Vector3.BACK, Color.WHITE)


func _chips() -> void:
	_match.arena.spawn_chips(_spot(Vector3(3.0, 0.0, 0.0)), 6, 0.0, 0.5, true)


func _item_box() -> void:
	var item: PowerUp = load("res://data/powerups/bomb.tres")
	_match.arena.spawn_floor_item(_spot(Vector3(-3.0, 0.0, 0.0)), item, 0.0)


func _floor_joker() -> void:
	var picked := _match.joker_catalog.offer(_match.rng, 1, [])
	if not picked.is_empty():
		_match.arena.spawn_floor_joker(_spot(Vector3(0.0, 0.0, 3.0)), picked[0], 0.0)
		_kart(0).jokers.add(picked[0])


func _die() -> void:
	_match.arena.place_drop(MultDie.new(), _spot(Vector3(0.0, 0.0, -3.0)))


func _fireworks() -> void:
	Fireworks.celebrate(_match, _match.arena.bounds(), Palette.player_color(0), 2.0)


func _smoke_machine() -> void:
	var machine := SmokeMachine.new()
	_match.add_child(machine)
	machine.position = _spot(Vector3(8.0, 0.0, 6.0))
	machine.spit(true)


## Gold tracks and ordinary ones, laid by hand under a standing kart.
func _tracks() -> void:
	var marks := _kart(2).tire_marks
	var now := Time.get_ticks_msec() * 0.001
	var from := _kart(2).global_position
	marks.gold = true
	for i: int in 4:
		marks.add_sample(0, from + Vector3(i * 0.3, 0.0, 0.0), Vector3.RIGHT, 0.5, now)
	marks.gold = false
	for i: int in 4:
		marks.add_sample(1, from + Vector3(1.5 + i * 0.3, 0.0, 0.0), Vector3.RIGHT, 0.5, now)


## What a kart wears on top of its dress: the bounty's crown, a shield, the channel ring.
func _dressed_karts() -> void:
	_kart(3).set_bounty(true)
	_kart(3).set_shielded(true)
	_kart(1).channel_progress = 0.5


## The corner of the HUD: a pot on fire, a tally, and the words and icons thrown up over a kart.
func _hud() -> void:
	if _match.hud != null and _match.hud._blocks.has(0):
		var pills: ScorePills = _match.hud._blocks[0]["pot"]
		pills.show_pot(12, 2.0, 24)
		pills.set_burning(true)
	var at := _kart(0).global_position + Vector3(0.0, 1.0, 0.0)
	FloatingText.spawn(_match, at, "+100", Palette.CHIP_GOLD)
	ChipBurst.spawn(_match, at, at + Vector3(2.0, 1.0, 0.0), 4, Palette.CHIP_GOLD)
	FloatingIcon.spawn(_match, at, Heart.broken_shapes(), Palette.player_color(0), 1.0, 1.0)


## The light and the air of [param room], each a shader of its own for the sky, the fog and the
## glow.
func _dress(room: String) -> void:
	_lighting.dress(load("res://data/rooms/%s.tres" % room))
