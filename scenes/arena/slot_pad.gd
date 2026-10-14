class_name SlotPad
extends Area3D
## The slot machine, GAME.md 3.15: a pad on the floor with three reels set in its face. A kart
## that drives onto it with chips in its pot bets a quarter of them, and the reels spin and stop
## one after another: three sevens pay ten times the bet, any other three of a kind three times,
## a pair the bet back, and anything else nothing. A kart pulls once every ten seconds at most,
## and the machine takes one bet at a time.
##
## The host draws the reels and says what they show, [signal Events.slot_spun], and every machine
## spins its own to the same faces; the host pays once they have stopped, [signal
## Events.slot_paid]. The reels are one quad lying in the pad's face, drawn by slot_reels.gdshader
## from a strip of the six faces drawn once a run, see [class Strip]: flat on the table, so they
## never stand in front of anything, karts driving over them as over any pad.

## The six faces, in the order the strip has them from its top.
enum Face { SEVEN, CHERRY, BELL, BAR, LEMON, CHIP }

## How much of a pot's chips a pull bets, the fewest chips a pot needs for it, and how long a kart
## waits before it may pull again, in seconds.
const BET := 0.25
const LEAST_COINS := 4
const REST := 10.0
## When each reel stops, in seconds from the pull, how many faces a second a spinning reel turns,
## and how long a reel settles as it stops.
const STOPS: Array[float] = [0.6, 0.9, 1.2]
const TURN := 14.0
const SETTLE := 0.35
## How often each outcome comes up, and what it pays, in bets: three sevens, any other three of a
## kind, a pair. What is left of the odds pays nothing. A pull is worth a little more than it costs.
const SEVENS := 0.04
const SEVENS_PAY := 10
const THREE := 0.12
const THREE_PAY := 3
const PAIR := 0.34
const PAIR_PAY := 1
## The pad, across and deep, a little wider than its cell, the reels set in it, how far its words
## float over it, and the strip's pixels.
const PLATE := Vector2(2.3, 1.15)
const REELS_SIZE := Vector2(2.1, 0.95)
const WORDS_HEIGHT := 0.4
const STRIP_PIXELS := Vector2i(128, 768)
## How long a win lights the cabinet up, in seconds, three sevens twice as long.
const LIT_TIME := 1.6
const GROUP := &"slot_pads"
const LOOK: Shader = preload("res://scenes/arena/slot_reels.gdshader")

## Which slot machine of the map this is, as the events name it.
var index := 0

var _match: Match
var _material: ShaderMaterial
## What the reels show, by [enum Face], and where each stood as the spin began.
var _faces := PackedByteArray([Face.SEVEN, Face.CHERRY, Face.BELL])
var _from := Vector3(0.0, 1.0, 2.0)
## Seconds into a spin, or below zero while the machine is idle, and the reels stopped of it.
var _spin := -1.0
var _stopped := 0
## Whose bet is on the reels and how many chips.
var _slot := -1
var _bet := 0
## By slot: when it may pull again, on the engine's clock.
var _rested: Dictionary[int, float] = {}
var _lit := 0.0
var _ticked := 0.0


## Puts a slot machine on every `$` of [param arena]'s map.
static func add_to(arena: Arena) -> void:
	for i: int in arena.grid.slot_pads.size():
		var pad := SlotPad.new()
		pad.index = i
		pad.name = "SlotPad%d" % i
		pad.position = arena.grid.cell_center(arena.grid.slot_pads[i])
		arena.add_child(pad)


## What [param faces] pay, in bets.
static func pays(faces: PackedByteArray) -> int:
	if faces.size() != 3:
		return 0
	if faces[0] == faces[1] and faces[1] == faces[2]:
		return SEVENS_PAY if faces[0] == Face.SEVEN else THREE_PAY
	if faces[0] == faces[1] or faces[1] == faces[2] or faces[0] == faces[2]:
		return PAIR_PAY
	return 0


