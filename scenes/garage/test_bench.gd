class_name TestBench
extends Node3D
## The board the Garage's tests are read off, GAME.md 9.4: bolted to a scaffold of its own on the
## floor outside the right wall, beside the rolling road and over the wall, turned to the camera,
## on the patch the room's clutter keeps clear for it, see [GarageGear]. A round dial for the
## rolling road, its needle on the speed the kart on the rollers is turning them at and a red
## tell-tale left at the best any kart reached this visit, see [Dyno]; and in digits beside it the
## rolling road's speed, the speed trap's last and best, see [SpeedTrap], and the longest drift
## anybody held, in seconds to the tenth. A close look at it comes up while a kart is on the
## rollers and for a few seconds after a time is set, see [BenchView].
##
## Scenery that reads: the digits are one [MultiMesh] of segments, see [SegmentDigits], the rest a
## few still meshes. Speeds are shown the way the HUD shows them, in its units.

## The board: its face, how high its foot stands, clear over the wall, and how far it turns from
## facing the camera toward facing the room, in radians about Y.
const FACE := Vector2(2.5, 1.55)
const FOOT := 1.5
const TURN := -0.3
const FRAME := 0.08
## The scaffold it is bolted to: its tubes, and how deep it stands, front to back.
const TUBE := 0.09
const DEEP := 0.6
## How long the close look stays up after a time is set, in seconds, and its titles.
const LOOK_HOLD := 4.0
## How much faster than the best before, in meters a second, a run on the rollers is a new best.
const NEW_BEST := 0.05
const DYNO_TITLE := "Dyno"
const SPEED_TRAP := "Speed trap"
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
## The middle of the board's face, +Z out of it, for the close look to film.
var face: Node3D
## The close look at the board while it is up, and how long it has left once nothing holds it up.
var view: BenchView
var _look_left := 0.0
## The rolling road's best before the kart on it now came on, to tell a new best by.
var _dyno_best_was := 0.0

var _bars: MultiMesh
var _rows: Array[Array] = []
## The drift's point, its bar's instance.
var _point := 0
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
	position = GarageGear.bench_spot(arena)
	rotation.y = TURN
	face = Node3D.new()
	face.name = "Face"
	face.position = Vector3(0.0, FOOT + FACE.y * 0.5, 0.0)
	add_child(face)
	var steel := arena.surfaces.metal(STEEL)
	_scaffold(steel)
	dyno.held_kart.connect(_on_held)
	dyno.let_go.connect(_on_let_go)
	trap.timed.connect(_on_timed)
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


## What the board is bolted to, the way the Garage puts a sign up, see [Billboard]: four uprights
## from the floor to its foot, a lift across them halfway and a brace across the back, baked into
## one mesh, since none of it moves and all of it is the same steel.
func _scaffold(steel: Material) -> void:
	var stand := Node3D.new()
	stand.name = "Scaffold"
	add_child(stand)
	var wide := FACE.x - TUBE * 2.0
	var tall := FOOT + FACE.y * 0.5
	for side: float in [-1.0, 1.0]:
		for back: float in [-1.0, 1.0]:
			var leg := _box(Vector3(TUBE, tall, TUBE), steel)
			leg.position = Vector3(side * wide * 0.5, tall * 0.5, -DEEP * 0.5 + back * DEEP * 0.5)
			stand.add_child(leg)
		var lift := _box(Vector3(TUBE, TUBE, DEEP), steel)
		lift.position = Vector3(side * wide * 0.5, FOOT * 0.5, -DEEP * 0.5)
		stand.add_child(lift)
	var across := _box(Vector3(wide, TUBE, TUBE), steel)
	across.position = Vector3(0.0, FOOT * 0.5, -DEEP)
	stand.add_child(across)
	var rise := FOOT * 0.8
	var brace := _box(Vector3(sqrt(wide * wide + rise * rise), TUBE, TUBE), steel)
	brace.position = Vector3(0.0, FOOT * 0.5, -DEEP)
	brace.rotation.z = atan2(rise, wide)
	stand.add_child(brace)
	if match_node.arena.bake_scenery:
		Bake.merge(stand)


## The close look put up, or kept up, titled [param title] and saying [param line].
func _look(title: String, line: String) -> void:
	if view == null or not is_instance_valid(view):
		view = BenchView.of(self, title, line)
		add_child(view)
	else:
		view.say(title, line)


func _on_held(_slot: PlayerSlot) -> void:
	_dyno_best_was = dyno.best
	_look(DYNO_TITLE, "Hold the throttle, back off to leave")


func _on_let_go(_slot: PlayerSlot, at_best: float) -> void:
	_look(DYNO_TITLE, "Best this visit: %s" % speed_text(at_best))
	_look_left = LOOK_HOLD
	# A new best on the rollers jolts the feed.
	if at_best > _dyno_best_was + NEW_BEST:
		view.feed.jolt()


