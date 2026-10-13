class_name AchievementRow
extends Control
## One achievement in the list of GAME.md 8.10, a row of the collector's case: its chip or its pin
## set into a round of the felt at the left, and beside it a label of the house's paper with its
## name, what it asks, and at the right the day it was earned, or how far along it is, a little road
## filling in gold with its count, or nothing for a moment that happens or does not. Earned, its
## chip shines and its paper is bright; not yet, its chip is gray and its paper dimmer. A hidden one
## says only that it is, on Kit's taped scrap. Under the cursor it wears the cursor's frame and its
## chip turns over once; it wears the NEW tag until the cursor has been on it.

## The cursor has come to it.
signal looked_at(row: AchievementRow)

## How tall a row is, how big its chip and the round it is set in, and the room round them.
const TALL := 96.0
const CHIP := 66.0
const ROUND := 40.0
const ROOM := 12.0
## How wide the right end is for the day or the bar, and the narrowest the label goes before that
## end is left out for the words.
const END_WIDE := 190.0
const NARROW := 520.0
## The felt the round is pressed into, and the label's notches.
const RECESS := Color("#1d3d2d")
const NOTCH := 7.0
## What a hidden one says, and what a row earned says over its day.
const HIDDEN := "Hidden achievement"
const HIDDEN_LINE := "Keep playing to reveal it."
const EARNED := "EARNED"
const MONTHS: Array[String] = [
	"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
]
## How long the chip takes to turn over under the cursor.
const TURN := 0.45

var achievement: Achievement
var look := AchievementArt.Look.LOCKED
## When it was earned, seconds since the Unix epoch, 0 for not yet; and how far along its bar is.
var earned_at := 0
var come := Vector2i.ZERO

var _frame := FocusGlide.look()
var _chip: AchievementArt.Picture
var _tag: Control
var _turning := 0.0


## The row of [param shown] for [param profile].
static func of(shown: Achievement, profile: Profile) -> AchievementRow:
	var row := AchievementRow.new()
	row.name = String(shown.id)
	row.achievement = shown
	row.look = AchievementArt.look_of(shown, profile)
	row.earned_at = profile.achievements.when(shown.id)
	row.come = Achievements.progress(profile, shown) if row.earned_at == 0 else Vector2i.ZERO
	row.set_fresh(profile.achievements.is_fresh(shown.id))
	return row


func _init() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_PASS
	custom_minimum_size.y = TALL
	add_to_group(FocusGlide.GROUP)


func _ready() -> void:
	_chip = AchievementArt.picture(achievement, look, CHIP)
	add_child(_chip)
	move_child(_chip, 0)
	focus_entered.connect(_on_focus.bind(true))
	focus_exited.connect(_on_focus.bind(false))
	mouse_entered.connect(_on_mouse_entered)
	resized.connect(_place)
	_place()
	set_process(false)


func _on_mouse_entered() -> void:
	if not TouchInput.enabled:
		grab_focus()


func _on_focus(on: bool) -> void:
	queue_redraw()
	if on:
		_turning = 0.0
		set_process(true)
		looked_at.emit(self)


## The chip turning over once under the cursor, as a coin turned in the fingers.
func _process(delta: float) -> void:
	_turning += delta
	var turned := clampf(_turning / TURN, 0.0, 1.0)
	_chip.spin = ease(turned, -1.6) * TAU
	if turned >= 1.0:
		_chip.spin = 0.0
		set_process(false)


func _place() -> void:
	if _chip != null:
		_chip.position = Vector2(ROOM + ROUND - CHIP * 0.5, (size.y - CHIP) * 0.5)


## Whether it wears the NEW tag, see [method AchievementState.is_fresh].
func set_fresh(on: bool) -> void:
	if on == (_tag != null):
		return
	if not on:
		_tag.queue_free()
		_tag = null
		return
	_tag = CatalogCell.new_tag()
	add_child(_tag)


func is_fresh() -> bool:
	return _tag != null


