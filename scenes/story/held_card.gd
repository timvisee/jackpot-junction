class_name HeldCard
extends Node2D
## A card held up to be looked at, as the license is, see [TiltedCard], for a card that is not the
## license: the opening invitation's, STORY.md 6.1a, and the House's invitation to the Final Hand,
## 8.1. [member drawn] is drawn once into a picture of its own, sharper than it is shown and
## smoothed at its edges, with room round it for its corners as it turns, and shown through the
## license's shader, turned a little toward the mouse, the stick or the phone, the light catching
## its foil: where a picture of where it shines says, [member shine], or else wherever it is gold.
## Its middle is this node's origin, and it moves, turns and scales as a Node2D without being drawn
## again; [method refresh] draws it again when it changes. It turns right over as the license does,
## see [method turn_over], saying as it passes edge-on which side the eye now sees, for whoever drew
## it to draw that side, see [signal side_changed].

## The side seen has changed in the middle of a turn over: [param back] whether it is the back.
signal side_changed(back: bool)

## The room round it in its picture, as a share of its longer side; how much sharper the picture
## is drawn than it is shown; how much lighter its near side and darker its far side; how bright
## and how tight the light on its foil is; and how far it turns toward the mouse, as a share of how
## far the license does.
const ROOM := 0.15
const SHARPEN := 2.0
const RELIEF := 0.45
const SHINE := 0.65
const SHINE_TIGHT := 7.0
const TILT := 0.8

## The card, and how big it is; and the same card drawn as where it shines, white on black, or null
## for its gold to say.
var drawn: Control
var drawn_size := Vector2.ZERO
var shine: Control
## How much it follows the mouse, the stick or the phone, 0 to 1: none while it is carried
## somewhere or put down.
var follow := 1.0
## How much sharper than it is shown its picture is drawn, set before it is in the tree.
var sharpen := SHARPEN
## Whether its back is the side seen, see [method turn_over].
var back := false
## A turn of its own on top of the mouse's, as a card peeled up off what it was glued to is turned,
## in the same measure as the tilt, -1 to 1 either way.
var peel := Vector2.ZERO:
	set(value):
		peel = value
		if look != null:
			_aim()
## The shader it is shown through, see [TiltedCard].
var look: ShaderMaterial
## A fixed direction to turn toward for a posed shot, -1 to 1 each way (left and up negative),
## overriding the mouse and the stick while it is a vector; null to follow them again.
var posed: Variant = null

var _sheet: SubViewport
var _shine_sheet: SubViewport
var _face: TextureRect
var _tilt := Vector2.ZERO
var _mouse: Variant = null
var _pull := Vector3.ZERO
## How far round a turn over is, and the side it started from.
var _over := 0.0
var _turning := false
var _from_back := false


## [param card], [param card_size] big, held; [param shines], drawn as where it shines, for its
## light, or null for its gold.
static func of(card: Control, card_size: Vector2, shines: Control = null) -> HeldCard:
	var held := HeldCard.new()
	held.drawn = card
	held.drawn_size = card_size
	held.shine = shines
	return held


func _ready() -> void:
	var room := Vector2.ONE * maxf(drawn_size.x, drawn_size.y) * ROOM
	var picture := (drawn_size + room * 2.0).ceil()
	_sheet = _sheet_of(drawn, picture, room, sharpen)
	_sheet.msaa_2d = Viewport.MSAA_4X
	look = ShaderMaterial.new()
	look.shader = TiltedCard.SHADER
	look.set_shader_parameter("extent", picture * 0.5 / drawn_size.x)
	look.set_shader_parameter("depth", TiltedCard.DEPTH * maxf(1.0, drawn_size.y / drawn_size.x))
	look.set_shader_parameter("relief", RELIEF)
	look.set_shader_parameter("sheen", SHINE)
	look.set_shader_parameter("sheen_tight", SHINE_TIGHT)
	if shine != null:
		_shine_sheet = _sheet_of(shine, picture, room, 1.0)
		look.set_shader_parameter("shine", _shine_sheet.get_texture())
		look.set_shader_parameter("shine_masked", 1.0)
	else:
		look.set_shader_parameter("foil", 1.0)
	_face = TextureRect.new()
	_face.name = "Face"
	_face.texture = _sheet.get_texture()
	_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_face.stretch_mode = TextureRect.STRETCH_SCALE
	_face.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_face.position = -drawn_size * 0.5 - room
	_face.size = picture
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_face.material = look
	add_child(_face)
	_pull = Input.get_gravity()


## A picture of [param of], [param picture] big with [param room] round it, drawn once,
## [param sharper] times as sharp as it is shown.
func _sheet_of(of: Control, picture: Vector2, room: Vector2, sharper: float) -> SubViewport:
	var sheet := SubViewport.new()
	sheet.transparent_bg = true
	sheet.disable_3d = true
	sheet.gui_disable_input = true
	sheet.size = Vector2i(picture * sharper)
	sheet.size_2d_override = Vector2i(picture)
	sheet.size_2d_override_stretch = true
	sheet.render_target_update_mode = SubViewport.UPDATE_ONCE
	of.position = room
	sheet.add_child(of)
	add_child(sheet)
	return sheet


## Drawn again, the card and where it shines, once: after it has changed.
func refresh() -> void:
	_sheet.render_target_update_mode = SubViewport.UPDATE_ONCE
	if _shine_sheet != null:
		_shine_sheet.render_target_update_mode = SubViewport.UPDATE_ONCE


func _input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion != null and not TouchInput.enabled:
		_mouse = motion.global_position


## Turned toward the mouse, the stick or the phone, as far as it follows them.
func _process(delta: float) -> void:
	if look == null:
		return
	_pull = _pull.lerp(Input.get_gravity(), 1.0 - exp(-TiltedCard.PHONE_SETTLE * delta))
	var held := get_global_transform()
	var shown := drawn_size * held.get_scale().abs()
	var over := Rect2(held.get_origin() - shown * 0.5, shown)
	var want: Vector2 = posed if posed is Vector2 else TiltedCard.wanted(over, _mouse, _pull)
	var toward := want * TILT * follow
	var tilt := _tilt.lerp(toward, 1.0 - exp(-TiltedCard.FOLLOW * delta))
	if not tilt.is_equal_approx(_tilt):
		_tilt = tilt
		_aim()


## The picture turned as the card is, as the license's is, see [method TiltedCard._aim]: the tilt,
## and the turn over on top of it, the side seen changing as it passes edge-on.
func _aim() -> void:
	var yaw := (_tilt.x + peel.x) * TiltedCard.TURN + _over
	if _turning:
		var showing := _from_back != (cos(yaw) < 0.0)
		if showing != back:
			back = showing
			side_changed.emit(back)
	var pitch := TiltedCard.pitch((_tilt.y + peel.y) * TiltedCard.TURN, _over)
	look.set_shader_parameter("turn", Vector2(yaw, pitch))


## Turns it right over about its upright axis, to its back or its front again, the way back the
## way it came, taking [param takes], as the license turns.
func turn_over(takes := TiltedCard.TURN_OVER) -> void:
	if _turning or look == null:
		return
	_turning = true
	_from_back = back
	var turn := create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	turn.tween_method(_turn_by, 0.0, PI * (-1.0 if _from_back else 1.0), takes)
	turn.tween_callback(_turned_over)
	Audio.play_sfx(&"page", -10.0, 0.0)


func _turn_by(angle: float) -> void:
	_over = angle
	_aim()


func _turned_over() -> void:
	_turning = false
	_over = 0.0
	_aim()


## Whether it is in the middle of turning over.
func is_turning() -> bool:
	return _turning
