class_name StoryDebugTab
extends ScrollContainer
## The settings' last page in a debug build alone, GAME.md 8.5: where the profile playing is in the
## story of 8.7, STORY.md 5 and 7, and buttons that move it, each kept in the profile at once. For
## trying the story out; a released game has no such page. The README lists the command line's
## story arguments beside it.

const WIDTH := 900.0
const INK := Color(0.86, 0.86, 0.9)
const SIZE := 17
## How far one press of More time moves the clock.
const MORE := 600.0

var _settings: Settings
var _said: Label


static func make(settings: Settings) -> StoryDebugTab:
	var tab := StoryDebugTab.new()
	tab._settings = settings
	return tab


func _init() -> void:
	name = "Story"


func _ready() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var middle := CenterContainer.new()
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(middle)
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(WIDTH, 0.0)
	column.add_theme_constant_override("separation", 14)
	middle.add_child(column)
	column.add_child(
		MenuTheme.subtitle("Debug builds only. Every change is kept in the profile.", Type.LABEL)
	)
	_said = Label.new()
	_said.name = "Where"
	Type.set_font(_said, NotePage.TYPED, SIZE)
	_said.add_theme_color_override("font_color", INK)
	column.add_child(_said)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	column.add_child(grid)
	for way: Array in [
		["Get a license", get_license],
		["Stage -", stage_back],
		["Stage +", stage_on],
		["Ten minutes more", more_time],
		["Unlock all notes", every_note],
		["No notes", no_notes],
		["Every note unread", all_unread],
		["Final Hand due", final_hand_due],
		["End the story", end_story],
		["Start the story over", start_over],
	]:
		var button := MenuTheme.button(str(way[0]), Type.LABEL)
		button.name = str(way[0]).replace(" ", "").replace("-", "Back").replace("+", "On")
		button.custom_minimum_size.x = 280.0
		button.pressed.connect(func() -> void: (way[1] as Callable).call())
		grid.add_child(button)
	say()


func _story() -> StoryState:
	return _settings.profile.story


## Where the profile playing is, line by line.
func say() -> void:
	var profile := _settings.profile
	var story := _story()
	var stage := Story.stage_of(profile)
	var lines: Array[String] = []
	lines.append("Profile ........ %s" % profile.display_name())
	lines.append(
		(
			"License ........ %s"
			% (
				profile.license_number
				if Story.licensed(profile)
				else "none, the clock does not run"
			)
		)
	)
	lines.append("Story .......... %s" % ("on" if story.on else "off"))
	lines.append("Stage .......... %s (%d)" % [Story.NAMES[stage], stage])
	var next := (
		"Final Hand at %d min" % int(Story.FINAL_HAND_AT / 60.0)
		if stage >= Story.Stage.CANDIDATE
		else "next stage at %d min" % int(Story.STAGE_STARTS[stage + 1] / 60.0)
	)
	if stage == Story.Stage.OPERATOR:
		next = "ended %s" % story.final_hand
	lines.append(
		"Clock .......... %d min (%d s), %s" % [Story.minutes(profile), story.seconds, next]
	)
	lines.append(
		(
			"Notes .......... %d of %d found, %d read"
			% [story.notes.size(), Story.NOTE_COUNT, story.notes_read.size()]
		)
	)
	var coming := StoryNotes.next_of(story)
	if coming == 1:
		lines.append("Next note ...... 1, in quick match %d" % Story.FIRST_NOTE_MATCH)
	elif coming > 0:
		lines.append(
			(
				"Next note ...... %d, due at %d min"
				% [coming, int(StoryNotes.due_at(coming, story) / 60.0)]
			)
		)
	else:
		lines.append("Next note ...... none")
	var hand := "due" if Story.final_hand_due(profile) else "not yet"
	if story.ended():
		hand = "played %s" % story.final_hand
	lines.append("Final Hand ..... %s" % hand)
	lines.append(
		(
			"Counted ........ %d maps, %d quick matches, %d deaths, %d jokers, %d shifts"
			% [story.maps, story.quick_matches, story.deaths, story.jokers, story.shifts]
		)
	)
	_said.text = "\n".join(lines)


func _kept() -> void:
	_settings.save_to_disk()
	say()


func get_license() -> void:
	Story.hand_license(_settings)
	say()


## A stage back: the ending undone after it, or the clock to the start of the stage before.
func stage_back() -> void:
	var story := _story()
	var stage := Story.stage_of(_settings.profile)
	if story.ended():
		story.final_hand = ""
		story.evaluation = {}
		story.seconds = Story.FINAL_HAND_AT
	elif stage > Story.Stage.CUSTOMER:
		story.seconds = Story.STAGE_STARTS[stage - 1]
	_kept()


## A stage on: the clock to the start of the next, then to the Final Hand, then the ending.
func stage_on() -> void:
	var story := _story()
	var stage := Story.stage_of(_settings.profile)
	if stage < Story.Stage.CANDIDATE:
		story.seconds = Story.STAGE_STARTS[stage + 1]
	elif not story.ended() and story.seconds < Story.FINAL_HAND_AT:
		story.seconds = Story.FINAL_HAND_AT
	elif not story.ended():
		end_story()
		return
	_kept()


func more_time() -> void:
	_story().seconds += MORE
	_kept()


func every_note() -> void:
	Story.hand_notes(_settings)
	say()


func no_notes() -> void:
	var story := _story()
	story.notes = PackedInt32Array()
	story.notes_read = PackedInt32Array()
	story.note_waits = 0
	_kept()


func all_unread() -> void:
	_story().notes_read = PackedInt32Array()
	_kept()


func final_hand_due() -> void:
	var story := _story()
	story.final_hand = ""
	story.seconds = maxf(story.seconds, Story.FINAL_HAND_AT)
	_kept()


## The ending as if the stamp had come down today, without a Final Hand's evaluation to keep.
func end_story() -> void:
	var story := _story()
	story.seconds = maxf(story.seconds, Story.FINAL_HAND_AT)
	story.final_hand = LicenseCard.today()
	story.final_seconds = story.seconds
	story.evaluation = {"date": story.final_hand}
	_kept()


## The story from the beginning, the switch left as it was.
func start_over() -> void:
	var was_on := _story().on
	_settings.profile.story = StoryState.new()
	_settings.profile.story.on = was_on
	_kept()
