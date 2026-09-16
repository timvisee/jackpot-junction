class_name FlushPad
extends Area3D
## One of the four Royal Flush pads, GAME.md 3.9. A kart driving over it paints the frame in its
## colour and takes the pad from whoever held it. The match watches the claims: holding all four
## at once scores the flush, after which every pad clears and sits disabled for a while. Each pad
## carries a card letter so players can talk about them.

signal claimed(pad: FlushPad, kart: Kart)

const LETTERS: Array[String] = ["A", "K", "Q", "J"]
const PLATE_HEIGHT := 0.05
const FRAME_HEIGHT := 0.1
const NEUTRAL := Color(0.86, 0.86, 0.9)
const DISABLED := Color(0.3, 0.3, 0.34)

var index := 0
var letter := "A"
var size := 1.25
## Slot holding the pad, -1 for nobody.
var owner_slot := -1
var owner_color := NEUTRAL
## Seconds the pad still ignores karts after a flush.
var disabled_left := 0.0
var puppet := false

var _frame_material: StandardMaterial3D
var _label: Label3D
var _pulse := 0.0


func _ready() -> void:
	collision_layer = Layers.TRIGGER
	collision_mask = Layers.KART | Layers.PROTECTED
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size * 0.8, 1.0, size * 0.8)
	shape.shape = box
	shape.position = Vector3(0.0, 0.5, 0.0)
	add_child(shape)
	_build_visuals()
	_refresh()


func is_disabled() -> bool:
	return disabled_left > 0.0


func _physics_process(delta: float) -> void:
	_pulse += delta
	if owner_slot >= 0 and not is_disabled():
		_frame_material.emission_energy_multiplier = 0.9 + 0.5 * sin(_pulse * 4.0)
	if is_disabled():
		disabled_left = maxf(disabled_left - delta, 0.0)
		if not is_disabled():
			_refresh()
		return
	if puppet:
		return
	# Polled rather than on entry, so a kart parked on a pad that comes back takes it too.
	for body: Node3D in get_overlapping_bodies():
		var kart := body as Kart
		if kart == null or kart.slot == owner_slot or not _can_claim(kart):
			continue
		claim(kart.slot, Palette.player_color(kart.color_index))
		claimed.emit(self, kart)
		return


func _can_claim(kart: Kart) -> bool:
	return kart.alive and not kart.falling and not kart.frozen and not kart.is_decoy()


## Hands the pad to a slot, painting the frame in its colour.
func claim(slot: int, color: Color) -> void:
	owner_slot = slot
	owner_color = color if slot >= 0 else NEUTRAL
	_refresh()


## After a flush: nobody holds the pad and it ignores karts for a while.
func clear_and_disable(seconds: float) -> void:
	owner_slot = -1
	owner_color = NEUTRAL
	disabled_left = seconds
	_refresh()


## A host snapshot's view of this pad, on a client.
func apply_puppet_state(slot: int, color: Color, disabled: float) -> void:
	puppet = true
	owner_slot = slot
	owner_color = color if slot >= 0 else NEUTRAL
	disabled_left = disabled
	_refresh()


func _refresh() -> void:
	var color := DISABLED if is_disabled() else owner_color
	_frame_material.albedo_color = color
	_frame_material.emission = color
	_frame_material.emission_energy_multiplier = 0.0 if is_disabled() or owner_slot < 0 else 1.0
	_label.modulate = color


func _build_visuals() -> void:
	var plate := MeshInstance3D.new()
	var plate_mesh := BoxMesh.new()
	plate_mesh.size = Vector3(size * 0.92, PLATE_HEIGHT, size * 0.92)
	plate.mesh = plate_mesh
	var asphalt := StandardMaterial3D.new()
	asphalt.albedo_color = Palette.ASPHALT
	plate.material_override = asphalt
	plate.position = Vector3(0.0, PLATE_HEIGHT * 0.5, 0.0)
	add_child(plate)
	_frame_material = StandardMaterial3D.new()
	_frame_material.emission_enabled = true
	var thickness := size * 0.09
	for i: int in 4:
		var bar := MeshInstance3D.new()
		var bar_mesh := BoxMesh.new()
		var along := i < 2
		bar_mesh.size = Vector3(
			size if along else thickness, FRAME_HEIGHT, thickness if along else size
		)
		bar.mesh = bar_mesh
		bar.material_override = _frame_material
		var offset := (size - thickness) * 0.5 * (1.0 if i % 2 == 0 else -1.0)
		bar.position = Vector3(
			0.0 if along else offset, FRAME_HEIGHT * 0.5, offset if along else 0.0
		)
		add_child(bar)
	_label = Label3D.new()
	_label.text = letter
	_label.font_size = 140
	_label.outline_size = 18
	_label.outline_modulate = Color(0.05, 0.05, 0.06)
	_label.pixel_size = 0.005
	# Flat on the plate, its top toward -Z, so it reads from the camera behind the arena.
	_label.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	_label.position = Vector3(0.0, PLATE_HEIGHT + 0.01, 0.0)
	add_child(_label)
