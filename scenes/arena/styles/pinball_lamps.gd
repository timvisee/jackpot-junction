class_name PinballLamps
extends MultiMeshInstance3D
## The Arcade's lamps that answer the game, GAME.md 8.1c: the inserts a pinball machine lights as
## play goes on, laid as light over their printed selves, [PinballInserts], which are the dark
## plastic the bulbs sit under. A coin pad's ring of the coin's blue is lit while the pad holds a
## chip or a die and goes dark once it is taken, flashing up as it lights; an item pad's warm disc
## the same for its item box; the chevrons down every turbo lane chase slowly the way the lane
## fires, and a run of light goes out down it as a kart rides its plate; and a Jackpot's arrow is
## lit while that Jackpot is the one growing, and pulses once it holds a lot, GAME.md 3.5. For a
## player who asked for fewer flashes, 8.5, they hold steady: a lamp eases on and off without its
## flash, the chevrons hold their run brightest by the plate and swell rather than run, and the
## arrow of a Jackpot that holds a lot is a little brighter rather than pulsing.
##
## Cheap by rule, 10.7: no light in it, only flat faces of light a hair over the floor's print and
## added to it, every lamp an instance of the one [MultiMesh] drawn by pinball_lamps.gdshader,
## which is one draw for the lot. Which shape a lamp is, how lit, its flash and its place in a
## chase are its instance's custom data, and the chase runs in the shader on its own clock. The
## script writes a lamp only when what it shows changes, and eases it for the moment it takes: a
## pickup put down on a pad or taken off it, a kart driving onto a plate, and the Jackpots, looked
## at a few times a second. What lies on a pad is what lies in the arena's pickups on every screen,
## the host's own and a client's sent to it, GAME.md 10.3, so every screen lights the same lamps
## and nothing more goes over the wire for it.

enum Kind { COIN, ITEM, CHEVRON, ARROW }

const SHADER := preload("res://scenes/arena/styles/pinball_lamps.gdshader")
## How high over the floor the lamps lie: a hair, under the pads' inlays, [constant
## ArenaPads.LIFT], and under anything dropped on the floor, so they hide under both.
const LIFT := 0.004
## How near a pad's middle a pickup lies for it to be what the pad holds, in meters. A pad puts
## what it holds down on its very middle, on every screen.
const ON_PAD := 0.15
## Each kind's light, in the inks the inserts are printed in, and how strong it is.
const LIGHTS: Dictionary[Kind, Color] = {
	Kind.COIN: PinballInserts.COIN_LIT,
	Kind.ITEM: PinballInserts.ITEM_LIT,
	Kind.CHEVRON: PinballInserts.AMBER_LIT,
	Kind.ARROW: PinballInserts.ARROW,
}
const STRENGTH: Dictionary[Kind, float] = {
	Kind.COIN: 0.45,
	Kind.ITEM: 0.35,
	Kind.CHEVRON: 0.4,
	Kind.ARROW: 0.35,
}
## How far past its edge the light of each kind reaches on the coat, in cells, and how strong it
## is beside the insert, of the insert's own.
const HALO_REACH: Dictionary[Kind, float] = {
	Kind.COIN: 0.55,
	Kind.ITEM: 0.55,
	Kind.CHEVRON: 0.42,
	Kind.ARROW: 0.6,
}
const HALO_STRENGTH: Dictionary[Kind, float] = {
	Kind.COIN: 0.8,
	Kind.ITEM: 0.5,
	Kind.CHEVRON: 0.4,
	Kind.ARROW: 0.4,
}
## How long a lamp takes to light, how long its flash takes to fade, how long it takes to go dark,
## and how long the run of light down a lane lasts, in seconds.
const LIGHT_UP := 0.12
const FLASH := 0.4
const GO_DARK := 0.35
const LAUNCH := 0.7
## How quickly a Jackpot's arrow comes on and goes off, and starts and stops pulsing, a second.
const ARROW_EASE := 2.5
## How often the Jackpots and the player's wish for fewer flashes are looked at, in seconds.
const LOOK_EVERY := 0.25

