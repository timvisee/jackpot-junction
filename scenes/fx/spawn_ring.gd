class_name SpawnRing
extends Node3D
## The flare a kart comes back with, GAME.md 3.6: a ring that opens out across the floor in the
## player's color with a column of light standing in the middle of it, both gone inside a
## second. A kart that has just respawned is untouchable for a moment and blinking, which says
## something about that kart to whoever is looking at it; this says, to everybody at once and
## from anywhere on the floor, that somebody is back and where they came back.

const LIFETIME := 0.75
const START_RADIUS := 0.5
const END_RADIUS := 3.6
## How thick the ring is, as a share of its radius, and how tall the column stands.
const THICKNESS := 0.16
const COLUMN_HEIGHT := 3.4
const COLUMN_RADIUS := 0.55
## The column has gone by this share of the flare's life; the ring keeps going to the end.
const COLUMN_LIFE := 0.55
## Held on a kart, see [method hold_on], the ring stays round where it came back once the flare has
## opened, breathing, until the kart drives off: how big it is, how long a breath takes, how far the
## kart goes before it counts as gone, and how long the ring takes to go then and to come.
const HELD_RADIUS := 1.9
const BREATH := 1.2
const MOVED := 0.75
const FADE := 0.3
## How long it waits for a kart that is not there yet, on a client whose snapshot has not moved it.
const ARRIVING := 2.0
## Every ring held on a kart, see [method on].
const GROUP := &"held_spawn_rings"

var color := Color.WHITE

var _age := 0.0
## The kart it is held on, whether that has been there yet, and how far gone the ring is, 0 to 1.
var _held: Node3D
var _arrived := false
var _going := 0.0
var _ring: MeshInstance3D
var _ring_material: StandardMaterial3D
var _column: MeshInstance3D
var _column_material: StandardMaterial3D


static func spawn(parent: Node, at: Vector3, player_color: Color) -> SpawnRing:
	var flare := SpawnRing.new()
	flare.name = "SpawnRing"
	flare.color = player_color
	parent.add_child(flare)
	flare.global_position = Vector3(at.x, 0.0, at.z)
	flare._build()
	return flare


## Keeps the ring round where [param kart] came back once the flare has opened, breathing, until it
## drives off, GAME.md 3.6: a player who has not found their kart yet finds it still marked, however
## long they take.
func hold_on(kart: Node3D) -> SpawnRing:
	_held = kart
	add_to_group(GROUP)
	return self


## Whether a ring is held on [param kart] just now, from its flare until it has gone: the one ring
## round that kart, which its kart ring of 8.5 makes way for, see [KartRings].
static func on(kart: Node3D) -> bool:
	if not kart.is_inside_tree():
		return false
	for node: Node in kart.get_tree().get_nodes_in_group(GROUP):
		var ring := node as SpawnRing
		if ring != null and ring._held == kart and not ring.is_queued_for_deletion():
			return true
	return false


func _process(delta: float) -> void:
	_age += delta
	var life := _age / LIFETIME
	if life >= 1.0 and _held != null:
		_breathe(delta)
		return
	if life >= 1.0:
		queue_free()
		return
	var radius := lerpf(START_RADIUS, END_RADIUS, ease(life, 0.35))
	_ring.scale = Vector3(radius, 1.0, radius)
	_ring_material.albedo_color.a = 0.85 * (1.0 - life)
	var column_life := clampf(life / COLUMN_LIFE, 0.0, 1.0)
	_column.visible = column_life < 1.0
	_column.scale = Vector3(
		1.0 - 0.4 * column_life, 1.0 + 0.5 * column_life, 1.0 - 0.4 * column_life
	)
	_column_material.albedo_color.a = 0.5 * (1.0 - column_life)


## The ring held round [member _held] after the flare, see [method hold_on]: breathing in and out
## until the kart drives further than [constant MOVED] off the spot, is wrecked or is gone, then
## going over [constant FADE].
func _breathe(delta: float) -> void:
	_column.visible = false
	var kart := _held as Kart
	var gone := not is_instance_valid(_held) or (kart != null and not kart.alive)
	if not gone:
		var off := _held.global_position - global_position
		var near := Vector2(off.x, off.z).length() <= MOVED
		_arrived = _arrived or near
		gone = (_arrived and not near) or (not _arrived and _age > LIFETIME + ARRIVING)
	if gone:
		_going = minf(_going + delta / FADE, 1.0)
		if _going >= 1.0:
			queue_free()
			return
	var held := _age - LIFETIME
	var breath := 0.5 - 0.5 * cos(TAU * held / BREATH)
	var radius := HELD_RADIUS * (0.92 + 0.08 * breath)
	_ring.scale = Vector3(radius, 1.0, radius)
	var coming := clampf(held / FADE, 0.0, 1.0)
	_ring_material.albedo_color.a = (0.35 + 0.4 * breath) * coming * (1.0 - _going)


func _build() -> void:
	_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 1.0 - THICKNESS
	torus.outer_radius = 1.0
	# A thin glowing band, gone in a second: coarse round its tube, GAME.md 10.7.
	torus.rings = 32
	torus.ring_segments = 6
	_ring.mesh = torus
	_ring_material = SpawnRing.glow(color, 0.85)
	_ring.material_override = _ring_material
	_ring.position = Vector3(0.0, 0.08, 0.0)
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ring)
	_column = MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = COLUMN_RADIUS * 0.6
	cylinder.bottom_radius = COLUMN_RADIUS
	cylinder.height = COLUMN_HEIGHT
	cylinder.radial_segments = 24
	cylinder.rings = 1
	_column.mesh = cylinder
	_column_material = SpawnRing.glow(color, 0.5)
	_column.material_override = _column_material
	_column.position = Vector3(0.0, COLUMN_HEIGHT * 0.5, 0.0)
	_column.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_column)


## The glowing, see-through look of [param color] at [param alpha] the flare is drawn in, and the
## arc a live cabinet throws, [ZapArc]: one shader for both, compiled behind the title.
static func glow(color: Color, alpha: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color, alpha)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 2.2
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material
