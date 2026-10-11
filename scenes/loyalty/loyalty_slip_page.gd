class_name LoyaltySlipPage
extends VBoxContainer
## The loyalty program's page of the payout slip, GAME.md 8.9: after the map's and the run's,
## headed with the program's name by the story's stage, each profile at this machine that won a bet
## in the map or came nearer one, under its name: a line for each bet won, stamped, with what it
## paid, and the open bets come nearest, with their bars. Printed by the House, so it lists the
## House's bets alone: a bet won off the books is on Kit's scrap, taped over the slip, see
## [method tape_onto]. A map with nothing in it for anybody has no page. See [LoyaltyRecord].

const INK := HouseTheme.INK
const FAINT := HouseTheme.INK_FAINT
const LINE_TALL := 62.0
const PICTURE := 34.0
const NEAR_TALL := 30.0
const STAMP_INK := Color(0.8, 0.17, 0.14, 0.85)
## How big the pin at the end of a near line is.
const PIN_SIDE := 30.0


## One bet won, a line of the page: its picture, its name and under it what it paid, what the
## House calls paying it beside them, and the stamp.
class WonLine:
	extends Control

	var landmark: LoyaltyLandmark
	var stage := 0

	func _init() -> void:
		custom_minimum_size.y = LoyaltySlipPage.LINE_TALL
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var picture := Rect2(
			Vector2(0.0, (size.y - LoyaltySlipPage.PICTURE) * 0.5),
			Vector2.ONE * LoyaltySlipPage.PICTURE
		)
		LoyaltyArt.draw_reward(self, picture, landmark, LoyaltySlipPage.INK)
		var left := picture.end.x + 12.0
		var base := size.y * 0.5 - 2.0
		draw_string(
			Type.STRONG,
			Vector2(left, base),
			landmark.title,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			20,
			LoyaltySlipPage.INK
		)
		var named := (
			Type.STRONG.get_string_size(landmark.title, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
		)
		var paid := Loyalty.reward_words(landmark, stage)
		var paid_wide := (
			Type.micro_font().get_string_size(paid, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		)
		var right := size.x - 96.0
		# Dotted leaders from the name across to what it paid.
		var x := left + named + 10.0
		while x < right - paid_wide - 10.0:
			draw_circle(Vector2(x, base - 4.0), 1.1, Color(LoyaltySlipPage.INK, 0.4))
			x += 7.0
		draw_string(
			Type.micro_font(),
			Vector2(right - paid_wide, base - 1.0),
			paid,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			11,
			LoyaltySlipPage.FAINT
		)
		# What it paid, by name, as the program's pane says it.
		draw_string(
			Type.TEXT,
			Vector2(left, base + 20.0),
			LoyaltySlipPage.paid_words(landmark),
			HORIZONTAL_ALIGNMENT_LEFT,
			right - left - 10.0,
			14,
			LoyaltySlipPage.FAINT
		)
		LoyaltyArt.stamp(
			self, Vector2(size.x - 40.0, size.y * 0.5), 19.0, LoyaltySlipPage.STAMP_INK
		)


## An open bet come nearer, a line under the won: its name, its bar and how far it has come, and
## at its end a pin, to pin it from the slip as from the program, GAME.md 8.9.
class NearLine:
	extends Control

	var landmark: LoyaltyLandmark
	var profile: Profile
	## The pin at the line's end, for the mouse, a finger and a pad's cursor, see [method
	## ResultsScreen._pin_by].
	var pin: Button

	func _init() -> void:
		custom_minimum_size.y = LoyaltySlipPage.NEAR_TALL
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		pin = Button.new()
		pin.name = "Pin"
		pin.flat = true
		pin.focus_mode = Control.FOCUS_ALL
		pin.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		pin.custom_minimum_size = Vector2.ONE * LoyaltySlipPage.PIN_SIDE
		pin.size = pin.custom_minimum_size
		pin.draw.connect(_draw_pin)
		pin.focus_entered.connect(pin.queue_redraw)
		pin.focus_exited.connect(pin.queue_redraw)
		pin.pressed.connect(toggle)
		add_child(pin)
		resized.connect(_place_pin)

	## Pinned or unpinned from the slip: kept, every pinned line on the page and the strip by a
	## clock told.
	func toggle() -> void:
		if profile == null or not Loyalty.can_pin(profile, landmark.id):
			return
		var state := profile.loyalty
		state.pinned = &"" if state.pinned == landmark.id else landmark.id
		Audio.play_sfx(&"ui_click", MenuTheme.CLICK_DB, 0.0)
		if not Game.is_headless():
			Game.settings.save_to_disk()
		get_tree().call_group(PinnedNote.STRIPS, &"look")
		var page := get_parent()
		if page != null:
			for line: Node in page.get_children():
				if line is NearLine:
					(line as NearLine).pin.queue_redraw()
					(line as NearLine).pin.tooltip_text = (line as NearLine).pin_words()

	## Whether this line's bet is the one pinned.
	func pinned() -> bool:
		return profile != null and profile.loyalty.pinned == landmark.id

	## What the pin says to a mouse over it.
	func pin_words() -> String:
		return LoyaltyPane.PINNED if pinned() else LoyaltyPane.PIN

	func _place_pin() -> void:
		pin.position = Vector2(size.x - pin.size.x, (size.y - pin.size.y) * 0.5)
		pin.visible = profile != null and Loyalty.can_pin(profile, landmark.id)
		pin.tooltip_text = pin_words()

	## The pin drawn upright on its button: full while pinned, faint while not, and a shade
	## brighter under the mouse or the cursor, which marks it as it marks a button.
	func _draw_pin() -> void:
		var side := pin.size.y
		var faint := 0.5 + (0.3 if pin.is_hovered() or pin.has_focus() else 0.0)
		pin.modulate = Color(1.0, 1.0, 1.0, 1.0 if pinned() else faint)
		LoyaltyArt.draw_pin(pin, Vector2(side * 0.35, side * 0.92), side * 0.85)
		if pin.has_focus():
			FocusMark.draw_on(pin, Rect2(Vector2.ZERO, pin.size), 6.0, SIDE_LEFT)

	func _draw() -> void:
		var base := size.y * 0.5 + 6.0
		draw_string(
			Type.TEXT,
			Vector2(0.0, base),
			landmark.title,
			HORIZONTAL_ALIGNMENT_LEFT,
			size.x * 0.4,
			17,
			LoyaltySlipPage.INK
		)
		var come := Loyalty.progress(profile, landmark)
		var track := Rect2(Vector2(size.x * 0.42, size.y * 0.5 - 3.0), Vector2(size.x * 0.34, 6.0))
		draw_rect(track, Color(LoyaltySlipPage.INK, 0.15))
		if come.y > 0.0:
			draw_rect(
				Rect2(track.position, Vector2(track.size.x * come.x / come.y, track.size.y)),
				LoyaltySlipPage.INK
			)
		var said := Loyalty.progress_text(profile, landmark)
		draw_string(
			Type.STRONG,
			Vector2(track.end.x + 12.0, base),
			said,
			HORIZONTAL_ALIGNMENT_LEFT,
			size.x - track.end.x - 18.0 - LoyaltySlipPage.PIN_SIDE,
			15,
			LoyaltySlipPage.FAINT
		)


## Kit's scrap: torn off a sheet of graph paper, taped on over the House's slip a little askew, the
## bets won off the books written on it in pencil, STORY.md 6.6b.
class KitScrap:
	extends Control

	const WIDE := 230.0
	const GRAPH := Color(0.42, 0.62, 0.82, 0.32)
	const TAPE := Color(0.95, 0.9, 0.7, 0.55)
	## The room under the lines for Kit's initial, as the notes are signed.
	const SIGNED := 26.0
	const SIGNATURE := "—K."
	var lines := PackedStringArray()

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func tall() -> float:
		return 30.0 + lines.size() * 30.0 + SIGNED

	func _draw() -> void:
		var high := tall()
		var edge := PackedVector2Array()
		edge.append(Vector2(0.0, 2.0))
		for i: int in 15:
			edge.append(Vector2(WIDE * (i + 1) / 15.0, 2.0 + (3.0 if i % 2 == 0 else 0.0)))
		edge.append(Vector2(WIDE - 2.0, high))
		for i: int in range(14, -1, -1):
			edge.append(
				Vector2(WIDE * i / 15.0, high - (4.0 if i % 2 == 1 else 0.0) - float(i % 3))
			)
		var shadow := PackedVector2Array()
		for point: Vector2 in edge:
			shadow.append(point + Vector2(3.0, 4.0))
		draw_colored_polygon(shadow, Color(0.0, 0.0, 0.0, 0.18))
		draw_colored_polygon(edge, Color(0.97, 0.97, 0.94))
		var x := 10.0
		while x < WIDE - 4.0:
			draw_line(Vector2(x, 4.0), Vector2(x, high - 4.0), GRAPH, 1.0)
			x += 12.0
		var y := 10.0
		while y < high - 4.0:
			draw_line(Vector2(2.0, y), Vector2(WIDE - 2.0, y), GRAPH, 1.0)
			y += 12.0
		for i: int in lines.size():
			var at := Vector2(18.0, 38.0 + i * 30.0)
			draw_string(
				LoyaltyArt.HAND,
				at,
				lines[i],
				HORIZONTAL_ALIGNMENT_LEFT,
				WIDE - 30.0,
				26,
				NotePage.PENCIL
			)
			NotePage.new_mark(self, at + Vector2(-9.0, -9.0), 0.55)
		draw_string(
			LoyaltyArt.HAND,
			Vector2(18.0, 34.0 + lines.size() * 30.0 + SIGNED * 0.5),
			SIGNATURE,
			HORIZONTAL_ALIGNMENT_RIGHT,
			WIDE - 44.0,
			24,
			NotePage.PENCIL
		)
		for corner: Vector2 in [Vector2(-10.0, -4.0), Vector2(WIDE - 40.0, high - 12.0)]:
			draw_set_transform(corner, 0.5 if corner.x < 0.0 else -0.45, Vector2.ONE)
			draw_rect(Rect2(Vector2.ZERO, Vector2(58.0, 18.0)), TAPE)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


var heading: Label
var caption: Label
var rows: VBoxContainer


static func create() -> LoyaltySlipPage:
	var page := LoyaltySlipPage.new()
	page._build()
	return page


func _build() -> void:
	name = "LoyaltyPage"
	add_theme_constant_override("separation", 14)
	heading = MenuTheme.title("", Type.TITLE)
	heading.name = "Heading"
	heading.add_theme_color_override("font_color", INK)
	heading.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.0))
	add_child(heading)
	caption = MenuTheme.subtitle("", Type.LABEL)
	caption.name = "Caption"
	caption.add_theme_color_override("font_color", FAINT)
	add_child(caption)
	var band := ColorRect.new()
	band.color = HouseTheme.FOIL
	band.custom_minimum_size = Vector2(0.0, 3.0)
	add_child(band)
	rows = VBoxContainer.new()
	rows.name = "Rows"
	rows.add_theme_constant_override("separation", 4)
	add_child(rows)


