class_name DiscoLights
extends Node3D
## Moving-head spot lights around the arena, GAME.md 8.1. They follow the excitement meter: one
## light drifting slowly over a quiet lap, more of them joining and sweeping wider and faster as
## the match heats up, all six at their widest during Last Call.
##
## The heads stand on posts along the long edges of the table, like a stage rig. While the match
## is cold they point up and sweep the air above the room; as the heat builds they tip down onto
## the floor, so the lights come down to the players rather than being switched on over them.
##
## Every head flashes on the beat of the music, harder on the first beat of the bar, and the flash
## too is barely there until the match is hot.
##
## The rig deliberately lags the meter. It follows a slowed-down copy of it, a head has to be
## clearly earned before it lights and clearly unearned before it goes out, and whichever way it
## went it stands for a few seconds. A flurry in the match therefore cannot blink a light on and
## straight off again. While some heads are still dark the lit run walks around the rig on its
## own, slowly at rest and quicker as things heat up, so the room keeps moving without brightening.
##
## Purely decorative: the lights cast no shadows and nothing reads them. The accessibility
## setting in GAME.md 8.5 switches them off entirely.

const COUNT := 6
## Where a head sits: this high on its post, this far outside the wall along the table's edge.
const MOUNT_HEIGHT := 1.9
const EDGE_OFFSET := 0.9
## How far above itself a head points while the match is cold.
const SKY_RISE := 13.0
## The heat at which heads start tipping down toward the floor, and where they are fully down.
const TIP_START := 0.12
const TIP_FULL := 0.7
## How far the light reaches. Comfortably past the far corner of the floor, so a beam thrown
## right across the table still lands.
const LIGHT_RANGE := 40.0
## Colours the heads are painted in, in the order they switch on.
const COLORS: Array[Color] = [
	Color("#FF4FA3"),
	Color("#35D0FF"),
	Color("#FFFFFF"),
	Color("#F2C14E"),
	Color("#8B5CF6"),
	Color("#4ADE80"),
]
## How fast the rig follows the meter, per second. Well below the meter's own rise.
const LEVEL_FOLLOW := 0.3
## Once a head has come on or gone out, the count stands for this long.
const HOLD := 3.0
## How far the level has to fall back below the mark that lit a head before it goes out again.
const BAND := 0.06
## Seconds between handing the lit run on to the next head, at rest and at full heat.
const CYCLE_SLOW := 7.0
const CYCLE_FAST := 2.0

## The excitement meter, 0 to 1, set by the match every tick.
var level := 0.0
## Whether this room wants lights at all. The Garage in GAME.md 9.4 turns them off: it is a
## place to look at the controls, not a nightclub.
var enabled := true

var _heads: Array[Dictionary] = []
var _time := 0.0
var _floor := Vector2(20.0, 11.25)
## The meter as the lights see it: the same number, slowed right down.
var _smooth := 0.0
## How many heads are lit, how long that has to stand, and which head the lit run starts at.
var _count := 1
var _hold := 0.0
var _offset := 0
var _cycle := 0.0


## Builds the heads above an arena of [param floor_size] metres.
func setup(floor_size: Vector2) -> void:
	_floor = floor_size * 0.5
	for i: int in COUNT:
		_heads.append(_build_head(i))


func lit_count() -> int:
	var lit := 0
	for head: Dictionary in _heads:
		if (head["light"] as SpotLight3D).visible:
			lit += 1
	return lit


func _process(delta: float) -> void:
	if _heads.is_empty():
		return
	if not enabled or not Game.settings.disco_lights:
		for head: Dictionary in _heads:
			(head["light"] as SpotLight3D).visible = false
		return
	_smooth = move_toward(_smooth, level, LEVEL_FOLLOW * delta)
	_step_count(delta)
	_step_cycle(delta)
	# Everything moves at a crawl until the match gives it a reason not to.
	_time += delta * (0.3 + 1.4 * _smooth)
	var beat := Audio.music_beat()
	var downbeat := Audio.music_beat_index() == 0
	# A flash right on the beat that falls away before the next one.
	var flash := pow(1.0 - beat, 4.0) * (1.3 if downbeat else 1.0)
	for i: int in _heads.size():
		_step_head(_heads[i], is_lit(i), flash)


## How many heads are lit. One more comes on only once the level has clearly earned it, one goes
## out only once it has clearly lost it, and either way the count then stands for a few seconds.
func _step_count(delta: float) -> void:
	_hold = maxf(_hold - delta, 0.0)
	if _hold > 0.0:
		return
	var step := 1.0 / float(COUNT - 1)
	if _count < COUNT and _smooth >= float(_count) * step:
		_count += 1
		_hold = HOLD
	elif _count > 1 and _smooth < float(_count - 1) * step - BAND:
		_count -= 1
		_hold = HOLD


## While some heads are dark the lit run walks around the rig, so the room keeps changing without
## getting any brighter. With every head already lit there is nothing to hand on.
func _step_cycle(delta: float) -> void:
	if _count >= COUNT:
		return
	_cycle -= delta
	if _cycle <= 0.0:
		_cycle = lerpf(CYCLE_SLOW, CYCLE_FAST, _smooth)
		_offset = posmod(_offset + 1, COUNT)


## Whether this head is one of the [member _count] currently taking their turn.
func is_lit(index: int) -> bool:
	return posmod(index - _offset, COUNT) < _count


