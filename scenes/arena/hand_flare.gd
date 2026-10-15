class_name HandFlare
extends Node3D
## The best hands made, seen on the table, GAME.md 7.3: a Four of a Kind or a Flush sends a column
## of gold light up off the kart, every screen seeing every kart's. See [HandFanfare] for what the
## player's own screen does. A ring of the hand's suits went up with every hand once, see
## [SuitBurst], and was too much for it.

## The column: how high, how wide and for how long.
const COLUMN_HEIGHT := 5.0
const COLUMN_WIDE := 0.55
const COLUMN_TIME := 1.1

var _age := 0.0
var _beam: MeshInstance3D
var _beam_look: StandardMaterial3D


## [param kart]'s hand gained [param gained]: the column, for a Four of a Kind or better.
static func on_hands_changed(gained: Array[int], _lost: Array[int], kart: Kart) -> void:
	if gained.is_empty() or not is_instance_valid(kart) or not kart.is_inside_tree():
		return
	if not kart.alive or kart.is_decoy() or Game.is_headless():
		return
	var best: int = gained.min()
	if best > JokerHands.Hand.FOUR_OF_A_KIND:
		return
	var flare := HandFlare.new()
	kart.add_child(flare)
	flare.position = Vector3(0.0, 0.6, 0.0)


func _ready() -> void:
	_beam = MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = COLUMN_WIDE * 0.6
	cylinder.bottom_radius = COLUMN_WIDE
	cylinder.height = COLUMN_HEIGHT
	cylinder.cap_top = false
	cylinder.cap_bottom = false
	_beam.mesh = cylinder
	_beam_look = StandardMaterial3D.new()
	_beam_look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_beam_look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_beam_look.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_beam_look.cull_mode = BaseMaterial3D.CULL_DISABLED
	_beam_look.albedo_color = Color(Palette.CHIP_GOLD, 0.0)
	_beam.material_override = _beam_look
	_beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_beam.position = Vector3(0.0, COLUMN_HEIGHT * 0.5 - 0.4, 0.0)
	add_child(_beam)


func _process(delta: float) -> void:
	_age += delta
	var b := clampf(_age / COLUMN_TIME, 0.0, 1.0)
	_beam_look.albedo_color.a = 0.45 * sin(PI * b)
	_beam.scale = Vector3(1.0, 0.4 + 0.6 * ease(b, 0.3), 1.0)
	if _age >= COLUMN_TIME:
		queue_free()
