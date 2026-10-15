class_name TestBench
extends Node3D
## The board the Garage's tests are read off, GAME.md 9.4: standing on its legs outside the right
## wall beside the rolling road, turned to the camera. A round dial for the rolling road, its needle
## on the speed the kart on the rollers is turning them at and a red tell-tale left at the best
## any kart reached this visit, see [Dyno], with the speed in digits under it; and in digits beside
## it the speed trap's last and best, see [SpeedTrap], and the longest drift anybody held, in
## seconds to the tenth.
##
## Scenery that reads: the digits are one [MultiMesh] of segments, see [SegmentDigits], the rest a
## few still meshes. Speeds are shown the way the HUD shows them, in its units.

## The board: its face, how high its foot stands over the rail it is bolted to, how far along the
## rail toward the back it stands from the rolling road's middle, and how far it turns from facing
## the camera toward facing the room, in radians about Y.
const FACE := Vector2(2.5, 1.55)
const FOOT := 0.3
const BACK := 2.6
const TURN := -0.55
const FRAME := 0.08
const LEG := 0.1
const BOARD_INK := Color(0.07, 0.07, 0.09)
const STEEL := Color(0.17, 0.17, 0.2)
## The dial: where its middle is on the face, how big, the sweep of its scale from empty to full,
## and its colors.
const DIAL_AT := Vector2(-0.6, -0.04)
const DIAL := 0.5
const SWEEP_FROM := deg_to_rad(225.0)
const SWEEP := deg_to_rad(270.0)
const TICKS := 11
const DIAL_INK := Color(0.93, 0.9, 0.82)
const RIM_INK := Color(0.12, 0.12, 0.14)
const NEEDLE_INK := Color(0.95, 0.42, 0.12)
const TELLTALE_INK := Color(0.85, 0.1, 0.1)
## Full scale, as a share of the top speed of the kart on the rollers, the same as the HUD's.
const FULL := 1.9
## The digits: how big, how far apart, and where each row of three stands on the face, the first
## row's middle and how far down the next is.
const DIGIT := Vector2(0.11, 0.2)
const SEGMENT := 0.028
const SPACING := 0.155
const ROWS_AT := Vector2(0.84, 0.36)
const ROW_GAP := 0.26
## Where the rows' words stand, their middles, between the dial and the digits.
const WORDS_X := 0.27
const LIT := Color(1.0, 0.72, 0.18)
const DARK := Color(0.14, 0.12, 0.1)
## The words on the face, a row's for each row of digits: the rolling road's speed now, the speed
## trap's last and best, and the longest drift, its seconds to the tenth.
const TITLE := "TEST BENCH"
const ROW_WORDS: Array[String] = ["DYNO", "TRAP", "BEST", "DRIFT"]
const DRIFT_ROW := 3
const WORDS_INK := Color(0.82, 0.84, 0.9)
const WORDS_SIZE := 64

var match_node: Match
var dyno: Dyno
var trap: SpeedTrap

var _bars: MultiMesh
var _rows: Array[Array] = []
var _needle: Node3D
var _telltale: Node3D
var _needle_at := 0.0
var _shown := ""


## The board beside [param for_dyno], reading it and [param for_trap].
static func add_to(in_match: Match, for_dyno: Dyno, for_trap: SpeedTrap) -> TestBench:
	var bench := TestBench.new()
	bench.name = "TestBench"
	bench.match_node = in_match
	bench.dyno = for_dyno
	bench.trap = for_trap
	in_match.arena.add_child(bench)
	bench._build()
	return bench


## [param speed], in meters a second, the way the HUD would say it, in its units.
static func speed_text(speed: float) -> String:
	var unit := Game.settings.speed_unit()
	return "%d %s" % [_shown_speed(speed, unit), SpeedUnits.word(unit)]


static func _shown_speed(speed: float, unit: String) -> int:
	return roundi(SpeedUnits.from_kmh(speed * MatchHud.SPEED_SCALE, unit))


