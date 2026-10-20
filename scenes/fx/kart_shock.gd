class_name KartShock
extends Node3D
## A kart electrocuted by a live cabinet, GAME.md 6.2, the cartoon way: held where it died for a
## moment, shaking, flickering black and white, the burnt silhouette and the flash by turns, with
## black smoke rising off it and arcs crackling over it, before it springs apart as any wrecked
## kart does, see [KartWreck], and a scorch left on the floor under it, see [Scorch]. The smoke
## rises on a while after. For fewer flashes, 8.5, it goes black and stays black rather than
## flicker, and the arcs hold their shape as they fade.
##
## Looks only, the kart its own copy of the kart's look, so nothing of the match waits on it: the
## kart died as it touched the cabinet, and is told it did on a client as any death is. The host
## and a machine playing on its own take it as the kart dies, see [method Kart.die]; a client from
## the word that a kart was killed by a cabinet, see [method LiveCabinet.zap], which nearly always
## comes before the snapshot saying it is dead. If the snapshot came first the kart has sprung
## apart already, and it is left the smoke and the scorch. While a kart's look is held here the
## snapshot springs nothing apart of its own, see [method holds].
##
## Drawn in the arcs' own glowing look, [SpawnRing], the smoke in the nitro's and the scorch in a
## bullet mark's, so it compiles nothing of its own.

## How long the kart is held in its shock before it springs apart, in seconds; how long each of
## black and white lasts, flickering; and how far it shakes, in meters.
const HOLD := 0.55
const FLICKER := 0.05
const SHAKE := 0.035
## How long between the arcs crackling over the kart while it is held, in seconds.
const ARCS := 0.06
## The smoke: how long it pours, and how long a puff of it lasts.
const SMOKE_TIME := 1.4
const SMOKE_LIFE := 1.6
## The parts of a kart worn over its look that spring off with it, as [KartWreck] has them.
const WORN: Array[String] = ["Hat", "Flag", "Plate"]

## The karts whose look is held in a shock just now, by their instance ids.
static var _held: Dictionary[int, bool] = {}
static var _black: StandardMaterial3D
static var _white: StandardMaterial3D

var _kart_id := 0
var _color := Color.WHITE
var _age := 0.0
var _next_arcs := 0.0
var _sprung := false
var _model: Node3D
## Every part of the copy and what it wore: [MeshInstance3D] and its own override, and a text or
## sprite and its own modulate.
var _parts: Array[Array] = []
var _smoke: GPUParticles3D
var _dice := RandomNumberGenerator.new()


## [param kart] electrocuted where it stands, under its parent: its look held in a shock and
## then sprung apart, black smoke and a scorch, or only the smoke and the scorch for a
## [param held] of false, a kart already sprung apart. Null where there is nothing to show it on,
## or for a kart held in a shock already.
static func take(kart: Kart, held := true) -> KartShock:
	var parent := kart.get_parent()
	if parent == null or not kart.is_inside_tree() or holds(kart):
		return null
	var shock := KartShock.new()
	shock.name = "KartShock"
	shock._kart_id = kart.get_instance_id()
	shock._color = Palette.player_color(kart.color_index)
	shock._dice.randomize()
	parent.add_child(shock)
	shock.global_position = Vector3(kart.global_position.x, 0.0, kart.global_position.z)
	Scorch.lay(_floor_of(parent), kart.global_position)
	shock._smoke = shock._smoking()
	shock.add_child(shock._smoke)
	if held and shock._copy(kart._body):
		_held[shock._kart_id] = true
		shock._flicker()
		# A client's kart is still standing here until the snapshot says otherwise; the copy is
		# what is seen of it now.
		if kart.puppet:
			kart._body.visible = false
	else:
		shock._sprung = true
	return shock


## Where a scorch goes for a kart under [param parent]: on its match's arena, so it goes with the
## table, or under [param parent] with none.
static func _floor_of(parent: Node) -> Node:
	var node := parent
	while node != null and not node is Match:
		node = node.get_parent()
	var match_node := node as Match
	return match_node.arena if match_node != null and match_node.arena != null else parent


## Whether [param kart]'s look is held in a shock just now, which a client's snapshot leaves to
## spring apart here rather than springing it itself, see [KartPuppet].
static func holds(kart: Kart) -> bool:
	return kart != null and _held.has(kart.get_instance_id())


## Whether it is still holding the kart, for the tests.
func holding() -> bool:
	return not _sprung


## Whether the kart is drawn black just now, for the tests.
func blackened() -> bool:
	return not _parts.is_empty() and (_parts[0][0] as Object).get("material_override") == _black


