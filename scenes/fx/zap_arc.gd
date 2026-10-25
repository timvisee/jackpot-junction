class_name ZapArc
extends MeshInstance3D
## The arc a live cabinet throws at a kart it kills, GAME.md 6.2: a few strands of jagged light
## between the two, drawn afresh every couple of frames so they crackle but for fewer flashes, and
## gone in half a second; and, smaller, its loose cable's crackle onto its roof while it is live,
## see [method crackle].
## Flat ribbons turned to the camera, in the one glowing, see-through look the spawn flare wears,
## [SpawnRing], so it compiles nothing of its own.

const LIFETIME := 0.7
## How many strands, how many kinks along each, how wide a strand is and how far a kink may stray
## off the straight line, in meters.
const STRANDS := 4
const KINKS := 7
const WIDTH := 0.1
const STRAY := 0.32
## How many frames each shape of the arcs is held for.
const HOLD := 2
## The way the ribbons are turned to: toward where the game camera looks from.
const TOWARD := Vector3(0.0, 0.55, 0.84)
## A crackle's: how long it lasts, how many strands, how wide one is and how far a kink strays.
const CRACKLE := 0.22
const CRACKLE_STRANDS := 2
const CRACKLE_WIDTH := 0.045
const CRACKLE_STRAY := 0.09
## A beam's: how long it lasts, how wide it is and how little it strays, see [method beam].
const BEAM := 0.18
const BEAM_WIDTH := 0.06
const BEAM_STRAY := 0.0

var from := Vector3.ZERO
var to := Vector3.ZERO
## The arc's own, a kill's unless it is a crackle, see the constants above.
var lifetime := LIFETIME
var strands := STRANDS
var width := WIDTH
var stray := STRAY

var _age := 0.0
var _frames := 0
var _material: StandardMaterial3D
var _lines := ImmediateMesh.new()
var _dice := RandomNumberGenerator.new()


## Throws an arc of [param color] from [param start] to [param end] under [param parent], in world
## space; it frees itself once it has gone out.
static func spawn(parent: Node, start: Vector3, end: Vector3, color: Color) -> ZapArc:
	return _thrown(ZapArc.new(), parent, start, end, color)


static func _thrown(
	arc: ZapArc, parent: Node, start: Vector3, end: Vector3, color: Color
) -> ZapArc:
	arc.name = "ZapArc"
	arc.from = start
	arc.to = end
	arc._material = SpawnRing.glow(color, 0.95)
	arc.material_override = arc._material
	arc.mesh = arc._lines
	arc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(arc)
	arc.global_transform = Transform3D.IDENTITY
	arc._dice.randomize()
	arc._shape()
	return arc


## A short crackle of [param color] from [param start] to [param end], a few centimeters of
## kinked light gone in a moment, the way a live cable arcs onto the steel beside it.
static func crackle(parent: Node, start: Vector3, end: Vector3, color: Color) -> ZapArc:
	var arc := ZapArc.new()
	arc.lifetime = CRACKLE
	arc.strands = CRACKLE_STRANDS
	arc.width = CRACKLE_WIDTH
	arc.stray = CRACKLE_STRAY
	return _thrown(arc, parent, start, end, color)


## A clean straight beam of [param color] from [param start] to [param end], a single strand that
## does not stray: a railgun's tracer down the line it fired along, GAME.md 5.3, gone in a moment.
static func beam(parent: Node, start: Vector3, end: Vector3, color: Color) -> ZapArc:
	var arc := ZapArc.new()
	arc.lifetime = BEAM
	arc.strands = 1
	arc.width = BEAM_WIDTH
	arc.stray = BEAM_STRAY
	return _thrown(arc, parent, start, end, color)


## A few crackles of [param color] over a kart at [param at], from one spot on its body to another,
## the current running through it.
static func over(
	parent: Node, at: Vector3, color: Color, dice: RandomNumberGenerator, count := 1
) -> void:
	for _i: int in count:
		var start := at + _on_body(dice)
		var end := at + _on_body(dice)
		var arc := crackle(parent, start, end, color)
		arc.width = CRACKLE_WIDTH * 1.5
		arc.stray = CRACKLE_STRAY * 1.6


## A spot on a kart's body, from its middle on the floor, in meters.
static func _on_body(dice: RandomNumberGenerator) -> Vector3:
	return Vector3(
		dice.randf_range(-0.4, 0.4), dice.randf_range(0.15, 0.6), dice.randf_range(-0.55, 0.55)
	)


func _process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	_material.albedo_color.a = 0.95 * (1.0 - _age / lifetime)
	_frames += 1
	# For fewer flashes, GAME.md 8.5, the strands hold the shape they were thrown in as they fade.
	var steady := Game.settings != null and Game.settings.flash_reduction
	if _frames % HOLD == 0 and not steady:
		_shape()


## A fresh set of strands, each kinked at random off the straight line between the ends.
func _shape() -> void:
	_lines.clear_surfaces()
	_lines.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var span := to - from
	var side := span.cross(TOWARD).normalized()
	if side.is_zero_approx():
		side = Vector3.RIGHT
	var lift := side.cross(span).normalized()
	for _strand: int in strands:
		var last := from
		for k: int in range(1, KINKS + 1):
			var share := float(k) / float(KINKS)
			var off := stray * sin(share * PI)
			var next := from + span * share
			if k < KINKS:
				next += side * _dice.randf_range(-off, off) + lift * _dice.randf_range(-off, off)
			_ribbon(last, next)
			last = next
	_lines.surface_end()


func _ribbon(a: Vector3, b: Vector3) -> void:
	var across := (b - a).cross(TOWARD).normalized() * width * 0.5
	for corner: Vector3 in [a - across, a + across, b + across, a - across, b + across, b - across]:
		_lines.surface_add_vertex(corner)