## Three faces drawn by [param rng], by the odds above.
static func draw(rng: RandomNumberGenerator) -> PackedByteArray:
	var roll := rng.randf()
	var count := Face.size()
	if roll < SEVENS:
		return PackedByteArray([Face.SEVEN, Face.SEVEN, Face.SEVEN])
	if roll < SEVENS + THREE:
		var face := rng.randi_range(1, count - 1)
		return PackedByteArray([face, face, face])
	if roll < SEVENS + THREE + PAIR:
		var paired := rng.randi_range(0, count - 1)
		var other := (paired + rng.randi_range(1, count - 1)) % count
		var faces := PackedByteArray([paired, paired, paired])
		faces[rng.randi_range(0, 2)] = other
		return faces
	var left: Array[int] = []
	for face: int in count:
		left.append(face)
	var drawn := PackedByteArray()
	for i: int in 3:
		drawn.append(left.pop_at(rng.randi_range(0, left.size() - 1)))
	return drawn


func _ready() -> void:
	add_to_group(GROUP)
	collision_layer = Layers.TRIGGER
	collision_mask = Layers.KART | Layers.PROTECTED
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(PLATE.x * 0.85, 1.0, PLATE.y * 0.85)
	shape.shape = box
	shape.position = Vector3(0.0, 0.5, 0.0)
	add_child(shape)
	_build_visuals()
	var node := get_parent()
	while node != null and not node is Match:
		node = node.get_parent()
	_match = node as Match
	Events.slot_spun.connect(_on_spun)
	Events.slot_paid.connect(_on_paid)


func _exit_tree() -> void:
	if Events.slot_spun.is_connected(_on_spun):
		Events.slot_spun.disconnect(_on_spun)
	if Events.slot_paid.is_connected(_on_paid):
		Events.slot_paid.disconnect(_on_paid)


## Whether this machine takes bets and pays them: the host's, while a map is being played.
func _hosting() -> bool:
	return _match != null and not _match.puppet and _match.is_running()


## Whether the reels are turning.
func is_spinning() -> bool:
	return _spin >= 0.0


func _physics_process(delta: float) -> void:
	if is_spinning():
		_step_spin(delta)
	elif _hosting():
		for body: Node3D in get_overlapping_bodies():
			var kart := body as Kart
			if kart != null and _may_pull(kart):
				_pull(kart)
				return


func _process(delta: float) -> void:
	if _lit > 0.0:
		_lit = maxf(_lit - delta / LIT_TIME, 0.0)
		# A win flickers as it fades, as a cabinet's lights chase.
		var flicker := 0.75 + 0.25 * sin(Time.get_ticks_msec() * 0.03)
		_material.set_shader_parameter(&"lit", minf(_lit, 1.0) * flicker)


func _may_pull(kart: Kart) -> bool:
	if not kart.alive or kart.falling or kart.is_decoy():
		return false
	if kart.pot.coins < LEAST_COINS:
		return false
	return _now() >= float(_rested.get(kart.slot, 0.0))


static func _now() -> float:
	return Time.get_ticks_msec() * 0.001


func _pull(kart: Kart) -> void:
	var bet := maxi(1, roundi(kart.pot.coins * BET))
	kart.pot.take_coins(bet)
	_rested[kart.slot] = _now() + REST
	Events.slot_spun.emit(kart.slot, index, bet, SlotPad.draw(_match.rng))


func _on_spun(slot: int, pad: int, bet: int, faces: PackedByteArray) -> void:
	if pad != index or faces.size() != 3:
		return
	_slot = slot
	_bet = bet
	_faces = faces
	_from = _material.get_shader_parameter(&"reel_at")
	_spin = 0.0
	_stopped = 0
	_ticked = 0.0
	Audio.play_sfx(&"item_pick", -6.0)


