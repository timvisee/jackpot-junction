class_name FlushPad
extends Area3D
## One of the four Royal Flush pads, GAME.md 3.9. A kart driving over it paints the frame in its
## color and takes the pad from whoever held it. A held pad pays its holder a slow trickle of
## coins for as long as they keep it, so taking one is worth something on its own; the match
## watches the claims as well, and holding all four at once scores the flush, after which every
## pad clears and sits disabled for a while. Each wears a card suit of its own on its plate, in
## its holder's color: four pads, four suits, and a flush is the set.
##
## Every coin the pad pays out throws a ring of light off it, so the trickle can be seen from
## across the table rather than only read off the score.
##
## A claim does not last: a pad lapses back to nobody after [member decay] seconds, dimming as
## it runs down, and driving over it again renews it. A flush therefore has to be put together
## inside that window and then kept up, rather than three pads being banked for the whole match
## while their holder waits for a chance at the fourth.

signal claimed(pad: FlushPad, kart: Kart)

const PLATE_HEIGHT := 0.05
const FRAME_HEIGHT := 0.1
const NEUTRAL := Color(0.86, 0.86, 0.9)
const DISABLED := Color(0.3, 0.3, 0.34)
## The ring a paid coin throws off the pad: how long it lasts, how far out it grows and how
## bright it starts.
const HALO_TIME := 0.7
const HALO_GROWTH := 1.9
const HALO_ALPHA := 0.75
## How big the suit is across the pad, and how finely it is drawn.
const SUIT := 0.5
const SUIT_PIXELS := 128
## How long a client stands by a claim of its own before the host's word takes over again, GAME.md
## 10.3, the way a crate it drove through does.
const PREDICTED_HOLD := 1.0

var index := 0
var size := 1.25
## Slot holding the pad, -1 for nobody.
var owner_slot := -1
var owner_color := NEUTRAL
## Seconds a fresh claim lasts, set by the match from the rules.
var decay := 30.0
## Seconds this claim still has to run.
var held_left := 0.0
## Seconds the pad still ignores karts after a flush.
var disabled_left := 0.0
var puppet := false
## How long this client still stands by its own claim, see [method predict_claim], and what the
## host last said of the pad meanwhile, for going back to the moment that runs out.
var _predicted_left := 0.0
var _host_said: Array = []

var _frame_material: StandardMaterial3D
var _suit_material: StandardMaterial3D
var _pulse := 0.0
var _halo: MeshInstance3D
var _halo_material: StandardMaterial3D
## How far through its life the last ring is, 1 the moment a coin lands and 0 once it is gone.
var _halo_left := 0.0
## The color of the ring in the air right now, which outlives the claim that threw it.
var _halo_color := NEUTRAL


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


## Throws a ring of light off the pad, for a coin landing in somebody's pot. The color is
## given rather than taken from the pad, since a pad resting after a flush is wearing nobody's
## color and is still paying out the flush that cleared it.
func pop_halo(color: Color = Color.TRANSPARENT) -> void:
	_halo_left = 1.0
	_halo_color = owner_color if color.a <= 0.0 else color


func _physics_process(delta: float) -> void:
	_pulse += delta
	if _predicted_left > 0.0:
		_predicted_left = maxf(_predicted_left - delta, 0.0)
		if _predicted_left <= 0.0 and not _host_said.is_empty():
			apply_puppet_state.callv(_host_said)
	_step_halo(delta)
	if owner_slot >= 0 and not is_disabled():
		held_left = maxf(held_left - delta, 0.0)
		# Dimming over the last stretch of the claim, so a pad about to lapse looks like one.
		var fade := clampf(held_left / maxf(decay * 0.4, 0.001), 0.0, 1.0)
		_frame_material.emission_energy_multiplier = (0.9 + 0.5 * sin(_pulse * 4.0)) * fade
		if held_left <= 0.0 and not puppet:
			claim(-1, NEUTRAL)
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
		if kart == null or not _can_claim(kart):
			continue
		if kart.slot == owner_slot:
			# Its holder came back around: the claim is renewed rather than taken again.
			held_left = decay
			continue
		claim(kart.slot, Palette.player_color(kart.color_index))
		claimed.emit(self, kart)
		return


## The last ring thrown off the pad: it grows outward and fades as it goes, in whatever color
## the pad is wearing, and takes itself off the table when it is spent.
func _step_halo(delta: float) -> void:
	if _halo_left <= 0.0:
		_halo.visible = false
		return
	_halo_left = maxf(_halo_left - delta / HALO_TIME, 0.0)
	var age := 1.0 - _halo_left
	_halo.visible = true
	_halo.scale = Vector3.ONE * lerpf(1.0, HALO_GROWTH, age)
	_halo_material.albedo_color = Color(_halo_color, HALO_ALPHA * _halo_left * _halo_left)


func _can_claim(kart: Kart) -> bool:
	return kart.is_active() and not kart.is_decoy()


## Hands the pad to a slot, painting the frame in its color.
func claim(slot: int, color: Color) -> void:
	owner_slot = slot
	held_left = decay if slot >= 0 else 0.0
	owner_color = color if slot >= 0 else NEUTRAL
	_refresh()


