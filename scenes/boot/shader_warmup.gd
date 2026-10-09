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
## A step is taken each frame, and the title says how far along it is in a pane over it with a
## Skip on it, see [WarmupPane]. Skipped, or the title left before it is done, it stops; whatever
## was not compiled is compiled the old way, on first use.
##
## Once it has run through, it leaves a stamp beside the shader cache saying for which build of
## the game, which renderer and which card, and how many entries the cache held: while the stamp
## matches and the cache is still at least that full, there is nothing to compile and it does not
## run. A new version, another card or a cleared cache runs it again.

signal finished

const MATCH_SCENE := preload("res://scenes/match/match.tscn")
## The rooms, whose lights and air are each a shader of their own.
const ROOMS: Array[String] = ["workbench", "the_yard", "garage", "after_hours", "count_room"]
## What is put into the match once its room stands, in order, each a method here: the match
## itself, then one of everything that happens in one. A new effect, pickup, dress, HUD piece or
## material goes on this list, GAME.md 10.7, and `make warmup-check` says whether it had to.
const EFFECTS: Array[StringName] = [
	&"_start_match",
	&"_nitro",
	&"_drift",
	&"_explosion",
	&"_burst",
	&"_ring",
	&"_stain",
	&"_bomb",
	&"_turret",
	&"_shots",
	&"_marks",
	&"_chips",
	&"_item_box",
	&"_floor_joker",
	&"_die",
	&"_fireworks",
	&"_burst_a_shell",
	&"_smoke_machine",
	&"_tracks",
	&"_dressed_karts",
	&"_finishes",
	&"_hud",
	&"_printed",
	&"_boxed_slabs",
	&"_tutorial_pieces",
	&"_story_rooms",
	&"_closer_looks",
]
## Frames left running after the last step, for what was put down to draw its first frames.
const SETTLE := 12
## The viewport's size: a shader compiles the same at any size, and pixels cost.
const SIZE := Vector2i(160, 90)
## How the karts are dressed, one of each trail and hat between them, GAME.md 4.4.
const STYLES: Array = [[0, 1, 1, 0], [1, 2, 2, 1], [2, 3, 3, 2], [3, 4, 0, 3]]
## Buses quiet while it runs: the karts idle and the fireworks go off in the viewport.
const QUIET: Array[StringName] = [Buses.SFX, Buses.KART]
## Where Godot keeps what it compiled, and where the stamp saying it has all been compiled goes.
const CACHE_DIR := "user://shader_cache"
const STAMP_PATH := "user://shader_warmup.cfg"

## Whether this run has warmed up already: once a start, kept across the screens the title comes
## back from.
static var done := false
## Runs headless too, for the tests: nothing is drawn, but every step is taken.
static var force := false
## Where the stamp is read and written; the tests point it at a file of their own.
static var stamp_path := STAMP_PATH

## How far along it is, 0 to 1.
var progress := 0.0

var _viewport: SubViewport
var _lighting: ArenaEnvironment
var _match: Match
var _show: Fireworks
var _steps: Array[Callable] = []
var _at := 0
var _settle := SETTLE
var _muted := false


## Starts the warm-up under [param parent], once a run, and returns it, or null when there is
## nothing to compile here: headless, or done already this run.
static func add_to(parent: Node) -> ShaderWarmup:
	if done or (Game.is_headless() and not force) or stamped():
		done = true
		return null
	var warmup := ShaderWarmup.new()
	warmup.name = "ShaderWarmup"
	parent.add_child(warmup)
	return warmup


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
	_stamp()
	finished.emit()
	queue_free()


## Whether the stamp says this build has been through here on this renderer and card, and the
## cache still holds what it held then.
static func stamped() -> bool:
	var stamp := ConfigFile.new()
	if stamp.load(stamp_path) != OK:
		return false
	if stamp.get_value("warmup", "key", "") != _key():
		return false
	return cache_entries() >= int(stamp.get_value("warmup", "entries", 0))


## Leaves the stamp: what this run compiled for, and how full the cache is now.
func _stamp() -> void:
	var stamp := ConfigFile.new()
	stamp.set_value("warmup", "key", _key())
	stamp.set_value("warmup", "entries", cache_entries())
	stamp.save(stamp_path)