## The instances' custom data, as last written: [kind, how lit, flash, place in a chase]; and
## where each lies, over the arena's floor.
var _state := PackedColorArray()
var _places: Array[Transform3D] = []
## What each lamp is easing toward, how lit and its flash, and the lamps easing.
var _want_lit := PackedFloat32Array()
var _want_flash := PackedFloat32Array()
var _easing: Dictionary[int, bool] = {}
## The coin and item pads' lamps by the pad's cell, and how many pickups each lamp's pad holds.
var _pad_lamps: Dictionary[Vector2i, int] = {}
var _held: Dictionary[int, int] = {}
## The chevrons' lamps down each turbo pad's lane, by the pad's place in the arena's turbo pads.
var _lanes: Array[PackedInt32Array] = []
## Each Jackpot's arrow, by the Jackpot's index, and the Jackpots.
var _arrows: Dictionary[int, int] = {}
var _zones: Array[JackpotZone] = []
var _grid: ArenaGrid
var _look: ShaderMaterial
var _steady := false


## Lays the lamps of [param arena]'s Arcade over its floor and wires them to the game.
static func lay(arena: Arena) -> PinballLamps:
	var lamps := PinballLamps.new()
	lamps.name = "Lamps"
	lamps._build(arena)
	arena.add_child(lamps)
	return lamps


## Whether lamp [param index] is lit, or lighting, as opposed to dark or going dark.
func is_lit(index: int) -> bool:
	return _want_lit[index] > 0.5


## How lit lamp [param index] is drawn right now, 0 to 1, flash aside.
func lit_now(index: int) -> float:
	return _state[index].g


## The lamp of the coin or item pad on [param cell], or -1.
func pad_lamp(cell: Vector2i) -> int:
	return _pad_lamps.get(cell, -1)


## The chevrons' lamps down the lane of the arena's [param pad]th turbo pad, nearest it first.
func lane(pad: int) -> PackedInt32Array:
	return _lanes[pad] if pad < _lanes.size() else PackedInt32Array()


## The arrow pointing out the Jackpot of [param index], or -1.
func arrow(index: int) -> int:
	return _arrows.get(index, -1)


## What lamp [param index] is drawn with: its kind, how lit, its flash and its place in a chase.
func state(index: int) -> Color:
	return _state[index]


## Where lamp [param index] lies over the floor, its square's x the way it points.
func place(index: int) -> Transform3D:
	return _places[index]


## The look every lamp is drawn in.
func look() -> ShaderMaterial:
	return _look


func _build(arena: Arena) -> void:
	_grid = arena.grid
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var lamps: Array[Array] = []
	for pad: CoinPad in arena.coin_pads:
		var at := _grid.cell_of(pad.position)
		_pad_lamps[at] = lamps.size()
		lamps.append([Kind.COIN, Vector2(at) + Vector2.ONE * 0.5, Vector2i.RIGHT, 0.0, 1.0])
	for pad: PowerUpPad in arena.power_pads:
		var at := _grid.cell_of(pad.position)
		_pad_lamps[at] = lamps.size()
		lamps.append([Kind.ITEM, Vector2(at) + Vector2.ONE * 0.5, Vector2i.RIGHT, 0.0, 1.0])
	for _section: Rect2i in _grid.turbo_sections():
		_lanes.append(PackedInt32Array())
	for chevron: Array in PinballInserts.chevrons(_grid):
		_lanes[chevron[4]].append(lamps.size())
		var reach := PinballInserts.chevron_reach(chevron[2])
		lamps.append([Kind.CHEVRON, chevron[0], chevron[1], float(chevron[3]), reach])
	for pointer: Array in PinballInserts.arrows(_grid):
		var tip: Vector2 = pointer[0]
		var tail: Vector2 = pointer[1]
		_arrows[pointer[2]] = lamps.size()
		lamps.append([Kind.ARROW, (tip + tail) * 0.5, tip - tail, 0.0, 1.0])
	multimesh = _instances(lamps)
	_look = _material(arena)
	material_override = _look
	_steady = _calm()
	_look.set_shader_parameter(&"steady", 1.0 if _steady else 0.0)
	_zones = arena.jackpot_zones
	# The chevrons are always lit, chasing, and the rest dark until the game lights them.
	for lane_lamps: PackedInt32Array in _lanes:
		for index: int in lane_lamps:
			_want_lit[index] = 1.0
			_write(index, 1.0, 0.0)
	arena.pickups.child_entered_tree.connect(_on_put_down)
	for pickup: Node in arena.pickups.get_children():
		_on_put_down(pickup)
	for i: int in arena.turbo_pads.size():
		arena.turbo_pads[i].body_entered.connect(_on_plate.bind(i))
	var watch := Timer.new()
	watch.name = "Watch"
	watch.wait_time = LOOK_EVERY
	watch.autostart = true
	watch.timeout.connect(_look_round)
	add_child(watch)
	set_process(false)