func _step_spin(delta: float) -> void:
	_spin += delta
	var at := Vector3.ZERO
	var blur := Vector3.ZERO
	for reel: int in 3:
		var stop := STOPS[reel]
		if _spin < stop:
			at[reel] = fposmod(_from[reel] - TURN * _spin, float(Face.size()))
			blur[reel] = minf(_spin * 5.0, 1.0)
			continue
		if reel >= _stopped:
			_stopped = reel + 1
			Audio.play_sfx(&"dry_fire", -4.0, 0.05)
		var settling := _spin - stop
		at[reel] = _faces[reel] + 0.2 * exp(-12.0 * settling) * sin(30.0 * settling)
	_material.set_shader_parameter(&"reel_at", at)
	_material.set_shader_parameter(&"blur", blur)
	if _stopped < 3 and _spin - _ticked >= 0.07:
		_ticked = _spin
		Audio.play_sfx(&"bank_tick", -16.0, 0.1)
	if _spin >= STOPS[2] + SETTLE:
		_spin = -1.0
		var resting := Vector3(_faces[0], _faces[1], _faces[2])
		_material.set_shader_parameter(&"reel_at", resting)
		# The host pays a bet it took, even should the whistle have gone while the reels turned.
		if _match != null and not _match.puppet:
			_pay()


## The reels have stopped: what they show is paid into the pot of whoever bet, still alive, and
## said, nothing as much as a win.
func _pay() -> void:
	var won := SlotPad.pays(_faces) * _bet
	var kart := Kart.of_slot(get_tree(), _slot)
	if kart == null or not kart.alive:
		won = 0
	if won > 0:
		kart.collect_coins(won, null)
	Events.slot_paid.emit(_slot, index, won)


func _on_paid(_by: int, pad: int, won: int) -> void:
	if pad != index:
		return
	var at := global_position + Vector3(0.0, WORDS_HEIGHT, 0.0)
	if won <= 0:
		FloatingText.spawn(get_parent(), at, "-%d" % _bet, Color(0.62, 0.62, 0.68), 40)
		return
	var sevens := SlotPad.pays(_faces) == SEVENS_PAY
	_lit = 2.0 if sevens else 1.0
	FloatingText.spawn(get_parent(), at, "+%d" % won, Palette.CHIP_GOLD, 64 if sevens else 52)
	Audio.play_sfx(&"slot_bell", -2.0 if sevens else -5.0, 0.0)
	Audio.play_sfx(&"chips_scatter" if sevens else &"gold_chip", -3.0)


func _build_visuals() -> void:
	var plate := MeshInstance3D.new()
	var plate_mesh := BoxMesh.new()
	plate_mesh.size = Vector3(PLATE.x, 0.05, PLATE.y)
	plate.mesh = plate_mesh
	var felt := StandardMaterial3D.new()
	felt.albedo_color = Color(0.36, 0.06, 0.08)
	plate.material_override = felt
	plate.position = Vector3(0.0, 0.025, 0.0)
	add_child(plate)
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Palette.CHIP_GOLD
	gold.metallic = 0.6
	gold.roughness = 0.35
	# A gold rim round the pad, as a cabinet's trim.
	for side: int in 4:
		var long := side % 2 == 0
		var rim := MeshInstance3D.new()
		var rim_mesh := BoxMesh.new()
		rim_mesh.size = Vector3(PLATE.x if long else 0.06, 0.08, 0.06 if long else PLATE.y)
		rim.mesh = rim_mesh
		rim.material_override = gold
		var out := (
			Vector3(0.0, 0.0, PLATE.y * 0.5 - 0.03)
			if long
			else Vector3(PLATE.x * 0.5 - 0.03, 0.0, 0.0)
		)
		rim.position = Vector3(0.0, 0.04, 0.0) + (out if side < 2 else -out)
		add_child(rim)
	var reels := MeshInstance3D.new()
	reels.name = "Reels"
	var quad := QuadMesh.new()
	quad.size = REELS_SIZE
	reels.mesh = quad
	reels.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Lying in the pad's face, its top toward the far side of the table.
	reels.rotation.x = -PI * 0.5
	reels.position = Vector3(0.0, 0.056, 0.0)
	_material = ShaderMaterial.new()
	_material.shader = LOOK
	_material.set_shader_parameter(&"reel_at", _from)
	reels.material_override = _material
	add_child(reels)
	_on_strip_ready()


