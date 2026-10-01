class_name Gate
extends StaticBody3D
## A gate between two rooms, GAME.md 9.4a: a portcullis no taller than the walls either side of
## it. Two posts with a lamp on top of each, red while the gate is shut and cyan once it is open,
## and a row of steel bars between them that sink into the floor one after another from the
## middle outward when it opens, and rise again when it shuts; the posts stay, a doorway. Nothing
## crosses over the top of it, so nothing a kart wears goes through anything. The arena puts one
## down for every run of G cells in a map, see 6.3, and whoever runs the room opens and closes
## them: a match on a map without them never meets one. Where the bots may drive is the room's to
## keep, see [method ArenaNav.set_cell_blocked], since the arena has no say in it.

signal opened
signal closed

## How long the bars take to go down or come up, in seconds, and how far under the floor they end.
const SECONDS := 0.9
const UNDER := 0.1
## How far down the bars are before nothing stands in the way any more, as a share of the slide:
## a kart is let through bars mostly gone rather than ones still standing.
const CLEAR_AT := 0.55
## How far behind the middle bars the end ones run, as a share of the slide.
const STAGGER := 0.6
## The bars: how far apart, how thick, how tall against the wall, and how much of the span either
## side is post rather than bar.
const BAR_EVERY := 0.32
const BAR_RADIUS := 0.055
const BAR_SHARE := 0.95
const INSET := 0.5
## The posts, as tall as the wall and a little more, and the lamp capping each.
const POST_SIDE := 0.36
const POST_OVER := 0.12
const LAMP := 0.12
const SHUT := Color("#FF3B30")
const OPEN := Palette.NEON_CYAN
const STEEL := Color(0.22, 0.23, 0.27)
const DARK := Color(0.11, 0.11, 0.13)

## The cells it stands on, for the room to block and unblock on the bots' map.
var cells: Array[Vector2i] = []
var is_open := false
## How far down the bars are, 0 standing to 1 under the floor; what opening and closing tween.
var drop := 0.0:
	set(value):
		drop = value
		_place_bars()
		if _shape != null:
			_shape.set_deferred("disabled", is_open and drop >= CLEAR_AT)

var _span := 1.0
var _along := Vector3.RIGHT
var _shape: CollisionShape3D
var _bars: MultiMeshInstance3D
var _bar_count := 0
var _bar_tall := 1.0
var _lamps: StandardMaterial3D
var _tween: Tween


## Builds the gate across [param size], in meters, standing on the floor at [param at]. The bars
## run along the longer side, and stand as tall as [param size] is.
func build(at: Vector3, size: Vector3) -> void:
	position = at
	var along_x := size.x >= size.z
	_along = Vector3.RIGHT if along_x else Vector3.BACK
	_span = maxf(size.x, size.z)
	_bar_tall = size.y * BAR_SHARE
	collision_layer = Layers.WORLD
	collision_mask = 0
	_shape = CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	_shape.shape = box
	_shape.position = Vector3(0.0, size.y * 0.5, 0.0)
	add_child(_shape)
	_lamps = StandardMaterial3D.new()
	_lamps.emission_enabled = true
	_lamps.emission_energy_multiplier = 1.6
	var post_tall := size.y + POST_OVER
	for side: float in [-1.0, 1.0]:
		var foot := _along * side * (_span * 0.5 - POST_SIDE * 0.5)
		var post := _box(Vector3(POST_SIDE, post_tall, POST_SIDE), _material(DARK, 0.2))
		post.position = foot + Vector3(0.0, post_tall * 0.5, 0.0)
		add_child(post)
		var lamp := _box(Vector3(POST_SIDE + 0.04, LAMP, POST_SIDE + 0.04), _lamps)
		lamp.position = foot + Vector3(0.0, post_tall + LAMP * 0.5, 0.0)
		add_child(lamp)
	_bar_count = maxi(roundi((_span - INSET * 2.0) / BAR_EVERY), 1)
	var bar := CylinderMesh.new()
	bar.top_radius = BAR_RADIUS
	bar.bottom_radius = BAR_RADIUS
	bar.height = _bar_tall + UNDER
	bar.radial_segments = 8
	bar.rings = 1
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = bar
	multi.instance_count = _bar_count
	_bars = MultiMeshInstance3D.new()
	_bars.name = "Bars"
	_bars.multimesh = multi
	_bars.material_override = _material(STEEL, 0.6)
	# The bars are moved by a tween, in frame time: with the physics interpolation of the project
	# on, the renderer would otherwise try to interpolate them and warn every frame they move.
	_bars.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	add_child(_bars)
	_place_bars()
	_paint()


## The bars go down, the middle ones first, and once they are mostly gone nothing stands in the way.
func open() -> void:
	if is_open:
		return
	is_open = true
	_paint()
	_slide(1.0)
	opened.emit()


## The bars come up, a wall again from the first moment of it.
func close() -> void:
	if not is_open:
		return
	is_open = false
	_paint()
	_shape.set_deferred("disabled", false)
	_slide(0.0)
	closed.emit()


## Where bar [param index] stands just now, in the gate's own space, for asking where they are.
func bar_origin(index: int) -> Vector3:
	return _bars.multimesh.get_instance_transform(index).origin


func _slide(to: float) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(self, "drop", to, SECONDS)


## Each bar where its share of the slide puts it: the middle bars lead and the end ones follow.
func _place_bars() -> void:
	if _bars == null:
		return
	var multi := _bars.multimesh
	var step := (_span - INSET * 2.0) / _bar_count
	var middle := (_bar_count - 1) * 0.5
	for i: int in _bar_count:
		var behind := absf(i - middle) / maxf(middle, 1.0) * STAGGER
		var slid := clampf(drop * (1.0 + STAGGER) - behind, 0.0, 1.0)
		var offset := -_span * 0.5 + INSET + (i + 0.5) * step
		var y := (_bar_tall - UNDER) * 0.5 - slid * (_bar_tall + UNDER)
		multi.set_instance_transform(
			i, Transform3D(Basis.IDENTITY, _along * offset + Vector3(0.0, y, 0.0))
		)


func _paint() -> void:
	var color := OPEN if is_open else SHUT
	_lamps.albedo_color = color
	_lamps.emission = color


static func _box(size: Vector3, skin: Material) -> MeshInstance3D:
	var piece := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	piece.mesh = mesh
	piece.material_override = skin
	return piece


static func _material(color: Color, metal: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metal
	material.roughness = 0.45
	return material
