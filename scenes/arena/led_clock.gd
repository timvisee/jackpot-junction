class_name LedClock
extends Node3D
## The match clock on a hoarding over the crowd, GAME.md 8.1: four seven-segment digits and a
## colon on a dark board, the way a scoreboard in a real hall keeps time. The HUD has the same
## clock in the corner, but a room with a clock in it is a room, and a player watching the table
## rather than the corner still knows how long is left.
##
## Scenery: it reads the match and decides nothing. A room with no clock to keep, such as the
## garage, has no board.

## The digits and the gap between them, in meters.
const DIGIT := Vector2(0.5, 0.96)
const SEGMENT := 0.11
const SPACING := 0.69
## The extra gap the colon is given, between the minutes and the seconds.
const COLON := 0.28
## Amber while the match runs and red during Last Call, GAME.md 8.3, with the unlit segments
## showing faintly so the display reads as a board with segments rather than as floating bars.
const LIT := Color(1.0, 0.72, 0.18)
const LIT_LAST_CALL := Color(1.0, 0.27, 0.27)
const DARK := Color(0.14, 0.12, 0.1)
## The board says a word instead of the time at the two moments it has something better to say
## than a number, GAME.md 8.1: the start and the finish. Green for the drop, the way the gantry
## goes green, and the flash of sudden death at this rate.
const GO := Color(0.42, 0.95, 0.5)
const WORD_SIZE := 0.62
const CAPTION_SIZE := 0.34
const CAPTION_INK := Color(0.75, 0.78, 0.85)
const GO_TIME := 1.4
const FLASH := 0.55
## How far out past the far wall the board stands, and how far along that edge from the middle:
## off to one side, since the middle of that edge is the DJ booth's and the other side is where
## the tanks of 8.1 stand.
const STANDOFF := 3.2
const OFFSET := 0.3

## Which segments each numeral lights, named the way a datasheet names them: a across the top,
## then round clockwise to f, and g across the middle.
const NUMERALS: Dictionary[String, String] = {
	"0": "abcdef",
	"1": "bc",
	"2": "abged",
	"3": "abgcd",
	"4": "fgbc",
	"5": "afgcd",
	"6": "afgedc",
	"7": "abc",
	"8": "abcdefg",
	"9": "abcdfg",
}

var match_node: Match

## One entry per digit: segment name to the mesh that draws it.
var _digits: Array[Dictionary] = []
var _board: Billboard
var _colon: Array[MeshInstance3D] = []
var _shown := ""
## The line the board reads when it has a word rather than a time on it, and the smaller line
## above it that says which of the two you are looking at.
var _word: Label3D
var _caption: Label3D
var _now := 0.0
var _go_left := 0.0
var _was_state := Match.State.LOBBY


## Hangs a clock off [param for_match], to be kept by its own clock.
static func add_to(for_match: Match) -> LedClock:
	var clock := LedClock.new()
	clock.name = "LedClock"
	clock.match_node = for_match
	for_match.add_child(clock)
	return clock


## Whether this room has a clock worth putting on a wall.
func wanted() -> bool:
	return match_node != null and match_node.rules != null and match_node.rules.timed


func _process(delta: float) -> void:
	visible = wanted()
	if not visible:
		return
	if _board == null:
		_build()
	_now += delta
	_step_state(delta)
	var word := _word_now()
	if word.is_empty():
		_say("", "TIME", LIT)
		_show(_clock_text(), _last_call())
	else:
		_say(word, _caption_now(), _word_color())


## The drop is a moment rather than a state, so it is caught as the countdown hands over to the
## match and held on the board for a second and a bit after it.
func _step_state(delta: float) -> void:
	if match_node.state != _was_state:
		if _was_state == Match.State.COUNTDOWN and match_node.state != Match.State.COUNTDOWN:
			_go_left = GO_TIME
		_was_state = match_node.state
	_go_left = maxf(_go_left - delta, 0.0)


