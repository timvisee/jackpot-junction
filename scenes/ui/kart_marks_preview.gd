class_name KartMarksPreview
extends FeltWindow
## The kart rings and the marker over a player's own kart as they are set, GAME.md 8.5, on the
## Accessibility page under Seeing: the first seat's kart facing the camera between two rivals
## turned toward it, on the felt, see [FeltWindow], each nosing slowly to and fro; a ring under
## the first seat's kart, under all three or under none, as Kart rings says, and the marker over
## the first seat's kart while it is asked for, see [KartRings] and [KartPointers], drawn as a
## match draws them; and at its left edge the arrow at a fourth kart out of the picture, as Rival
## arrows says. The first seat's kart in its own color and dress, the rivals in the second and third
## seats' colors and the one out of the picture in the fourth's, and all of them in the palette for
## a kind of color blindness the moment one is chosen.

## Where the three karts stand, the first seat's in the middle, and which way each faces: a model's
## nose is its -Z, so PI faces the camera, south, and the rivals face south-east and south-west.
const SPOTS: Array[Vector3] = [
	Vector3(1.9, 0.0, -0.02), Vector3(6.4, 0.0, -0.02), Vector3(10.9, 0.0, -0.02)
]
const FACINGS: Array[float] = [-PI * 0.75, PI, PI * 0.75]
## Where the fourth kart is, out of the picture to the left, level with the rest, for the arrow at
## it to point at.
const AWAY := Vector3(-2.6, 0.0, -0.02)
## How big a ring is across its middle, in meters: as big as one under the match camera at the
## distance it usually keeps, see [constant KartRings.PER_METER].
const RING := 1.6
## The chips left on the felt, clear of the rings: each where it stands and how many high.
const CHIPS: Array[Vector4] = [
	Vector4(8.65, 0.0, -1.3, 4), Vector4(4.15, 0.0, 0.95, 1), Vector4(4.45, 0.0, 0.8, 1)
]
## How far the noses swing either way, in radians, and how long a swing there and back takes.
const SWING := 0.1
const SWING_SECONDS := 8.0

## The three karts, their rings, and what they were last built for: the colors, and the first
## seat's dress.
var _karts: Array[Node3D] = []
var _rings: Array[Array] = []
var _built := []
var _marks: Control
var _age := 0.0


func _ready() -> void:
	super()
	_marks = Control.new()
	_marks.name = "Marks"
	_marks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_marks.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_marks.draw.connect(_draw_marks)
	add_child(_marks)
	visibility_changed.connect(_refresh)
	_refresh()


func _chips() -> Array[Vector4]:
	return CHIPS


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_age += delta
	if _wanted() != _built:
		_refresh()
	for i: int in _karts.size():
		var swing := sin(_age * TAU / SWING_SECONDS + i * 2.1) * SWING
		_karts[i].rotation.y = FACINGS[i] + swing
		for ring: MeshInstance3D in _rings[i]:
			ring.visible = _ringed(i)
	_marks.queue_redraw()


## Whether kart [param i] has a ring under it as Kart rings is set: the first seat's, the middle
## one, for My kart, and all three for All karts.
static func _ringed(i: int) -> bool:
	var which := Game.settings.kart_rings if Game.settings != null else ViewChoices.RINGS_OFF
	return which == ViewChoices.RINGS_ALL or (which == ViewChoices.RINGS_HERE and i == 1)


## The three karts and their rings built again should a color or the first seat's dress have
## changed since they were last, on another page or with the palette on this one.
func _refresh() -> void:
	if not is_visible_in_tree() and not _karts.is_empty():
		return
	var wanted := _wanted()
	if wanted == _built:
		return
	_built = wanted
	for kart: Node3D in _karts:
		kart.queue_free()
	for rings: Array in _rings:
		for ring: MeshInstance3D in rings:
			ring.queue_free()
	_karts.clear()
	_rings.clear()
	var colors: Array[int] = wanted[0]
	for i: int in SPOTS.size():
		var style: KartStyle = KartStyle.from_array(wanted[1]) if i == 1 else null
		var kart := KartVisuals.display_model(colors[i], style)
		kart.position = SPOTS[i]
		kart.rotation.y = FACINGS[i]
		felt.add_child(kart)
		_karts.append(kart)
		var color := Palette.player_color(colors[i])
		var rings := KartRings.made(color)
		for ring: MeshInstance3D in rings:
			felt.add_child(ring)
		KartRings.lay(rings, SPOTS[i], color, RING)
		_rings.append(rings)


## What the karts are built for: their colors, left to right, see [method colors_of], with the
## colors those come out in now; and the first seat's dress.
func _wanted() -> Array:
	var settings := Game.settings
	var colors := colors_of(settings)
	var inks: Array[Color] = []
	for each: int in colors:
		inks.append(Palette.player_color(each))
	return [colors, settings.seat_style(0) if settings != null else [], inks]


## The karts' colors, left to right: the second seat's, the first seat's in the middle and the
## third seat's, then the fourth seat's, the kart out of the picture; each its favorite where one
## is picked and otherwise the one its place gives it, as at a table, and never one another's: a
## color taken already gives way to the first free.
static func colors_of(settings: Settings) -> Array[int]:
	var taken: Array[int] = []
	for seat: int in [0, 1, 2, 3]:
		var color := settings.seat_color(seat) if settings != null else -1
		if color < 0:
			color = seat
		if color in taken:
			color = 0
			while color in taken:
				color += 1
		taken.append(color)
	return [taken[1], taken[0], taken[2], taken[3]]


## The marker over the first seat's kart while it is asked for, as [KartPointers] hangs it; and
## the arrow at the kart out of the picture, see [method rival_arrow].
func _draw_marks() -> void:
	if _built.is_empty() or Game.settings == null:
		return
	var arrow := rival_arrow()
	if not arrow.is_empty():
		var color := Palette.player_color(_built[0][3])
		KartPointers.draw_sign(_marks, arrow.at, arrow.way, arrow.length, color, arrow.shows)
	if not Game.settings.kart_marker:
		return
	var color := Palette.player_color(_built[0][1])
	var over := SPOTS[1] + Vector3.UP * (CameraRig.KART_MIDDLE + KartPointers.MARKER_LIFT)
	KartPointers.draw_sign(_marks, on_window(over), Vector2.DOWN, KartPointers.MARKER, color)


## The arrow at the kart out of the picture to the left, see [constant AWAY], as a match points at
## a rival there, see [KartPointers]: where its tip is on the window, which way it points, how long
## it is and how much of it shows; empty for Rival arrows Off.
func rival_arrow() -> Dictionary:
	var look := KartPointers.rival_look(Game.settings.rival_arrows)
	if look.x <= 0.0:
		return {}
	var away := on_window(AWAY + Vector3.UP * CameraRig.KART_MIDDLE)
	var way := (away - size * 0.5).normalized()
	return {at = KartPointers.on_edge(size, way), way = way, length = look.x, shows = look.y}