## Fills the page from [param report], see [method LoyaltyRecord.report_of], headed with the
## program's name and its line as the profile playing's screens show them. False with nothing of
## the House's to print, which is no page.
func fill(report: Array[Dictionary]) -> bool:
	var profile := Game.settings.profile
	heading.text = LoyaltyDialog.program_name(profile)
	caption.text = LoyaltyDialog.program_line(profile)
	for child: Node in rows.get_children():
		rows.remove_child(child)
		child.free()
	var stage := Story.stage_here()
	var any := false
	for line: Dictionary in report:
		var won: Array = line["won"]
		var nearer: Array = line["nearer"]
		var laps: int = line.get("laps", 0)
		if won.is_empty() and nearer.is_empty() and laps <= 0:
			continue
		any = true
		var named := Label.new()
		named.text = str(line["name"])
		Type.strong(named, Type.LARGE, INK)
		rows.add_child(named)
		if laps > 0:
			var lap := Label.new()
			var profile_of: Profile = line["profile"]
			lap.text = StoryLines.SLIP_LAP % profile_of.loyalty.laps
			Type.strong(lap, Type.LARGE, LoyaltySlipPage.STAMP_INK)
			rows.add_child(lap)
		if not won.is_empty():
			rows.add_child(_small(StoryLines.SLIP_WON))
		for landmark: LoyaltyLandmark in won:
			var row := WonLine.new()
			row.landmark = landmark
			row.stage = stage
			rows.add_child(row)
		if not nearer.is_empty():
			rows.add_child(_small(StoryLines.SLIP_NEAREST))
		for landmark: LoyaltyLandmark in nearer:
			var near := NearLine.new()
			near.landmark = landmark
			near.profile = line["profile"]
			rows.add_child(near)
	return any