## A copy of the kart's look, every mesh of [param body] that is shown and what it wears over it,
## where it stands. Whether there was anything to copy.
func _copy(body: Node3D) -> bool:
	if body == null:
		return false
	var model := body.get_node_or_null("Model") as Node3D
	if model == null:
		return false
	_model = Node3D.new()
	_model.name = "Model"
	add_child(_model)
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var part := node as MeshInstance3D
		if not _shown(part, body):
			continue
		var copy := MeshInstance3D.new()
		copy.name = part.name
		copy.mesh = part.mesh
		copy.material_override = part.material_override
		for surface: int in part.get_surface_override_material_count():
			copy.set_surface_override_material(surface, part.get_surface_override_material(surface))
		copy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_model.add_child(copy)
		copy.global_transform = part.global_transform
		_parts.append([copy, copy.material_override])
	for worn: String in WORN:
		var piece := body.get_node_or_null(worn) as Node3D
		if piece == null or not _shown(piece, body):
			continue
		var copied := piece.duplicate() as Node3D
		add_child(copied)
		copied.global_transform = piece.global_transform
		var each: Array[Node] = [copied]
		each.append_array(copied.find_children("*", "GeometryInstance3D", true, false))
		for node: Node in each:
			if node is MeshInstance3D:
				_parts.append([node, (node as MeshInstance3D).material_override])
			elif node is Label3D or node is SpriteBase3D:
				_parts.append([node, node.get("modulate")])
	return not _parts.is_empty()


## Whether [param node] is shown as part of [param body], whether or not the body itself is: a
## kart that has just died has its body hidden already.
static func _shown(node: Node, body: Node) -> bool:
	var at := node
	while at != null and at != body:
		var spatial := at as Node3D
		if spatial != null and not spatial.visible:
			return false
		at = at.get_parent()
	return at == body


func _process(delta: float) -> void:
	_age += delta
	if not _sprung:
		if _age >= HOLD:
			_spring()
		else:
			_flicker()
			_arcing(delta)
	if _smoke.emitting and _age >= SMOKE_TIME:
		_smoke.emitting = false
	if _age >= SMOKE_TIME + SMOKE_LIFE:
		queue_free()


## The current running through the held kart: arcs crackling over its body, [constant ARCS] apart.
func _arcing(delta: float) -> void:
	_next_arcs -= delta
	if _next_arcs > 0.0 or get_parent() == null:
		return
	_next_arcs = ARCS
	ZapArc.over(get_parent(), global_position, LiveCabinet.SPARK, _dice, 2)


## Black and white by turns, or black for fewer flashes, and a shake.
func _flicker() -> void:
	var steady := Game.settings != null and Game.settings.flash_reduction
	var black := steady or int(_age / FLICKER) % 2 == 0
	var look := _blackened() if black else _whitened()
	var ink := Color.BLACK if black else Color.WHITE
	for part: Array in _parts:
		var node: Node = part[0]
		if node is MeshInstance3D:
			(node as MeshInstance3D).material_override = look
		else:
			node.set("modulate", ink)
	_model.position = Vector3(
		_dice.randf_range(-SHAKE, SHAKE),
		_dice.randf_range(0.0, SHAKE),
		_dice.randf_range(-SHAKE, SHAKE)
	)


## Springs the kart apart as any wreck does, in its own paint again, with the pop of its color.
func _spring() -> void:
	_sprung = true
	_held.erase(_kart_id)
	_model.position = Vector3.ZERO
	for part: Array in _parts:
		var node: Node = part[0]
		if node is MeshInstance3D:
			(node as MeshInstance3D).material_override = part[1]
		else:
			node.set("modulate", part[1])
	KartWreck.spawn(get_parent(), self)
	Burst.spawn(get_parent(), global_position, _color, 0.7, 10)
	_model.queue_free()
	for worn: String in WORN:
		var piece := get_node_or_null(worn)
		if piece != null:
			piece.queue_free()
	_parts.clear()


func _exit_tree() -> void:
	_held.erase(_kart_id)


## Black smoke pouring up off it, in the look the nitro's plume is drawn in, see [NitroFlame].
func _smoking() -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.name = "Smoke"
	particles.amount = 48
	particles.lifetime = SMOKE_LIFE
	particles.local_coords = false
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3(0.0, 1.0, 0.0)
	process.spread = 30.0
	process.initial_velocity_min = 1.0
	process.initial_velocity_max = 2.0
	process.gravity = Vector3(0.0, 0.6, 0.0)
	process.damping_min = 0.8
	process.damping_max = 1.4
	process.scale_min = 0.9
	process.scale_max = 1.6
	process.scale_curve = _swelling()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = 0.35
	process.color_ramp = ParticleLook.fade_out(
		Color(0.04, 0.04, 0.045, 0.92), Color(0.12, 0.12, 0.13, 0.0)
	)
	particles.process_material = process
	particles.draw_pass_1 = ParticleLook.ball(0.24)
	ParticleLook.no_shadows(particles)
	particles.position = Vector3(0.0, 0.45, 0.0)
	particles.emitting = true
	return particles


## Puffs start small and swell as they rise.
static func _swelling() -> CurveTexture:
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.55))
	curve.add_point(Vector2(1.0, 1.2))
	var texture := CurveTexture.new()
	texture.curve = curve
	return texture


static func _blackened() -> StandardMaterial3D:
	if _black == null:
		_black = SpawnRing.glow(Color.BLACK, 1.0)
	return _black


static func _whitened() -> StandardMaterial3D:
	if _white == null:
		_white = SpawnRing.glow(Color.WHITE, 1.0)
	return _white