## What the compiled shaders are good for: this build of the game, on this renderer, on this
## card, with this many steps in the plan. Any of the four changing means compiling again.
static func _key() -> String:
	return (
		"%s|%s|%s|%d"
		% [
			Game.version(),
			RenderingServer.get_current_rendering_method(),
			RenderingServer.get_video_adapter_name(),
			plan_length(),
		]
	)


## How many files the shader cache holds, in every folder of it: none where there is no cache.
static func cache_entries() -> int:
	return _files_under(CACHE_DIR)


static func _files_under(path: String) -> int:
	var dir := DirAccess.open(path)
	if dir == null:
		return 0
	var count := 0
	dir.list_dir_begin()
	var name := dir.get_next()
	while not name.is_empty():
		if dir.current_is_dir():
			count += _files_under(path.path_join(name))
		else:
			count += 1
		name = dir.get_next()
	dir.list_dir_end()
	return count


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
	for step: StringName in EFFECTS:
		steps.append(Callable(self, step))
	for room: String in ROOMS:
		steps.append(_dress.bind(room))
	return steps


## How many steps the plan has, without a match to run them on: the room's phases, the effects
## and the rooms. In the stamp, so a step added to the plan runs on a machine that has stamped.
static func plan_length() -> int:
	var arena := Arena.new()
	var phases := arena.build_steps().size()
	arena.free()
	return phases + EFFECTS.size() + ROOMS.size()


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


## The tutorial's own pieces, GAME.md 9.4a, each a material of its own: a gate, opening, the arrow
## on the floor, a pad of the steering room and a traffic light.
func _tutorial_pieces() -> void:
	var gate := Gate.new()
	_match.add_child(gate)
	gate.build(_spot(Vector3(6.0, 0.0, -3.0)), Vector3(5.0, 1.0, 1.25))
	gate.open()
	var arrow := GuideArrow.add_to(_match)
	arrow.kart = _kart(0)
	arrow.point_at(_spot(Vector3(0.0, 0.0, -30.0)))
	ModePad.add_to(_match, _spot(Vector3(-6.0, 0.0, -3.0)), Settings.DRIVE_SIMPLE)
	TrafficLight.add_to(_match, _spot(Vector3(-6.0, 0.0, 3.0))).set_green()
	Hologram.add_to(_match, _spot(Vector3(0.0, 0.0, 6.0)), Vector3(2.5, 1.0, 0.3))


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


## A show, with its first shell sent up at once rather than when the show would send it.
func _fireworks() -> void:
	_show = Fireworks.celebrate(_match, _match.arena.bounds(), Palette.player_color(0), 2.0)
	_show._launch()


## The shell broken open now: the break is the one place the game draws particles with trails,
## which is a shader of its own, and a shell takes a second to climb that this does not wait.
func _burst_a_shell() -> void:
	if _show == null or not is_instance_valid(_show):
		return
	for shell: Node in _show.get_children():
		if shell is Fireworks.Shell:
			(shell as Fireworks.Shell)._break()


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


## The finishes of the loyalty program's editions, GAME.md 8.9: one shader for all three, laid
## over a kart's paint.
func _finishes() -> void:
	var sheen := MeshInstance3D.new()
	sheen.mesh = BoxMesh.new()
	var under := StandardMaterial3D.new()
	under.next_pass = KartDress.finish_material(1)
	sheen.material_override = under
	sheen.position = _spot(Vector3(-6.0, 0.5, -6.0))
	_match.add_child(sheen)


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


## A picture printed on a thing, GAME.md 8.1: the chip stacks and cards of the card room and the
## Grand Prix finale, the one textured surface a match on the home table never shows.
func _printed() -> void:
	var surfaces := _match.arena.surfaces
	var stack := MeshInstance3D.new()
	var coin := CylinderMesh.new()
	coin.top_radius = 0.4
	coin.bottom_radius = 0.4
	coin.height = 0.1
	coin.radial_segments = 16
	coin.rings = 1
	stack.mesh = coin
	stack.material_override = surfaces.printed(Surfaces.CHIP_FACE, Palette.CHIP_RED)
	stack.position = _spot(Vector3(5.0, 0.05, 5.0))
	_match.add_child(stack)
	var card := MeshInstance3D.new()
	var face := BoxMesh.new()
	face.size = Vector3(0.6, 0.02, 0.9)
	card.mesh = face
	card.material_override = surfaces.printed(Surfaces.CARD_BACK)
	card.position = _spot(Vector3(6.0, 0.01, 5.0))
	_match.add_child(card)