func _draw() -> void:
	var middle := Vector2(ROOM + ROUND, size.y * 0.5)
	# The round pressed into the felt, darker at its top where the light does not reach.
	draw_circle(middle, ROUND, RECESS, true, -1.0, true)
	draw_arc(middle, ROUND - 1.5, PI * 1.1, PI * 1.9, 24, Color(0.0, 0.0, 0.0, 0.35), 3.0, true)
	var left := ROOM * 2.0 + ROUND * 2.0
	var label := Rect2(Vector2(left, 8.0), Vector2(size.x - left - ROOM, size.y - 16.0))
	var earned := look == AchievementArt.Look.EARNED
	var paper := HouseTheme.PAPER if earned else HouseTheme.PAPER_LOW
	var style := TicketStyle.cut(paper, NOTCH, 0.0, 0.0)
	draw_style_box(style, label)
	if has_focus():
		draw_style_box(_frame, label.grow(4.0))
	var hidden := look == AchievementArt.Look.HIDDEN
	var name := HIDDEN if hidden else achievement.title
	var line := HIDDEN_LINE if hidden else achievement.objective
	var narrow := label.size.x < NARROW
	var end := 0.0 if narrow or hidden or (earned_at == 0 and come.y <= 0) else END_WIDE
	var words_left := label.position.x + 18.0
	var words_wide := label.size.x - 36.0 - end
	var title_size := Type.LARGE - 2
	var top := label.position.y + 12.0 + Type.display_font().get_ascent(title_size)
	draw_string(
		Type.display_font(),
		Vector2(words_left, top),
		name,
		HORIZONTAL_ALIGNMENT_LEFT,
		words_wide,
		title_size,
		HouseTheme.INK if earned or hidden else HouseTheme.INK_FAINT
	)
	draw_multiline_string(
		Type.TEXT,
		Vector2(words_left, top + 22.0),
		line,
		HORIZONTAL_ALIGNMENT_LEFT,
		words_wide,
		Type.SMALL + 1,
		2,
		HouseTheme.INK_FAINT
	)
	if end > 0.0:
		_draw_end(
			Rect2(Vector2(label.end.x - end - 12.0, label.position.y), Vector2(end, label.size.y))
		)


## The right end of the label: the day it was earned under EARNED, or the bar and its count.
func _draw_end(room: Rect2) -> void:
	var middle := room.position.y + room.size.y * 0.5
	if earned_at > 0:
		# Stamped EARNED in the rubber stamp's red, a little askew and a little short of solid, the
		# day written in under it.
		var at := Vector2(room.end.x - 66.0, middle - 8.0)
		var turn := -0.07 - 0.05 * float(hash(achievement.id) % 3)
		draw_set_transform(at, turn, Vector2.ONE)
		var box := Rect2(Vector2(-58.0, -15.0), Vector2(116.0, 30.0))
		draw_rect(box, Color(HouseTheme.STAMP_RED, 0.85), false, 2.4)
		draw_rect(box.grow(-4.0), Color(HouseTheme.STAMP_RED, 0.55), false, 1.0)
		draw_string(
			Type.display_font(),
			Vector2(-58.0, 8.0),
			EARNED,
			HORIZONTAL_ALIGNMENT_CENTER,
			116.0,
			21,
			Color(HouseTheme.STAMP_RED, 0.85)
		)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_string(
			Type.STRONG,
			Vector2(room.position.x, middle + 26.0),
			day_of(earned_at),
			HORIZONTAL_ALIGNMENT_RIGHT,
			room.size.x - 8.0,
			Type.SMALL,
			HouseTheme.INK_FAINT
		)
		return
	var share := float(come.x) / float(maxi(come.y, 1))
	var from := Vector2(room.position.x, middle - 4.0)
	PinnedNote.draw_road(self, from, from + Vector2(room.size.x - 70.0, 0.0), share, 6.0)
	draw_string(
		Type.STRONG,
		Vector2(room.end.x - 62.0, middle + 2.0),
		"%d / %d" % [come.x, come.y],
		HORIZONTAL_ALIGNMENT_RIGHT,
		62.0,
		Type.LABEL,
		HouseTheme.INK
	)


## The day [param when] fell on here, as a slip prints it: Oct 13, 2026.
static func day_of(when: int) -> String:
	var bias := int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	var date := Time.get_date_dict_from_unix_time(when + bias)
	return "%s %d, %d" % [MONTHS[clampi(int(date["month"]) - 1, 0, 11)], date["day"], date["year"]]
