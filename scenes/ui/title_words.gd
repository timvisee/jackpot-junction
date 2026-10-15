class_name TitleWords
extends RefCounted
## The words under the title's name, GAME.md 8.1a: the microprint between two rules of foil, and
## after the story's ending the House's status line in the tagline's place, STORY.md 8.6.

## How long the microprint's rules are.
const MICRO_RULE := 150.0
## The Operator's line after the ending, STORY.md 8.6: its size.
const STATUS_SIZE := Type.BODY


## After the ending, one line under the name in the Count Room's green, set as a terminal's, in the
## tagline's place, with a block cursor blinking after its end, held still for fewer flashes,
## STORY.md 8.6: the House's own room showing through the menu. The cursor blinks by fading rather
## than by going, so the line never moves.
static func status_line() -> HBoxContainer:
	var green: Color = (load("res://data/rooms/count_room.tres") as RoomLook).trim
	var row := HBoxContainer.new()
	row.name = "StatusLine"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 4)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var said := Label.new()
	said.text = StoryFill.fill(StoryLines.STATUS_LINE, Game.settings.profile)
	said.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Type.set_font(said, NotePage.TYPED, STATUS_SIZE)
	said.add_theme_color_override("font_color", green)
	row.add_child(said)
	# The block in a slot the line's height, from just under the top of the letters to a little under
	# their foot, level with the capitals rather than centered on the whole line.
	var font := NotePage.TYPED
	var slot := Control.new()
	slot.name = "Cursor"
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.custom_minimum_size = Vector2(STATUS_SIZE * 0.6, font.get_height(STATUS_SIZE))
	row.add_child(slot)
	var cursor := ColorRect.new()
	cursor.name = "Block"
	cursor.color = green
	cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cursor.position = Vector2(0.0, font.get_ascent(STATUS_SIZE) * 0.08)
	cursor.size = Vector2(
		STATUS_SIZE * 0.6,
		font.get_ascent(STATUS_SIZE) * 0.92 + font.get_descent(STATUS_SIZE) * 0.35
	)
	slot.add_child(cursor)
	if not Game.settings.flash_reduction:
		var blink := cursor.create_tween().set_loops()
		(
			blink
			. tween_callback(func() -> void: cursor.self_modulate.a = 1.0 - cursor.self_modulate.a)
			. set_delay(0.53)
		)
	return row


## A line of microprint between two short rules of foil, centered under the name.
static func microprint(words: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i: int in 3:
		if i == 1:
			var said := Label.new()
			said.text = words
			said.uppercase = true
			Type.set_font(said, Type.micro_font(), 13)
			said.add_theme_color_override("font_color", Color(HouseTheme.FOIL, 0.8))
			row.add_child(said)
			continue
		var rule := ColorRect.new()
		rule.color = Color(HouseTheme.FOIL, 0.45)
		rule.custom_minimum_size = Vector2(MICRO_RULE, 1.0)
		rule.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(rule)
	return row