func _on_timed(_slot: PlayerSlot, speed: float) -> void:
	var line := "Through at %s" % speed_text(speed)
	var best := speed >= trap.best
	if best:
		line += "  ·  the best yet"
	_look(SPEED_TRAP, line)
	_look_left = maxf(_look_left, LOOK_HOLD)
	if best:
		view.feed.jolt()


## Takes the close look down once nothing has held it up for long enough.
func _step_look(delta: float) -> void:
	if view == null or dyno.held != null:
		return
	_look_left -= delta
	if _look_left <= 0.0:
		view.close()
		view = null


## The dial: its face, rim and ticks, the needle and the tell-tale on their pivots.
func _dial(board: Node3D) -> void:
	var surfaces := match_node.arena.surfaces
	var rim := _disc(DIAL + 0.04, surfaces.painted(RIM_INK), 0.005)
	var disc := _disc(DIAL, surfaces.marking(DIAL_INK), 0.012)
	for made: MeshInstance3D in [rim, disc]:
		made.position += Vector3(DIAL_AT.x, DIAL_AT.y, 0.0)
		board.add_child(made)
	var ink := surfaces.painted(RIM_INK)
	for i: int in TICKS:
		var angle := SWEEP_FROM - SWEEP * float(i) / (TICKS - 1)
		var out := Vector2(cos(angle), sin(angle))
		var long := 0.09 if i % 5 == 0 else 0.05
		var tick := _flat(
			Vector2(long, 0.018), ink, DIAL_AT + out * (DIAL - 0.03 - long * 0.5), 0.02
		)
		tick.rotation.z = angle
		board.add_child(tick)
	_telltale = _pointer(board, surfaces.painted(TELLTALE_INK), 0.012, 0.024)
	_needle = _pointer(board, surfaces.painted(NEEDLE_INK), 0.028, 0.03)
	var cap := _disc(0.05, ink, 0.034)
	cap.position += Vector3(DIAL_AT.x, DIAL_AT.y, 0.0)
	board.add_child(cap)


func _pointer(board: Node3D, skin: Material, wide: float, out: float) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = Vector3(DIAL_AT.x, DIAL_AT.y, 0.0)
	board.add_child(pivot)
	var long := DIAL - 0.06
	pivot.add_child(_flat(Vector2(long, wide), skin, Vector2(long * 0.5 - 0.04, 0.0), out))
	pivot.rotation.z = SWEEP_FROM
	return pivot


## The digits: three on each row beside the dial, the drift's with a point before its last.
func _digits(board: Node3D) -> void:
	_bars = SegmentDigits.bars(7 * 3 * ROW_WORDS.size() + 1)
	var segments := MultiMeshInstance3D.new()
	segments.name = "Segments"
	segments.multimesh = _bars
	segments.material_override = SegmentDigits.look(DARK)
	segments.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	board.add_child(segments)
	var first := 0
	for i: int in ROW_WORDS.size():
		_rows.append(_three(Vector2(ROWS_AT.x, ROWS_AT.y - ROW_GAP * i), first))
		first += 21
	var drift := Vector2(ROWS_AT.x, ROWS_AT.y - ROW_GAP * DRIFT_ROW)
	var point := drift + Vector2(SPACING * 0.5, -DIGIT.y * 0.5)
	_point = first
	SegmentDigits.bar(_bars, _point, point, Vector2(SEGMENT, SEGMENT), LIT)


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
	_step_look(delta)


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
	# The drift in tenths, a nought before the point under a second.
	var tenths := mini(roundi(drift * 10.0), 999)
	var shown: Array[String] = [
		"%3d" % _shown_speed(dyno.speed, unit),
		_three_of(trap.last, unit),
		_three_of(trap.best, unit),
		"%2d%d" % [floori(tenths / 10.0), tenths % 10] if drift > 0.0 else "   ",
	]
	var all := "".join(shown)
	if all == _shown:
		return
	_shown = all
	for i: int in _rows.size():
		SegmentDigits.show(_bars, _rows[i], shown[i], LIT)
	# Its point lit with it, and dark with no drift to show.
	_bars.set_instance_custom_data(_point, Color(1.0 if drift > 0.0 else 0.0, 0.0, 0.0))


static func _three_of(speed: float, unit: String) -> String:
	return "%3d" % mini(_shown_speed(speed, unit), 999) if speed > 0.0 else "   "


## [param text] on the face, its middle at [param at], its capitals [param tall] high in
## [param ink].
func _words(board: Node3D, text: String, at: Vector2, tall: float, ink: Color) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font = Type.mark_font()
	label.font_size = WORDS_SIZE
	label.outline_size = 0
	label.pixel_size = tall / (WORDS_SIZE * Type.CAP_HEIGHT)
	label.modulate = ink
	label.position = Vector3(at.x, at.y, 0.03)
	board.add_child(label)
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