## Whether [param kart], its simulation at [param where], is on the pad, for a client asking about
## its own, GAME.md 10.3: its body's box, turned the way it points, against the pad's.
func would_take(kart: Kart, where: Transform3D) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	var body := kart.get_node_or_null(^"CollisionShape3D") as CollisionShape3D
	if body == null:
		return false
	query.shape = body.shape
	query.transform = where * body.transform
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = Layers.TRIGGER
	for hit: Dictionary in get_world_3d().direct_space_state.intersect_shape(query, 16):
		if hit["collider"] == self:
			return true
	return false


## Whether [param kart] would take the pad off whoever holds it by driving on: not while it rests
## after a flush, and not from itself, which only renews the claim.
func can_be_taken_by(kart: Kart) -> bool:
	return not is_disabled() and kart.slot != owner_slot and _can_claim(kart)


## Taken by this client's own kart on its own word, GAME.md 10.3: in its color the tick it drove
## on rather than a round trip later. The snapshot leaves it that way until the host agrees, or
## clears the pads for a flush, or for [constant PREDICTED_HOLD], after which the host's word is
## the pad again.
func predict_claim(kart: Kart) -> void:
	_host_said = [owner_slot, owner_color, disabled_left]
	claim(kart.slot, Palette.player_color(kart.color_index))
	_predicted_left = PREDICTED_HOLD


func predicted_claim() -> bool:
	return _predicted_left > 0.0


## After a flush: nobody holds the pad and it ignores karts for a while.
func clear_and_disable(seconds: float) -> void:
	owner_slot = -1
	held_left = 0.0
	owner_color = NEUTRAL
	disabled_left = seconds
	_refresh()


## A host snapshot's view of this pad, on a client.
func apply_puppet_state(slot: int, color: Color, disabled: float) -> void:
	puppet = true
	if predicted_claim():
		# Built before the host heard of this client's claim: the pad stays this client's.
		if slot != owner_slot and disabled <= 0.0:
			_host_said = [slot, color, disabled]
			return
		_predicted_left = 0.0
	_host_said = []
	if slot != owner_slot:
		held_left = decay if slot >= 0 else 0.0
	owner_slot = slot
	owner_color = color if slot >= 0 else NEUTRAL
	disabled_left = disabled
	_refresh()


func _refresh() -> void:
	var color := DISABLED if is_disabled() else owner_color
	_frame_material.albedo_color = color
	_frame_material.emission = color
	_frame_material.emission_energy_multiplier = 0.0 if is_disabled() or owner_slot < 0 else 1.0
	_suit_material.albedo_color = color


func _build_visuals() -> void:
	var plate := MeshInstance3D.new()
	var plate_mesh := BoxMesh.new()
	plate_mesh.size = Vector3(size * 0.92, PLATE_HEIGHT, size * 0.92)
	plate.mesh = plate_mesh
	var asphalt := StandardMaterial3D.new()
	asphalt.albedo_color = Palette.ASPHALT
	plate.material_override = asphalt
	plate.position = Vector3(0.0, PLATE_HEIGHT * 0.5, 0.0)
	# A plate and a frame set into the felt throw no shadow anybody sees, GAME.md 10.7.
	plate.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
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
		bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var offset := (size - thickness) * 0.5 * (1.0 if i % 2 == 0 else -1.0)
		bar.position = Vector3(
			0.0 if along else offset, FRAME_HEIGHT * 0.5, offset if along else 0.0
		)
		add_child(bar)
	# The pad's own suit, one of the four a flush collects, drawn once in white and worn in
	# whatever color the pad is.
	var mark := Mark.new()
	mark.suit = index
	_suit_material = DrawnTexture.decal(DrawnTexture.of(self, mark, Vector2i.ONE * SUIT_PIXELS))
	var suit := DrawnTexture.face(Vector2.ONE * size * SUIT, _suit_material)
	suit.name = "Suit"
	# Flat on the plate, its top toward -Z, so it reads from the camera behind the arena.
	suit.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	suit.position = Vector3(0.0, PLATE_HEIGHT + 0.01, 0.0)
	suit.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(suit)
	_build_halo()


## The ring itself: a flat band lying just above the plate, wider than the pad so it reads as
## something thrown off it rather than as part of it.
func _build_halo() -> void:
	_halo_material = StandardMaterial3D.new()
	_halo_material.albedo_color = Color(NEUTRAL, 0.0)
	_halo_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_halo_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_halo_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_halo_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_halo = MeshInstance3D.new()
	_halo.name = "Halo"
	var ring := TorusMesh.new()
	ring.inner_radius = size * 0.62
	ring.outer_radius = size * 0.72
	ring.rings = 4
	_halo.mesh = ring
	_halo.material_override = _halo_material
	_halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_halo.position = Vector3(0.0, PLATE_HEIGHT + 0.02, 0.0)
	# A four-sided ring is a diamond where the pad is a square, so it is turned an eighth of a
	# turn to put its corners on the pad's.
	_halo.rotation_degrees = Vector3(0.0, 45.0, 0.0)
	_halo.visible = false
	add_child(_halo)


## The suit on the plate, outlined in the dark of the asphalt so it reads on a pad lit in a pale
## color.
class Mark:
	extends Control

	var suit := 0

	func _draw() -> void:
		SuitArt.draw_into(self, Rect2(Vector2.ZERO, size), suit, Color.WHITE, size.x * 0.035)