## One instance for every lamp of [param lamps], each [kind, middle in cells, the way it points,
## its place in a chase, how far across a chevron reaches], dark.
func _instances(lamps: Array[Array]) -> MultiMesh:
	var many := MultiMesh.new()
	many.transform_format = MultiMesh.TRANSFORM_3D
	many.use_colors = true
	many.use_custom_data = true
	many.instance_count = lamps.size()
	var face := PlaneMesh.new()
	face.size = Vector2.ONE
	many.mesh = face
	_state.resize(lamps.size())
	_want_lit.resize(lamps.size())
	_want_flash.resize(lamps.size())
	var cell := _grid.cell_size
	var corner := Vector2(_grid.width, _grid.height) * 0.5
	for i: int in lamps.size():
		var lamp: Array = lamps[i]
		var kind: Kind = lamp[0]
		var middle: Vector2 = (lamp[1] as Vector2 - corner) * cell
		var way := Vector2(lamp[2]).normalized()
		var along := Vector3(way.x, 0.0, way.y)
		var square := _square(kind) * 2.0 * cell
		var basis := Basis(along * square.x, Vector3.UP, along.cross(Vector3.UP) * square.y)
		_places.append(Transform3D(basis, Vector3(middle.x, LIFT, middle.y)))
		many.set_instance_transform(i, _places[i])
		var light := LIGHTS[kind].srgb_to_linear() * STRENGTH[kind]
		light.a = lamp[4]
		many.set_instance_color(i, light)
		_state[i] = Color(float(kind), 0.0, 0.0, lamp[3])
		many.set_instance_custom_data(i, _state[i])
	return many


## Half the square each kind of lamp is drawn in, along the way it points and across it, in
## cells: the insert and the light it throws round it.
static func _square(kind: Kind) -> Vector2:
	var reach: float = HALO_REACH[kind]
	match kind:
		Kind.COIN:
			return Vector2.ONE * (PinballInserts.CHIP_RING + reach)
		Kind.ITEM:
			return Vector2.ONE * (PinballInserts.ITEM_DISC + reach)
		Kind.CHEVRON:
			var along := PinballInserts.CHEVRON_ALONG * 0.5 + PinballInserts.CHEVRON_ARM
			return Vector2(along, PinballInserts.CHEVRON_ACROSS * 0.5) + Vector2.ONE * reach
	return (
		Vector2(PinballInserts.ARROW_LONG * 0.5, PinballInserts.ARROW_HEAD * 0.5)
		+ Vector2.ONE * reach
	)


## The look every lamp of [param arena] is drawn in, its shapes those [PinballInserts] prints.
func _material(arena: Arena) -> ShaderMaterial:
	var made := ShaderMaterial.new()
	made.shader = SHADER
	made.set_shader_parameter(&"coin_ring", Vector2(PinballInserts.CHIP, PinballInserts.CHIP_RING))
	made.set_shader_parameter(&"item_disc", PinballInserts.ITEM_DISC)
	made.set_shader_parameter(
		&"chevron", Vector2(PinballInserts.CHEVRON_ALONG, PinballInserts.CHEVRON_ARM)
	)
	made.set_shader_parameter(&"arrow", PinballInserts.arrow_shape())
	made.set_shader_parameter(&"coin_square", _square(Kind.COIN))
	made.set_shader_parameter(&"item_square", _square(Kind.ITEM))
	made.set_shader_parameter(&"chevron_square", _square(Kind.CHEVRON))
	made.set_shader_parameter(&"arrow_square", _square(Kind.ARROW))
	var reach := Vector4()
	var strength := Vector4()
	for kind: Kind in [Kind.COIN, Kind.ITEM, Kind.CHEVRON, Kind.ARROW]:
		reach[kind] = HALO_REACH[kind]
		strength[kind] = HALO_STRENGTH[kind]
	made.set_shader_parameter(&"halo_reach", reach)
	made.set_shader_parameter(&"halo_strength", strength)
	made.set_shader_parameter(&"fog_density", arena.room.fog_density if arena.room else 0.0)
	return made