## The pins at the ends of the near lines that can be pressed, top to bottom, for a pad's cursor.
func pins() -> Array[Button]:
	var found: Array[Button] = []
	for line: Node in rows.get_children():
		if line is NearLine and (line as NearLine).pin.visible:
			found.append((line as NearLine).pin)
	return found


## What [param landmark] paid, in words, one after another, as the program's pane names each, see
## [method LoyaltyPane.pays_of]: the slip said only that a reward was issued, never which.
static func paid_words(landmark: LoyaltyLandmark) -> String:
	var said := PackedStringArray()
	for paid: Array in LoyaltyPane.pays_of(landmark):
		said.append(str(paid[0]))
	return "  ·  ".join(said)


func _small(words: String) -> Label:
	var small := Label.new()
	small.text = words.to_upper()
	Type.set_font(small, Type.micro_font(), 12)
	small.add_theme_color_override("font_color", FAINT)
	return small


## The bets won off the books in [param report], every profile's, as Kit writes them: their names.
static func kit_lines(report: Array[Dictionary]) -> PackedStringArray:
	var lines := PackedStringArray()
	for line: Dictionary in report:
		for landmark: LoyaltyLandmark in line["kit"]:
			lines.append(landmark.title)
	return lines


## Kit's scrap with [param lines] taped onto [param page], over its top right corner, a little
## askew, or [param at_foot] at its foot on the right, in room of its own, so it covers nothing of
## a page with a heading; any taped on it before taken off first. None for no lines.
static func tape_onto(page: Control, lines: PackedStringArray, at_foot := false) -> void:
	var old := page.get_node_or_null("Tape")
	if old != null:
		old.name = "TapeGone"
		(old as Control).hide()
		old.queue_free()
	if lines.is_empty():
		return
	# A strip of no height at the page's top, so the scrap lies over the page rather than taking
	# room in it.
	var tape := Control.new()
	tape.name = "Tape"
	tape.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(tape)
	var scrap := KitScrap.new()
	scrap.name = "Scrap"
	scrap.lines = lines
	scrap.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	if at_foot:
		# Under everything on the page, at its right, in a strip as tall as it is.
		tape.custom_minimum_size.y = scrap.tall() + 14.0
		scrap.offset_left = -KitScrap.WIDE - 12.0
		scrap.offset_right = -12.0
		scrap.offset_top = 8.0
		scrap.rotation = -0.035
	else:
		# Over the page's top right corner, clear of its heading in the middle.
		page.move_child(tape, 0)
		scrap.offset_left = -KitScrap.WIDE + 26.0
		scrap.offset_right = 26.0
		scrap.offset_top = 62.0
		scrap.rotation = 0.055
	scrap.offset_bottom = scrap.offset_top + scrap.tall()
	tape.add_child(scrap)