## The strip of faces on the reels, once it has been drawn, see [KeptPictures].
func _on_strip_ready() -> void:
	var strip := KeptPictures.of(
		self,
		"slot_strip",
		STRIP_PIXELS,
		func() -> Control: return Strip.new(),
		GROUP,
		&"_on_strip_ready"
	)
	if strip != null:
		_material.set_shader_parameter(&"strip", strip)


## The six faces one over another on a reel's cream, drawn once a run.
class Strip:
	extends Control

	const CREAM := Color(0.97, 0.94, 0.86)
	const RED := Color(0.82, 0.1, 0.12)
	const INK := Color(0.08, 0.07, 0.09)

	func _ready() -> void:
		size = Vector2(SlotPad.STRIP_PIXELS)

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), CREAM)
		var side := size.x
		for face: int in SlotPad.Face.size():
			SlotPad.draw_face(self, Rect2(0.0, face * side, side, side), face)


## Draws [param face] into [param box] on [param on], on the reel's cream.
static func draw_face(on: CanvasItem, box: Rect2, face: int) -> void:
	var red := Strip.RED
	var ink := Strip.INK
	match face:
		Face.SEVEN:
			var font := Type.display_font()
			var high := box.size.y * 0.9
			var at := box.position + Vector2(0.0, box.size.y * 0.5 + high * 0.34)
			on.draw_string(font, at, "7", HORIZONTAL_ALIGNMENT_CENTER, box.size.x, int(high), red)
		Face.CHERRY:
			for x: float in [0.36, 0.64]:
				IconShapes.disc(on, box, x, 0.66, 0.16, red)
				IconShapes.disc(on, box, x - 0.05, 0.6, 0.04, Color(1.0, 0.6, 0.6))
			var green := Color(0.15, 0.5, 0.2)
			IconShapes.line(on, box, 0.36, 0.52, 0.56, 0.2, green)
			IconShapes.line(on, box, 0.64, 0.52, 0.56, 0.2, green)
			IconShapes.disc(on, box, 0.66, 0.2, 0.07, green)
		Face.BELL:
			var gold := Color(0.95, 0.68, 0.1)
			IconShapes.disc(on, box, 0.5, 0.42, 0.22, gold)
			IconShapes.bar(on, box, 0.28, 0.42, 0.44, 0.26, gold)
			IconShapes.bar(on, box, 0.2, 0.64, 0.6, 0.08, gold)
			IconShapes.disc(on, box, 0.5, 0.78, 0.07, ink)
		Face.BAR:
			IconShapes.bar(on, box, 0.12, 0.34, 0.76, 0.32, ink)
			var font := Type.display_font()
			var high := box.size.y * 0.24
			var at := box.position + Vector2(0.0, box.size.y * 0.5 + high * 0.36)
			var cream := Strip.CREAM
			on.draw_string(
				font, at, "BAR", HORIZONTAL_ALIGNMENT_CENTER, box.size.x, int(high), cream
			)
		Face.LEMON:
			var yellow := Color(0.98, 0.84, 0.15)
			IconShapes.disc(on, box, 0.5, 0.5, 0.26, yellow)
			IconShapes.disc(on, box, 0.22, 0.5, 0.08, yellow)
			IconShapes.disc(on, box, 0.78, 0.5, 0.08, yellow)
		Face.CHIP:
			IconShapes.disc(on, box, 0.5, 0.5, 0.34, red)
			for i: int in 6:
				var angle := TAU * i / 6.0
				var notch := Vector2(0.5, 0.5) + Vector2.from_angle(angle) * 0.28
				IconShapes.disc(on, box, notch.x, notch.y, 0.05, Strip.CREAM)
			IconShapes.ring(on, box, 0.5, 0.5, 0.18, Strip.CREAM)