func _build() -> void:
	var arena := match_node.arena
	var half := arena.world_size() * 0.5
	var bay := dyno.area.get_center()
	# On the right rail, a little back from the rolling road, so the kart on it is not behind it.
	var rail := half.x - arena.grid.cell_size * 0.5
	position = Vector3(rail, arena.layout.wall_height, bay.y - BACK)
	rotation.y = TURN
	var face := Node3D.new()
	face.position = Vector3(0.0, FOOT + FACE.y * 0.5, 0.0)
	add_child(face)
	var steel := arena.surfaces.metal(STEEL)
	for side: float in [-1.0, 1.0]:
		var leg := _box(Vector3(LEG, FOOT + FACE.y * 0.5, LEG), steel)
		leg.position = Vector3(side * FACE.x * 0.38, (FOOT + FACE.y * 0.5) * 0.5, -0.06)
		add_child(leg)
	var frame := _box(Vector3(FACE.x + FRAME * 2.0, FACE.y + FRAME * 2.0, 0.08), steel)
	frame.position = Vector3(0.0, 0.0, -0.05)
	face.add_child(frame)
	face.add_child(_flat(FACE, arena.surfaces.painted(BOARD_INK), Vector2.ZERO, 0.0))
	_dial(face)
	_digits(face)
	_words(face, TITLE, Vector2(0.0, FACE.y * 0.5 - 0.13), 0.09, WORDS_INK)
	for i: int in ROW_WORDS.size():
		_words(face, ROW_WORDS[i], Vector2(WORDS_X, ROWS_AT.y - ROW_GAP * i), 0.065, WORDS_INK)
	# The unit on the dial's face, in the gap at its foot, as the HUD's dial has it.
	var unit := SpeedUnits.word(Game.settings.speed_unit())
	_words(face, unit, DIAL_AT + Vector2(0.0, -DIAL * 0.62), 0.06, RIM_INK)
	_show()


## The dial: its face, rim and ticks, the needle and the tell-tale on their pivots.
func _dial(face: Node3D) -> void:
	var surfaces := match_node.arena.surfaces
	var rim := _disc(DIAL + 0.04, surfaces.painted(RIM_INK), 0.005)
	var disc := _disc(DIAL, surfaces.marking(DIAL_INK), 0.012)
	for made: MeshInstance3D in [rim, disc]:
		made.position += Vector3(DIAL_AT.x, DIAL_AT.y, 0.0)
		face.add_child(made)
	var ink := surfaces.painted(RIM_INK)
	for i: int in TICKS:
		var angle := SWEEP_FROM - SWEEP * float(i) / (TICKS - 1)
		var out := Vector2(cos(angle), sin(angle))
		var long := 0.09 if i % 5 == 0 else 0.05
		var tick := _flat(
			Vector2(long, 0.018), ink, DIAL_AT + out * (DIAL - 0.03 - long * 0.5), 0.02
		)
		tick.rotation.z = angle
		face.add_child(tick)
	_telltale = _pointer(face, surfaces.painted(TELLTALE_INK), 0.012, 0.024)
	_needle = _pointer(face, surfaces.painted(NEEDLE_INK), 0.028, 0.03)
	var cap := _disc(0.05, ink, 0.034)
	cap.position += Vector3(DIAL_AT.x, DIAL_AT.y, 0.0)
	face.add_child(cap)


func _pointer(face: Node3D, skin: Material, wide: float, out: float) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = Vector3(DIAL_AT.x, DIAL_AT.y, 0.0)
	face.add_child(pivot)
	var long := DIAL - 0.06
	pivot.add_child(_flat(Vector2(long, wide), skin, Vector2(long * 0.5 - 0.04, 0.0), out))
	pivot.rotation.z = SWEEP_FROM
	return pivot


