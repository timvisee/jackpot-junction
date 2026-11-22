class_name KartRings
extends Node
## The rings on the floor under the karts, GAME.md 8.5: asked for in Accessibility, under the karts
## driven here or under every kart, each in its kart's color inside a ring of ink, so a kart reads
## as its color from across a room however small it is drawn and whatever felt it is on. They grow
## as the camera goes back, never smaller on the screen than they are with it close in.
##
## And at the start of a map every kart's own ring of 3.6, the one it comes back with, breathing
## where it stands until it drives off, see [method SpawnRing.hold_on]: a player finds their kart
## on the grid by its color before the lights.
##
## Never two rings round a kart: while it wears the ring it came back with, or the countdown's, its
## kart ring makes way, see [method SpawnRing.on], and comes in once that has gone, over
## [constant COME_IN] seconds, gone in [constant MAKE_WAY].
##
## Drawn in the flare's own glowing look, [SpawnRing], so they compile nothing of their own; two
## coarse rings a kart, GAME.md 10.7.

## How big a ring is, in meters across its middle, at the least and as a share of how far back the
## camera is; how thick its color is and how much ink is round it, as shares of that.
const RADIUS := 1.35
const PER_METER := 0.045
const BAND := 0.14
const INK_BAND := 0.05
const INK := Color(0.05, 0.04, 0.07)
## How high over the floor they lie, clear of its print and under every kart, and how flat they
## are pressed, as a share of their tube's own height.
const LIFT := 0.04
const FLAT := 0.15
## How long a kart ring takes to come in once its kart's spawn ring has gone, and to make way.
const COME_IN := 0.3
const MAKE_WAY := 0.1
## How much of itself the ink and the color are drawn at.
const INK_ALPHA := 0.8
const COLOR_ALPHA := 0.95

var hud: MatchHud
## Each kart's ring and its ink, by the kart's instance id, and how much of itself each is shown at,
## 0 to 1, see [constant COME_IN].
var _rings: Dictionary[int, Array] = {}
var _shown: Dictionary[int, float] = {}


static func add_to(to: MatchHud) -> KartRings:
	var rings := KartRings.new()
	rings.name = "KartRings"
	rings.hud = to
	to.add_child(rings)
	Events.match_state_changed.connect(rings._on_state_changed)
	return rings


func _exit_tree() -> void:
	if Events.match_state_changed.is_connected(_on_state_changed):
		Events.match_state_changed.disconnect(_on_state_changed)
	for id: int in _rings.keys():
		_drop(id)


## Every kart's ring breathing where it stands as the countdown starts, see [SpawnRing].
func _on_state_changed(state: int) -> void:
	var match_node := hud.match_node
	if state != Match.State.COUNTDOWN or match_node == null:
		return
	for slot: PlayerSlot in match_node.slots:
		var kart := slot.kart
		if kart != null and kart.alive and kart.is_inside_tree():
			SpawnRing.spawn(match_node, kart.global_position, slot.color()).hold_on(kart)


func _process(delta: float) -> void:
	var match_node := hud.match_node
	var rig := match_node.camera_rig if match_node != null else null
	var which := Game.settings.kart_rings
	var wanted: Dictionary[int, bool] = {}
	if rig != null and which != ViewChoices.RINGS_OFF and not hud.dismissed:
		var here := CameraRig._valid(rig.listener_targets)
		var radius := maxf(RADIUS, rig._distance * PER_METER)
		for slot: PlayerSlot in match_node.slots:
			var kart := slot.kart
			if kart == null or not kart.alive or not kart.is_inside_tree():
				continue
			if which == ViewChoices.RINGS_HERE and kart not in here:
				continue
			var id := kart.get_instance_id()
			wanted[id] = true
			_place(id, kart, slot.color(), radius)
			_make_way(id, SpawnRing.on(kart), delta)
	for id: int in _rings.keys():
		if not wanted.has(id):
			_drop(id)


## [param kart]'s ring, made if it has none, under it in [param color] and [param radius] across.
func _place(id: int, kart: Kart, color: Color, radius: float) -> void:
	if not _rings.has(id):
		var inked := _ring(1.0 - BAND - INK_BAND, 1.0 + INK_BAND, INK, INK_ALPHA)
		_rings[id] = [inked, _ring(1.0 - BAND, 1.0, color, COLOR_ALPHA)]
		_shown[id] = 0.0
		for ring: MeshInstance3D in _rings[id]:
			hud.match_node.add_child(ring)
	var color_ring: MeshInstance3D = _rings[id][1]
	(color_ring.material_override as StandardMaterial3D).emission = color
	(color_ring.material_override as StandardMaterial3D).albedo_color = color
	var at := Vector3(kart.global_position.x, LIFT, kart.global_position.z)
	for i: int in 2:
		var ring: MeshInstance3D = _rings[id][i]
		ring.global_position = at + Vector3.UP * 0.01 * i
		ring.scale = Vector3(radius, FLAT, radius)


## Shows kart [param id]'s ring [param delta] seconds further toward all of itself, or toward none
## of itself while a spawn ring is round its kart, [param making_way].
func _make_way(id: int, making_way: bool, delta: float) -> void:
	var shown := _shown.get(id, 0.0) as float
	if making_way:
		shown = maxf(shown - delta / MAKE_WAY, 0.0)
	else:
		shown = minf(shown + delta / COME_IN, 1.0)
	_shown[id] = shown
	var alphas: Array[float] = [INK_ALPHA, COLOR_ALPHA]
	for i: int in 2:
		var ring: MeshInstance3D = _rings[id][i]
		ring.visible = shown > 0.0
		(ring.material_override as StandardMaterial3D).albedo_color.a = alphas[i] * shown


## A flat ring of [param inner] to [param outer] across, in [param color] at [param alpha].
static func _ring(inner: float, outer: float, color: Color, alpha: float) -> MeshInstance3D:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = inner
	torus.outer_radius = outer
	torus.rings = 32
	torus.ring_segments = 4
	ring.mesh = torus
	ring.material_override = SpawnRing.glow(color, alpha)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.top_level = true
	return ring


func _drop(id: int) -> void:
	for ring: MeshInstance3D in _rings[id]:
		if is_instance_valid(ring):
			ring.queue_free()
	_rings.erase(id)
	_shown.erase(id)
