class_name DiscoLights
extends Node3D
## Moving-head spot lights over the arena, GAME.md 8.1. They follow the excitement meter: one
## light drifting slowly over a quiet lap, more of them joining and sweeping wider and faster as
## the match heats up, all six at their widest during Last Call. Every head flashes on the beat
## of the music, harder on the first beat of the bar, and the flash too is barely there until the
## match is hot.
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
const MOUNT_HEIGHT := 8.5
const BEAM_LENGTH := 11.0
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
	if not Game.settings.disco_lights:
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
	if not on:
		return
	var reach: Vector2 = head["reach"] * (0.35 + 0.65 * _smooth)
	var target := Vector3(
		clampf(sin(_time * head["rate_x"] + head["phase"]) * reach.x, -_floor.x, _floor.x),
		0.0,
		clampf(cos(_time * head["rate_z"] + head["phase"]) * reach.y, -_floor.y, _floor.y)
	)
	if absf(target.x - light.position.x) < 0.02 and absf(target.z - light.position.z) < 0.02:
		target.x += 0.05
	light.look_at(target, Vector3.UP)
	var pulse := 1.0 + (0.2 + 1.3 * _smooth) * flash
	light.light_energy = (0.9 + 3.2 * _smooth) * pulse
	light.spot_angle = lerpf(14.0, 24.0, _smooth)
	var beam: StandardMaterial3D = head["beam"]
	beam.albedo_color.a = (0.025 + 0.1 * _smooth) * pulse


func _build_head(index: int) -> Dictionary:
	var color := COLORS[index % COLORS.size()]
	var light := SpotLight3D.new()
	light.name = "Head%d" % index
	light.light_color = color
	light.light_energy = 1.0
	light.spot_range = BEAM_LENGTH * 1.6
	light.spot_angle = 16.0
	light.spot_attenuation = 0.8
	light.shadow_enabled = false
	# Mounted in two rows over the table, spread along it, each sweeping its own way.
	var across := (float(index % 3) - 1.0) * _floor.x * 0.62
	var along := (-1.0 if index < 3 else 1.0) * _floor.y * 0.72
	light.position = Vector3(across, MOUNT_HEIGHT, along)
	add_child(light)
	# Aimed short of straight down: looking_at cannot pick a roll from a target directly below.
	light.look_at(Vector3(across * 0.5, 0.0, along * 0.5), Vector3.UP)
	var beam_material := StandardMaterial3D.new()
	beam_material.albedo_color = Color(color.r, color.g, color.b, 0.03)
	beam_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	beam_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var beam := MeshInstance3D.new()
	beam.name = "Beam"
	var cone := CylinderMesh.new()
	# The wide end lands on the floor: after the tilt below, the mesh's top points away from the
	# light along its beam.
	cone.top_radius = 1.7
	cone.bottom_radius = 0.1
	cone.height = BEAM_LENGTH
	beam.mesh = cone
	beam.material_override = beam_material
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beam.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	beam.position = Vector3(0.0, 0.0, -BEAM_LENGTH * 0.5)
	light.add_child(beam)
	return {
		"light": light,
		"beam": beam_material,
		"reach": Vector2(_floor.x * 0.75, _floor.y * 0.75),
		"rate_x": 0.31 + 0.07 * index,
		"rate_z": 0.23 + 0.05 * index,
		"phase": float(index) * 1.1,
	}