## The digits: three on each row beside the dial, the drift's with a point before its last.
func _digits(face: Node3D) -> void:
	_bars = SegmentDigits.bars(7 * 3 * ROW_WORDS.size() + 1)
	var segments := MultiMeshInstance3D.new()
	segments.name = "Segments"
	segments.multimesh = _bars
	segments.material_override = SegmentDigits.look(DARK)
	segments.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	face.add_child(segments)
	var first := 0
	for i: int in ROW_WORDS.size():
		_rows.append(_three(Vector2(ROWS_AT.x, ROWS_AT.y - ROW_GAP * i), first))
		first += 21
	var drift := Vector2(ROWS_AT.x, ROWS_AT.y - ROW_GAP * DRIFT_ROW)
	var point := drift + Vector2(SPACING * 0.5, -DIGIT.y * 0.5)
	SegmentDigits.bar(_bars, first, point, Vector2(SEGMENT, SEGMENT), LIT)
	_bars.set_instance_custom_data(first, Color(1.0, 0.0, 0.0))


func _three(middle: Vector2, first: int) -> Array[Dictionary]:
	var three: Array[Dictionary] = []
	for i: int in 3:
		var at := middle + Vector2(SPACING * (i - 1), 0.0)
		three.append(SegmentDigits.digit(_bars, first + i * 7, at, DIGIT, SEGMENT, LIT))
	return three


func _process(delta: float) -> void:
	var full := _full_speed()
	var target := clampf(dyno.speed / full, 0.0, 1.0)
	_needle_at = lerpf(_needle_at, target, 1.0 - exp(-12.0 * delta))
	_needle.rotation.z = SWEEP_FROM - SWEEP * _needle_at
	_telltale.rotation.z = SWEEP_FROM - SWEEP * clampf(dyno.best / full, 0.0, 1.0)
	_show()


## What full scale on the dial is: the share of the top speed of the kart on the rollers, or of a
## kart as it comes when there is none.
func _full_speed() -> float:
	var top := dyno.held.stats.top_speed if dyno.held != null else KartStats.new().top_speed
	return top * FULL


## Lights the digits, when what they say has changed.
func _show() -> void:
	var unit := Game.settings.speed_unit()
	var drift := 0.0
	for slot: PlayerSlot in match_node.slots:
		if not slot.is_dummy():
			drift = maxf(drift, slot.stats.value(&"longest_drift"))
	var shown: Array[String] = [
		"%3d" % _shown_speed(dyno.speed, unit),
		_three_of(trap.last, unit),
		_three_of(trap.best, unit),
		"%3d" % mini(roundi(drift * 10.0), 999) if drift > 0.0 else "   ",
	]
	var all := "".join(shown)
	if all == _shown:
		return
	_shown = all
	for i: int in _rows.size():
		SegmentDigits.show(_bars, _rows[i], shown[i], LIT)


static func _three_of(speed: float, unit: String) -> String:
	return "%3d" % mini(_shown_speed(speed, unit), 999) if speed > 0.0 else "   "


## [param text] on the face, its middle at [param at], its capitals [param tall] high in
## [param ink].
func _words(face: Node3D, text: String, at: Vector2, tall: float, ink: Color) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font = Type.mark_font()
	label.font_size = WORDS_SIZE
	label.outline_size = 0
	label.pixel_size = tall / (WORDS_SIZE * Type.CAP_HEIGHT)
	label.modulate = ink
	label.position = Vector3(at.x, at.y, 0.03)
	face.add_child(label)
	return label


## A flat rectangle on the face, [param size] across, its middle at [param at], [param out] in
## front of it.
static func _flat(size: Vector2, skin: Material, at: Vector2, out: float) -> MeshInstance3D:
	var made := _box(Vector3(size.x, size.y, 0.01), skin)
	made.position = Vector3(at.x, at.y, out)
	return made


static func _disc(radius: float, skin: Material, out: float) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.01
	mesh.radial_segments = 40
	mesh.rings = 1
	var made := MeshInstance3D.new()
	made.mesh = mesh
	made.material_override = skin
	made.rotation.x = PI * 0.5
	made.position = Vector3(0.0, 0.0, out)
	made.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return made


static func _box(size: Vector3, skin: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var made := MeshInstance3D.new()
	made.mesh = mesh
	made.material_override = skin
	made.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return made