## The word the board has in place of the time, or nothing while it is keeping the clock. The
## lamps of the start gantry are what READY and SET follow, GAME.md 8.3, so the board and the
## rack are one countdown rather than two.
func _word_now() -> String:
	match match_node.state:
		Match.State.COUNTDOWN:
			return "READY" if match_node.countdown_lamps() <= 1 else "SET"
		Match.State.OVERTIME:
			return "OVERTIME"
		Match.State.RESULTS:
			return _winner()
		_:
			return "GO!" if _go_left > 0.0 else ""


## The smaller line above it, which says what the word is about.
func _caption_now() -> String:
	match match_node.state:
		Match.State.COUNTDOWN:
			return "START"
		Match.State.OVERTIME:
			return "SUDDEN DEATH"
		Match.State.RESULTS:
			return "CHAMPION" if _champion() != null else "WINNER"
		_:
			return "START"


## Amber to hold the field, green for the drop, the winner's own color at the whistle, and red
## for sudden death, which flashes. The flash stands still for anybody who has asked for fewer
## of them, GAME.md 8.5.
func _word_color() -> Color:
	if match_node.state == Match.State.RESULTS:
		var champion := _champion()
		return champion.color() if champion != null else match_node.standings()[0].color()
	if match_node.state == Match.State.OVERTIME:
		var lit := Game.settings.flash_reduction or fmod(_now, FLASH) < FLASH * 0.5
		return LIT_LAST_CALL if lit else LIT_LAST_CALL.darkened(0.75)
	return GO if _go_left > 0.0 else LIT


## Whoever won it, for the board to name. A player who set no name still has one to be called
## by, the same one the standings and the podium use.
func _winner() -> String:
	var champion := _champion()
	if champion != null:
		return champion.display_name()
	return match_node.standings()[0].display_name()


## Whoever won the Grand Prix this was the last map of, GAME.md 9.7, once the run's podium is up,
## or null. Until then the board names the last map's winner like any map's: the last map has its
## own podium first. From then on it names the run's, which is what everybody has been playing.
func _champion() -> PlayerSlot:
	var rules := match_node.rules
	var run := Game.grand_prix
	if rules.rounds <= 0 or rules.round < rules.rounds or run == null or not run.revealed:
		return null
	if run.scored_round < rules.round - 1:
		return null
	return run.standings(match_node.slots)[0]


## Puts a word on the board, or takes it off again and gives the digits back. Refitted every time
## the words change, since how big a line can be drawn depends on how long it is.
func _say(word: String, caption: String, color: Color) -> void:
	var showing := not word.is_empty()
	for digit: Dictionary in _digits:
		for name: String in digit:
			(digit[name] as MeshInstance3D).visible = not showing
	for dot: MeshInstance3D in _colon:
		dot.visible = not showing
	_word.visible = showing
	_word.modulate = color
	if showing and _word.text != word:
		_word.text = word
		_word.pixel_size = _board.fitted(word, WORD_SIZE) / float(Billboard.FONT_SIZE)
	if _caption.text != caption:
		_caption.text = caption
		_caption.pixel_size = _board.fitted(caption, CAPTION_SIZE) / float(Billboard.FONT_SIZE)


## How hard this room drives its signs, GAME.md 8.1: a display in a dark hall is the brightest
## thing in it and a display in daylight is a display.
func _neon() -> float:
	return match_node.arena.room.neon if match_node.arena != null else 1.0


## The time left as mm:ss, which is what the four digits have room for.
func _clock_text() -> String:
	var left := maxi(int(ceil(match_node.time_left)), 0)
	return "%02d%02d" % [mini(left / 60, 99), left % 60]


func _last_call() -> bool:
	return match_node.state == Match.State.LAST_CALL


