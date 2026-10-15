class_name SlotDial
extends MeshInstance3D
## A clock over a slot machine, GAME.md 3.15, shown to a kart that drove onto it while still resting
## from its last pull: a wedge in its own color for the rest it still has to wait, emptying as the
## rest runs out. Turned to the camera wherever it stands, see slot_dial.gdshader.

const LOOK: Shader = preload("res://scenes/arena/slot_dial.gdshader")
## How big across, and how high over the pad.
const SIDE := 0.8
const HEIGHT := 2.4

var _material: ShaderMaterial


func _init() -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * SIDE
	mesh = quad
	_material = ShaderMaterial.new()
	_material.shader = LOOK
	material_override = _material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	position = Vector3(0.0, HEIGHT, 0.0)
	visible = false


## Shows [param left] of the rest still to wait, from 1 to 0, in [param ink], as strongly as
## [param shown]; nothing at none.
func show_left(left: float, shown: float, ink: Color) -> void:
	visible = shown > 0.0 and left > 0.0
	if not visible:
		return
	_material.set_shader_parameter(&"left", clampf(left, 0.0, 1.0))
	_material.set_shader_parameter(&"shown", clampf(shown, 0.0, 1.0))
	_material.set_shader_parameter(&"left_color", ink)
