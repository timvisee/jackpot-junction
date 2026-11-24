class_name AimGuidePreview
extends FeltWindow
## The aim guide as it is set, GAME.md 8.5, on the Accessibility page under its switch: the first
## seat's kart on the felt, see [FeltWindow], its nose swinging slowly to and fro and the dots
## ahead of it as long, as big, as solid and in the color the settings say, built again the moment
## one changes; none while the guide is switched off. The dots are the guide's own, see
## [method AimGuide.make_dots], placed as it places them.

## The chips left on the felt, clear of the longest guide: a stack and a few lying loose, each
## where it is and how many high.
const CHIPS: Array[Vector4] = [
	Vector4(10.4, 0.0, 1.15, 4), Vector4(10.75, 0.0, 1.3, 1), Vector4(2.6, 0.0, -1.5, 2)
]
## How far ahead of the kart the first dot is measured from, as a kart's cannon has it, see
## [CannonStats].
const MUZZLE := 1.0
## How far the nose swings either way, in radians, and how long a swing there and back takes.
const SWING := 0.12
const SWING_SECONDS := 7.0
## The kart faces down the strip, +X: a model's nose is its -Z.
const FACING := -PI * 0.5

var _kart: Node3D
var _dots: Array[MeshInstance3D] = []
## What the dots and the kart were last built for, see [method AimGuide.wanted].
var _built := []
var _kart_for := []
var _age := 0.0


func _ready() -> void:
	super()
	visibility_changed.connect(_refresh)
	_refresh()


func _chips() -> Array[Vector4]:
	return CHIPS


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_age += delta
	# The palette for a kind of color blindness changed on this page: kart and dots painted anew.
	if Palette.player_color(_color_index()) != _kart_for[1]:
		_refresh()
	if AimGuide.wanted() != _built:
		_build_dots()
	var turn := FACING + sin(_age * TAU / SWING_SECONDS) * SWING
	_kart.rotation.y = turn
	# The way the nose points, from the turn: a model's nose is its -Z.
	var ahead := Vector3(-sin(turn), 0.0, -cos(turn))
	AimGuide.place(_dots, _kart.position + ahead * MUZZLE, ahead)
	var on := Game.settings == null or Game.settings.aim_guide
	for dot: MeshInstance3D in _dots:
		dot.visible = on


## The first seat's kart, in its color and dress, built again should either have changed on another
## page since it was last shown, or its color with the palette for a kind of color blindness on
## this one, and the dots with it.
func _refresh() -> void:
	if not is_visible_in_tree() and _kart != null:
		return
	var settings := Game.settings
	var wanted := [
		_color_index(),
		Palette.player_color(_color_index()),
		settings.seat_style(0) if settings != null else []
	]
	if wanted == _kart_for:
		return
	_kart_for = wanted
	if _kart != null:
		_kart.queue_free()
	var style: KartStyle = KartStyle.from_array(wanted[2]) if settings != null else null
	_kart = KartVisuals.display_model(_color_index(), style)
	_kart.rotation.y = FACING
	felt.add_child(_kart)
	_build_dots()


func _build_dots() -> void:
	for dot: MeshInstance3D in _dots:
		dot.queue_free()
	_built = AimGuide.wanted()
	_dots = AimGuide.make_dots(Palette.player_color(_color_index()))
	for dot: MeshInstance3D in _dots:
		felt.add_child(dot)


## The first seat's color, its favorite or the one its place gives it, as its kart has it.
static func _color_index() -> int:
	var chosen := Game.settings.seat_color(0) if Game.settings != null else -1
	return maxi(chosen, 0)