func _step_head(head: Dictionary, on: bool, flash: float) -> void:
	var light: SpotLight3D = head["light"]
	light.visible = on
	(head["post"] as MeshInstance3D).visible = on
	if not on:
		return
	var target := _aim_point(head)
	if absf(target.x - light.position.x) < 0.02 and absf(target.z - light.position.z) < 0.02:
		target.x += 0.05
	light.look_at(target, Vector3.UP)
	# The cone is cut to the distance it actually has to cross and widened to the light's own
	# angle, so it always ends in a lit pool on the floor rather than stopping in mid-air.
	var throw := light.global_position.distance_to(target)
	var cone: CylinderMesh = head["cone"]
	cone.height = throw
	cone.top_radius = throw * tan(deg_to_rad(light.spot_angle))
	(head["beam"] as MeshInstance3D).position.z = -throw * 0.5
	# Kept well short of washing the table out: at full heat every head is on, and six of them
	# blazing would cost more in readability than it buys in atmosphere.
	var pulse := 1.0 + (0.15 + 0.55 * _smooth) * flash
	light.light_energy = (0.8 + 1.5 * _smooth) * pulse
	light.spot_angle = lerpf(14.0, 24.0, _smooth)
	var tint: StandardMaterial3D = head["tint"]
	# Beams from the edge cut across the camera rather than pointing away from it, so they are
	# kept fainter than an overhead rig would need.
	tint.albedo_color.a = (0.018 + 0.038 * _smooth) * pulse


## Where a head is pointing: into the air above itself while the room is quiet, swinging down onto
## the floor as the heat builds. Both ends of that blend keep moving, so a head sweeping the sky
## looks as alive as one raking the table.
func _aim_point(head: Dictionary) -> Vector3:
	var mount: Vector3 = (head["light"] as SpotLight3D).position
	var inward: float = head["inward"]
	var sway := sin(_time * head["rate_x"] + head["phase"]) * 3.2
	var sky := mount + Vector3(sway, SKY_RISE, inward * 2.5)
	var reach: Vector2 = head["reach"] * (0.35 + 0.65 * _smooth)
	var floor_point := Vector3(
		clampf(sin(_time * head["rate_x"] + head["phase"]) * reach.x, -_floor.x, _floor.x),
		0.0,
		clampf(cos(_time * head["rate_z"] + head["phase"]) * reach.y, -_floor.y, _floor.y)
	)
	var tipped := clampf((_smooth - TIP_START) / (TIP_FULL - TIP_START), 0.0, 1.0)
	return sky.lerp(floor_point, tipped)


func _build_head(index: int) -> Dictionary:
	var color := COLORS[index % COLORS.size()]
	# Three heads along each long edge of the table, just outside the wall.
	var across := (float(index % 3) - 1.0) * _floor.x * 0.62
	var side := -1.0 if index < 3 else 1.0
	var mount := Vector3(across, MOUNT_HEIGHT, side * (_floor.y + EDGE_OFFSET))
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.12, 0.12, 0.14)
	var post := MeshInstance3D.new()
	post.name = "Post%d" % index
	var stem := CylinderMesh.new()
	stem.top_radius = 0.07
	stem.bottom_radius = 0.11
	stem.height = MOUNT_HEIGHT
	post.mesh = stem
	post.material_override = dark
	post.position = Vector3(mount.x, MOUNT_HEIGHT * 0.5, mount.z)
	add_child(post)
	var light := SpotLight3D.new()
	light.name = "Head%d" % index
	light.light_color = color
	light.light_energy = 1.0
	light.spot_range = LIGHT_RANGE
	light.spot_angle = 16.0
	light.spot_attenuation = 0.5
	light.shadow_enabled = false
	light.position = mount
	add_child(light)
	# Aimed over the table to start with, never straight along an axis: looking_at cannot pick a
	# roll from a target directly above or below.
	light.look_at(Vector3(across * 0.5, MOUNT_HEIGHT + SKY_RISE, mount.z * 0.5), Vector3.UP)
	light.add_child(_fixture(color, dark))
	var beam_material := StandardMaterial3D.new()
	beam_material.albedo_color = Color(color.r, color.g, color.b, 0.03)
	beam_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	beam_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var beam := MeshInstance3D.new()
	beam.name = "Beam"
	var cone := CylinderMesh.new()
	# The wide end lands where the beam does: after the tilt below, the mesh's top points away
	# from the light along its beam. Both the length and that end are resized every frame.
	cone.top_radius = 1.7
	cone.bottom_radius = 0.1
	cone.height = SKY_RISE
	beam.mesh = cone
	beam.material_override = beam_material
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beam.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	beam.position = Vector3(0.0, 0.0, -SKY_RISE * 0.5)
	light.add_child(beam)
	return {
		"light": light,
		"post": post,
		"beam": beam,
		"cone": cone,
		"tint": beam_material,
		"inward": -side,
		"reach": Vector2(_floor.x * 0.75, _floor.y * 0.75),
		"rate_x": 0.31 + 0.07 * index,
		"rate_z": 0.23 + 0.05 * index,
		"phase": float(index) * 1.1,
	}


## The head itself: a dark housing with a lens the colour of its beam, so the rig reads as a row
## of lamps rather than as beams from nowhere. Parented to the light, so it swings with it.
static func _fixture(color: Color, dark: StandardMaterial3D) -> Node3D:
	var housing := MeshInstance3D.new()
	housing.name = "Fixture"
	var box := BoxMesh.new()
	box.size = Vector3(0.34, 0.34, 0.44)
	housing.mesh = box
	housing.material_override = dark
	housing.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var lens := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.13
	disc.bottom_radius = 0.13
	disc.height = 0.04
	lens.mesh = disc
	var glow := StandardMaterial3D.new()
	glow.albedo_color = color
	glow.emission_enabled = true
	glow.emission = color
	glow.emission_energy_multiplier = 2.0
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lens.material_override = glow
	lens.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	lens.position = Vector3(0.0, 0.0, -0.24)
	lens.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	housing.add_child(lens)
	return housing