## Lights the segments the numerals want and leaves the rest showing dark.
func _show(text: String, urgent: bool) -> void:
	var color := LIT_LAST_CALL if urgent else LIT
	if text == _shown and not urgent:
		return
	_shown = text
	for i: int in _digits.size():
		var on: String = NUMERALS.get(text.substr(i, 1), "") as String
		for name: String in _digits[i]:
			var segment: MeshInstance3D = _digits[i][name]
			var material := segment.material_override as StandardMaterial3D
			var lit := on.contains(name)
			material.albedo_color = color if lit else DARK
			material.emission = color
			material.emission_energy_multiplier = 1.6 * _neon() if lit else 0.0
	for dot: MeshInstance3D in _colon:
		var material := dot.material_override as StandardMaterial3D
		material.albedo_color = color
		material.emission = color


## The board, its legs and the display on it. Built once the match is running, since where it
## stands comes from how big the table is.
func _build() -> void:
	var size := match_node.arena.world_size() if match_node.arena != null else Vector2(40.0, 22.5)
	var along := size.x * OFFSET * 0.5
	var at := Vector3(along, 0.0, -(size.y * 0.5 + STANDOFF))
	_board = Billboard.add_to(self, at, Vector3.ZERO, match_node.arena.room)
	_board.name = "ClockBoard"
	var run := SPACING * 4.0 + COLON
	var left := -run * 0.5 + SPACING * 0.5
	for i: int in 4:
		var x := left + i * SPACING + (COLON if i >= 2 else 0.0)
		_digits.append(_digit(Vector2(x, -0.18)))
	for high: bool in [true, false]:
		var dot := _bar(Vector2(SEGMENT, SEGMENT))
		dot.position = Vector3(
			left + SPACING * 1.5 + COLON * 0.5, -0.18 + (0.24 if high else -0.24), 0.04
		)
		_board.face.add_child(dot)
		_colon.append(dot)
	_caption = _board.words("TIME", Vector2(0.0, 0.74), CAPTION_SIZE, CAPTION_INK)
	_word = _board.words("", Vector2(0.0, -0.2), WORD_SIZE, LIT)
	_word.visible = false
	# Nobody stands in front of a board put up to be read.
	if match_node.arena != null and match_node.arena.crowd != null:
		var keep := Rect2(at.x - Billboard.WIDTH * 0.5, at.z - 1.6, Billboard.WIDTH, 3.2)
		match_node.arena.crowd.keep_clear(keep)


## One numeral: seven bars laid out the way a segment display lays them out.
func _digit(at: Vector2) -> Dictionary:
	var half := Vector2(DIGIT.x * 0.5, DIGIT.y * 0.5)
	var across := Vector2(DIGIT.x - SEGMENT, SEGMENT)
	var upright := Vector2(SEGMENT, DIGIT.y * 0.5 - SEGMENT)
	var places: Dictionary[String, Array] = {
		"a": [Vector2(0.0, half.y), across],
		"b": [Vector2(half.x, half.y * 0.5), upright],
		"c": [Vector2(half.x, -half.y * 0.5), upright],
		"d": [Vector2(0.0, -half.y), across],
		"e": [Vector2(-half.x, -half.y * 0.5), upright],
		"f": [Vector2(-half.x, half.y * 0.5), upright],
		"g": [Vector2(0.0, 0.0), across],
	}
	var segments: Dictionary[String, MeshInstance3D] = {}
	for name: String in places:
		var place: Array = places[name]
		var bar := _bar(place[1] as Vector2)
		bar.position = Vector3(at.x + (place[0] as Vector2).x, at.y + (place[0] as Vector2).y, 0.04)
		_board.face.add_child(bar)
		segments[name] = bar
	return segments


## One segment: a flat bar on the face, dark until it is lit.
func _bar(size: Vector2) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(size.x, size.y, 0.05)
	var node := MeshInstance3D.new()
	node.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = DARK
	material.emission_enabled = true
	material.emission = LIT
	material.emission_energy_multiplier = 0.0
	node.material_override = material
	return node