## The table's wood and the floor's felt on a box, GAME.md 10.7: the arena lays them on meshes it
## builds itself, without tangents, and the Grand Prix finale lays the same wood on a BoxMesh,
## which has them. Godot compiles a material's shader per vertex layout, so the one material is
## two shaders, and a finale was the first to draw the second.
func _boxed_slabs() -> void:
	var surfaces := _match.arena.surfaces
	for skin: Material in [surfaces.surround(), surfaces.floor_top()]:
		var slab := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(2.0, 0.3, 2.0)
		slab.mesh = box
		slab.material_override = skin
		slab.position = _spot(Vector3(-7.0, 0.15, 5.0))
		_match.add_child(slab)


## The story's rooms, STORY.md 6.1 and 3.9: the lettering it puts up in its own light, a lit
## poster's, the Yard's sign and the Count Room's monitor, which is a shader of its own; and the
## Count Room's racks and monitors, each one too, so the Final Hand does not hitch on its first
## frame.
func _story_rooms() -> void:
	var lit := Label3D.new()
	lit.text = StoryLines.MONITOR
	lit.font = Type.display_font()
	lit.shaded = false
	lit.double_sided = false
	lit.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	lit.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	lit.position = _spot(Vector3(-4.0, 1.5, 5.0))
	_match.add_child(lit)
	var room: RoomLook = load("res://data/rooms/count_room.tres")
	var rack := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(2.0, 2.0, 2.0)
	rack.mesh = box
	rack.material_override = CountKit.leds(room)
	rack.position = _spot(Vector3(-5.0, 1.0, 6.0))
	_match.add_child(rack)
	# And as the room has its racks, baked into one mesh, which is a layout of its own.
	var baked := MeshInstance3D.new()
	baked.mesh = Bake.joined([[box, Transform3D.IDENTITY]])
	baked.material_override = rack.material_override
	baked.position = _spot(Vector3(-7.0, 1.0, 6.0))
	_match.add_child(baked)
	var screen := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(1.6, 1.0)
	screen.mesh = quad
	screen.material_override = CountKit.screen(room, 0.0)
	screen.position = _spot(Vector3(-3.0, 1.0, 6.0))
	_match.add_child(screen)
	# The House's word worn into the road, which every room's floor carries, STORY.md 6.1.
	var road := RoadPaint.make(
		StoryLines.at(StoryLines.ROAD, 0, ""), Vector2(4.0, 2.0), room.marking
	)
	road.position = _spot(Vector3(-11.0, 0.02, 6.0))
	_match.add_child(road)
	# Its floor and the table it stands on, in its own surfaces.
	var surfaces := Surfaces.new(room)
	for skin: Material in [surfaces.surround(), surfaces.floor_top()]:
		var slab := MeshInstance3D.new()
		slab.mesh = Bake.joined([[box, Transform3D.IDENTITY]])
		slab.material_override = skin
		slab.position = _spot(Vector3(-9.0, 1.0, 6.0))
		_match.add_child(slab)
	# One of Kit's notes lying on the floor, with its halo and its glint, STORY.md 7.1.
	var note := StoryNote.make(1, &"workbench", surfaces)
	note.position = _spot(Vector3(-13.0, 0.0, 6.0))
	_match.add_child(note)


## The light and the air of [param room], each a shader of its own for the sky, the fog and the
## glow.
func _dress(room: String) -> void:
	_lighting.dress(load("res://data/rooms/%s.tres" % room))


## What is looked at closer over the title, GAME.md 8.1a: the vignette the license, Kit's folder
## and a note are held up over; the turn that holds the license and a note up toward the eye, the
## page that turns over in the folder and the driving school's book, and the hologram on the
## license, which the title only shows once there is one. `make warmup-check` opens them all.
func _closer_looks() -> void:
	var layer := CanvasLayer.new()
	layer.name = "CloserLooks"
	_match.add_child(layer)
	layer.add_child(MenuTheme.closer_shade(0.7))
	for shader: Shader in [TiltedCard.SHADER, NotesFolder.TURN_SHADER, LicenseCard.HOLOGRAM_SHADER]:
		var worn := ColorRect.new()
		worn.size = Vector2(32.0, 32.0)
		var material := ShaderMaterial.new()
		material.shader = shader
		worn.material = material
		layer.add_child(worn)
