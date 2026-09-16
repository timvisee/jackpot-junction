class_name DiscoLights
extends Node3D
## Moving-head spot lights around the arena, GAME.md 8.1. The rig runs on the excitement levels
## of GAME.md 8.4, one head per level: a single light drifting over the opening lap at level 1,
## another joining at every level, all six sweeping their widest and quickest at level 6.
##
## The heads stand on posts along the long edges of the table, like a stage rig. At the first two
## levels they point up and sweep the air above the room; from level 3 they tip down onto the
## floor, and by level 4 they are fully down, so the lights come down to the players rather than
## being switched on over them.
##
## From level 3 the heads also flash on the beat of the music, harder on the first beat of the
## bar, faintly at first and hardest at level 6.
##
## The levels themselves hold for long enough that nothing here has to guard against flapping,
## so the rig only eases between them: a step up sweeps the beams open over a second or so rather
## than snapping. While some heads are still dark the lit run walks around the rig on its own,
## slowly at rest and quicker as things heat up, so the room keeps moving without brightening.
##
## The lamps themselves are part of the room and stay where they are: a head that is not taking
## its turn simply goes dark, with its beam gone and its lens unlit, rather than vanishing. Only
## a room that wants no rig at all, such as the Garage, takes the posts away with it.
##
## Purely decorative: the lights cast no shadows and nothing reads them. The accessibility
## setting in GAME.md 8.5 leaves the lamps standing and stops them lighting.

const COUNT := 6
## Where a head sits: this high on its post, this far outside the wall along the table's edge.
const MOUNT_HEIGHT := 1.9
const EDGE_OFFSET := 0.9
## How far above itself a head points while the match is cold.
const SKY_RISE := 13.0
## Where in the climb the heads start tipping down toward the floor, and where they are fully
## down: nothing at levels 1 and 2, halfway at level 3, all the way from level 4.
const TIP_START := 0.25
const TIP_FULL := 0.58
## How brightly a lit head's lens shows, and the colour a dark one's takes instead.
const LENS_GLOW := 2.0
const LENS_DARK := Color(0.16, 0.16, 0.19)
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
## How fast the beams follow a change of level, per second: a step is a fifth of the climb, so
## this sweeps one open over rather more than half a second.
const LEVEL_FOLLOW := 0.35
## The level from which the heads start flashing on the beat.
const FLASH_FROM := 3
## Seconds between handing the lit run on to the next head, at rest and at full heat.
const CYCLE_SLOW := 7.0
const CYCLE_FAST := 2.0

## The excitement level, 1 to [constant COUNT], set by the match every tick.
var level := 1
## Whether this room wants lights at all. The Garage in GAME.md 9.4 turns them off: it is a
## place to look at the controls, not a nightclub.
var enabled := true

var _heads: Array[Dictionary] = []
var _time := 0.0
var _floor := Vector2(20.0, 11.25)
## How far through the levels the beams are, 0 at level 1 and 1 at the top, eased so a step up
## sweeps rather than snaps.
var _smooth := 0.0
## Which head the lit run starts at.
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
		if head["lit"]:
			lit += 1
	return lit


func _process(delta: float) -> void:
	if _heads.is_empty():
		return
	if not enabled:
		# A room that wants no rig at all: the posts go with the lights.
		visible = false
		for head: Dictionary in _heads:
			head["lit"] = false
		return
	visible = true
	if not Game.settings.disco_lights:
		for head: Dictionary in _heads:
			_darken(head)
		return
	_smooth = move_toward(_smooth, _climb(), LEVEL_FOLLOW * delta)
	_step_cycle(delta)
	# Everything moves at a crawl until the match gives it a reason not to.
	_time += delta * (0.3 + 1.4 * _smooth)
	var beat := Audio.music_beat()
	var downbeat := Audio.music_beat_index() == 0
	# A flash right on the beat that falls away before the next one.
	# Below [constant FLASH_FROM] the room is not pulsing yet, and it pulses hardest at the top.
	var strength := float(lit_heads() - FLASH_FROM + 1) / float(COUNT - FLASH_FROM + 1)
	var flash := pow(1.0 - beat, 4.0) * (1.3 if downbeat else 1.0) * clampf(strength, 0.0, 1.0)
	for i: int in _heads.size():
		_step_head(_heads[i], is_lit(i), flash)


## How many heads the current level asks for: one per level, and never fewer than one.
func lit_heads() -> int:
	return clampi(level, 1, COUNT)


## How far up the rig the current level sits, 0 at the bottom and 1 at the top.
func _climb() -> float:
	return float(lit_heads() - 1) / float(COUNT - 1)


## While some heads are dark the lit run walks around the rig, so the room keeps changing without
## getting any brighter. With every head already lit there is nothing to hand on.
func _step_cycle(delta: float) -> void:
	if lit_heads() >= COUNT:
		return
	_cycle -= delta
	if _cycle <= 0.0:
		_cycle = lerpf(CYCLE_SLOW, CYCLE_FAST, _smooth)
		_offset = posmod(_offset + 1, COUNT)


## Whether this head is one of those currently taking their turn.
func is_lit(index: int) -> bool:
	return posmod(index - _offset, COUNT) < lit_heads()


func _step_head(head: Dictionary, on: bool, flash: float) -> void:
	head["lit"] = on
	if not on:
		_darken(head)
		return
	var light: SpotLight3D = head["light"]
	(head["beam"] as MeshInstance3D).visible = true
	var lens: StandardMaterial3D = head["lens"]
	lens.albedo_color = head["color"]
	lens.emission_energy_multiplier = LENS_GLOW
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
	var pulse := 1.0 + (0.2 + 0.6 * _smooth) * flash
	light.light_energy = (0.8 + 1.5 * _smooth) * pulse
	light.spot_angle = lerpf(14.0, 24.0, _smooth)
	var tint: StandardMaterial3D = head["tint"]
	# Beams from the edge cut across the camera rather than pointing away from it, so they are
	# kept fainter than an overhead rig would need.
	tint.albedo_color.a = (0.018 + 0.038 * _smooth) * pulse


## A head that is not taking its turn: the lamp stays where it is, pointing where it last
## pointed, with no beam and a dead lens.
func _darken(head: Dictionary) -> void:
	head["lit"] = false
	(head["light"] as SpotLight3D).light_energy = 0.0
	(head["beam"] as MeshInstance3D).visible = false
	var lens: StandardMaterial3D = head["lens"]
	lens.albedo_color = LENS_DARK
	lens.emission_energy_multiplier = 0.0


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
	var lens := StandardMaterial3D.new()
	lens.albedo_color = LENS_DARK
	lens.emission_enabled = true
	lens.emission = color
	lens.emission_energy_multiplier = 0.0
	lens.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	light.add_child(_fixture(dark, lens))
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
		"lens": lens,
		"color": color,
		"lit": false,
		"inward": -side,
		"reach": Vector2(_floor.x * 0.75, _floor.y * 0.75),
		"rate_x": 0.31 + 0.07 * index,
		"rate_z": 0.23 + 0.05 * index,
		"phase": float(index) * 1.1,
	}


## The head itself: a dark housing with a lens the colour of its beam, so the rig reads as a row
## of lamps rather than as beams from nowhere. Parented to the light, so it swings with it.
static func _fixture(dark: StandardMaterial3D, lens_material: StandardMaterial3D) -> Node3D:
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
	lens.material_override = lens_material
	lens.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	lens.position = Vector3(0.0, 0.0, -0.24)
	lens.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	housing.add_child(lens)
	return housing
