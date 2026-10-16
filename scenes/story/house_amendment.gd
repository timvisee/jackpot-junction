class_name HouseAmendment
extends Control
## An amendment to the terms at the Final Hand, STORY.md 8.2: each of the House's acts announced
## over the HUD where the announcer's plate goes, a typed slip of the House's paper, AMENDMENT and
## its number over its line and PLAYING ON ACCEPTS THE CHANGE. under it. A few seconds later, the
## candidate's kart still driving, TERMS ACCEPTED is stamped across it in the House's gold, and it
## is counted where it is due, see [HouseWatch]. Then it goes.

signal accepted

const SLIP := Vector2(660.0, 156.0)
const ROOM := 30.0
## How long it takes to come in, how long it is up before the stamp comes down, how long the stamp
## takes to land, how long it stays up after, and how long it takes to go.
const IN := 0.3
const READ := 3.0
const LAND := 0.18
const AFTER := 1.8
const OUT := 0.5
const STAMP_TILT := -0.13

var number := 1
var words := ""
## Whether the stamp may come down: the candidate's kart still driving, as [HouseWatch] says.
var driving := true

var _age := 0.0
var _stamped_at := -1.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Amendment [param of_number] over [param hud], where the announcer's plate goes.
static func over(hud: Node, of_number: int) -> HouseAmendment:
	var notice := HouseAmendment.new()
	notice.name = "HouseAmendment"
	notice.number = of_number
	notice.words = StoryLines.AMENDMENTS[clampi(of_number - 1, 0, StoryLines.AMENDMENTS.size() - 1)]
	notice.custom_minimum_size = SLIP
	notice.set_anchors_preset(Control.PRESET_CENTER)
	notice.offset_left = -SLIP.x * 0.5
	notice.offset_right = SLIP.x * 0.5
	notice.offset_top = MatchHud.CALL_DROP - SLIP.y * 0.5
	notice.offset_bottom = MatchHud.CALL_DROP + SLIP.y * 0.5
	notice.pivot_offset = SLIP * 0.5
	var call := hud.get_node_or_null("Call") as CallBanner
	if call != null:
		call.put_away()
	hud.add_child(notice)
	ScreenReader.say(
		notice,
		ScreenReader.line(
			[StoryLines.AMENDMENT % of_number, notice.words, StoryLines.AMENDMENT_UNDER]
		)
	)
	return notice


## Whether the stamp has come down.
func is_accepted() -> bool:
	return _stamped_at >= 0.0


func _process(delta: float) -> void:
	_age += delta
	if _stamped_at < 0.0 and _age >= IN + READ and driving:
		_stamped_at = _age
		accepted.emit()
		ScreenReader.say(self, StoryLines.TERMS_ACCEPTED)
	var gone := _stamped_at >= 0.0 and _age > _stamped_at + LAND + AFTER
	var fade := 1.0
	if gone:
		fade = 1.0 - (_age - _stamped_at - LAND - AFTER) / OUT
		if fade <= 0.0:
			queue_free()
			return
	modulate.a = clampf(_age / IN, 0.0, 1.0) * clampf(fade, 0.0, 1.0)
	scale = Vector2.ONE * lerpf(0.94, 1.0, clampf(_age / IN, 0.0, 1.0))
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2(5.0, 8.0), size), Color(0.0, 0.0, 0.0, 0.35))
	draw_rect(Rect2(Vector2.ZERO, size), HouseTheme.PAPER)
	draw_rect(Rect2(Vector2.ZERO, size), Color(HouseTheme.PAPER_LOW, 0.9), false, 2.0)
	for y: float in [12.0, 17.0]:
		draw_line(
			Vector2(ROOM, y),
			Vector2(size.x - ROOM, y),
			Color(HouseTheme.FOIL_LOW, 0.8),
			2.2 if y < 14.0 else 1.2
		)
	var typed := NotePage.TYPED
	var wide := size.x - ROOM * 2.0
	draw_string(
		Type.micro_font(),
		Vector2(ROOM, 44.0),
		StoryLines.AMENDMENT % number,
		HORIZONTAL_ALIGNMENT_CENTER,
		wide,
		15,
		HouseTheme.FOIL_LOW
	)
	draw_string(
		typed, Vector2(ROOM, 88.0), words, HORIZONTAL_ALIGNMENT_CENTER, wide, 26, HouseTheme.INK
	)
	draw_string(
		typed,
		Vector2(ROOM, 128.0),
		StoryLines.AMENDMENT_UNDER,
		HORIZONTAL_ALIGNMENT_CENTER,
		wide,
		16,
		HouseTheme.INK_FAINT
	)
	if _stamped_at >= 0.0:
		_draw_stamp(clampf((_age - _stamped_at) / LAND, 0.0, 1.0))


## TERMS ACCEPTED in the House's gold, a rubber stamp's box round it, slammed down across the slip
## at [param landed] of the way down.
func _draw_stamp(landed: float) -> void:
	var font := Type.display_font()
	var font_size := 34
	var said := StoryLines.TERMS_ACCEPTED
	var text := font.get_string_size(said, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var box := Vector2(text.x + 36.0, text.y + 14.0)
	var grow := lerpf(1.6, 1.0, ease(landed, 0.5))
	var ink := Color(ApprovedStamp.INK, ApprovedStamp.INK.a * landed)
	draw_set_transform(
		Vector2(size.x - box.x * 0.42, size.y - 18.0), STAMP_TILT, Vector2.ONE * grow
	)
	draw_rect(Rect2(-box * 0.5, box), Color(ink, ink.a * 0.12))
	draw_rect(Rect2(-box * 0.5, box), ink, false, 4.0)
	draw_rect(Rect2(-box * 0.5 + Vector2(6.0, 6.0), box - Vector2(12.0, 12.0)), ink, false, 1.6)
	draw_string(
		font,
		Vector2(-text.x * 0.5, font_size * 0.36),
		said,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		ink
	)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
