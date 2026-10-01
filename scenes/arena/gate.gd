class_name Gate
extends StaticBody3D
## A piece of wall that opens, GAME.md 9.4a: the tutorial's rooms are joined by these. Shut, it is
## a wall segment like the ones either side of it with a red band along its top; opened, the band
## turns cyan and the whole piece sinks into the floor, and it rises again to close. The arena puts
## one down for every run of G cells in a map, see 6.3, and whoever runs the room opens and closes
## them: a match on a map without them never meets one. Where the bots may drive is the room's to
## keep, see [method ArenaNav.set_cell_blocked], since the arena has no say in it.

signal opened
signal closed

## How long the piece takes to sink or rise, in seconds, and how far under the floor its top ends.
const SECONDS := 0.8
const UNDER := 0.08
## How far down it is before nothing stands in the way any more, as a share of the way down: a kart
## is let through a piece mostly gone rather than one still standing.
const CLEAR_AT := 0.55
## The band along the top: its color shut and open, and how thick it is.
const SHUT := Color("#FF3B30")
const OPEN := Palette.NEON_CYAN
const BAND := 0.08

## The cells it stands on, for the room to block and unblock on the bots' map.
var cells: Array[Vector2i] = []
var is_open := false

var _rest_y := 0.0
var _height := 1.0
var _shape: CollisionShape3D
var _band: StandardMaterial3D
var _tween: Tween


## Builds the piece: [param size] in meters, standing on the floor at [param at], and looking like
## [param look], the room's own wall.
func build(at: Vector3, size: Vector3, look: Node3D) -> void:
	position = at + Vector3(0.0, size.y * 0.5, 0.0)
	_rest_y = position.y
	_height = size.y
	collision_layer = Layers.WORLD
	collision_mask = 0
	_shape = CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	_shape.shape = box
	add_child(_shape)
	add_child(look)
	var band := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(size.x + BAND, BAND, size.z + BAND)
	band.mesh = mesh
	band.position = Vector3(0.0, size.y * 0.5, 0.0)
	_band = StandardMaterial3D.new()
	_band.emission_enabled = true
	_band.emission_energy_multiplier = 1.4
	band.material_override = _band
	add_child(band)
	_paint()


## Sinks into the floor, and stops being a wall once it is mostly down.
func open() -> void:
	if is_open:
		return
	is_open = true
	_paint()
	var bottom := _rest_y - _height - UNDER
	var clear := lerpf(_rest_y, bottom, CLEAR_AT)
	_slide()
	_tween.tween_property(self, "position:y", clear, SECONDS * CLEAR_AT)
	_tween.tween_callback(_shape.set_deferred.bind("disabled", true))
	_tween.tween_property(self, "position:y", bottom, SECONDS * (1.0 - CLEAR_AT))
	opened.emit()


## Rises out of the floor, a wall again from the first moment of it.
func close() -> void:
	if not is_open:
		return
	is_open = false
	_paint()
	_shape.set_deferred("disabled", false)
	_slide()
	_tween.tween_property(self, "position:y", _rest_y, SECONDS)
	closed.emit()


func _slide() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()


func _paint() -> void:
	var color := OPEN if is_open else SHUT
	_band.albedo_color = color
	_band.emission = color