## A pickup put down in the arena: if it lies on a pad's middle, the pad's lamp lights until it
## goes. A chip or a die lights a coin pad's ring, an item box an item pad's disc.
func _on_put_down(node: Node) -> void:
	var pickup := node as Pickup
	if pickup == null:
		return
	var cell := _grid.cell_of(pickup.position)
	var index: int = _pad_lamps.get(cell, -1)
	if index < 0:
		return
	var middle := _grid.cell_center(cell)
	if Vector2(pickup.position.x - middle.x, pickup.position.z - middle.z).length() > ON_PAD:
		return
	var kind := int(_state[index].r) as Kind
	var fits := pickup is ItemBox if kind == Kind.ITEM else (pickup is Chip or pickup is MultDie)
	if not fits:
		return
	pickup.tree_exiting.connect(_on_taken.bind(index), CONNECT_ONE_SHOT)
	_held[index] = _held.get(index, 0) + 1
	if _held[index] == 1:
		_light(index, true)


## What lay on a pad's middle gone from the floor, taken or swept off.
func _on_taken(index: int) -> void:
	_held[index] = maxi(_held.get(index, 0) - 1, 0)
	if _held[index] == 0:
		_light(index, false)


## A kart driving onto the arena's [param pad]th turbo pad: a run of light out down its lane.
func _on_plate(body: Node3D, pad: int) -> void:
	if not body is Kart:
		return
	for index: int in lane(pad):
		_ease(index, 1.0, 1.0, true)


## Lamp [param index] lit or dark, and a lamp lighting flashes as it does.
func _light(index: int, on: bool) -> void:
	_ease(index, 1.0 if on else 0.0, 1.0 if on and not _steady else 0.0, on)


## Lamp [param index] easing toward [param lit] from where it is, its flash set to [param flash]
## where [param restart] says so and fading from there.
func _ease(index: int, lit: float, flash: float, restart: bool) -> void:
	_want_lit[index] = lit
	if restart:
		_write(index, _state[index].g, flash)
	_want_flash[index] = 0.0
	_easing[index] = true
	set_process(true)


func _process(delta: float) -> void:
	for index: int in _easing.keys():
		var now := _state[index]
		var kind := int(now.r) as Kind
		var lit := now.g
		var flash := now.b
		var want := _want_lit[index]
		if kind == Kind.ARROW:
			lit = move_toward(lit, want, delta * ARROW_EASE)
			flash = move_toward(flash, _want_flash[index], delta * ARROW_EASE)
		else:
			lit = move_toward(lit, want, delta / (LIGHT_UP if want > lit else GO_DARK))
			var fade := LAUNCH if kind == Kind.CHEVRON else FLASH
			flash = move_toward(flash, _want_flash[index], delta / fade)
		_write(index, lit, flash)
		if is_equal_approx(lit, want) and is_equal_approx(flash, _want_flash[index]):
			_easing.erase(index)
	if _easing.is_empty():
		set_process(false)


## The Jackpots' arrows, each lit while its Jackpot is the one growing and pulsing once it holds
## as much as turns its light amber, GAME.md 3.5; and whether the player has asked for fewer
## flashes since, 8.5.
func _look_round() -> void:
	var calm := _calm()
	if calm != _steady:
		_steady = calm
		_look.set_shader_parameter(&"steady", 1.0 if calm else 0.0)
	for zone: JackpotZone in _zones:
		var index: int = _arrows.get(zone.index, -1)
		if index < 0 or not is_instance_valid(zone):
			continue
		var lit := 1.0 if zone.active else 0.0
		var amber := zone.rules.jackpot_amber if zone.rules != null else 0
		var full := 1.0 if zone.active and amber > 0 and zone.whole_chips() >= amber else 0.0
		if lit != _want_lit[index] or full != _want_flash[index]:
			_want_lit[index] = lit
			_want_flash[index] = full
			_easing[index] = true
			set_process(true)


static func _calm() -> bool:
	return Game.settings != null and Game.settings.flash_reduction


func _write(index: int, lit: float, flash: float) -> void:
	var now := _state[index]
	now.g = lit
	now.b = flash
	_state[index] = now
	multimesh.set_instance_custom_data(index, now)
