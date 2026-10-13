class_name StoryDebugTab
extends ScrollContainer
## The settings' last page in a debug build alone, GAME.md 8.5: where the profile playing is in the
## story of 8.7, STORY.md 5 and 7, and in its loyalty program, 8.9, and buttons that move them,
## each kept in the profile at once; the achievements of 8.10, and buttons that earn them or take
## them back; and a switch that draws what the camera keeps clear, 8.2. For
## trying the story and the program out; a released game has no such page. The README lists the
## command line's story and loyalty arguments beside it.

const WIDTH := 900.0
const INK := Color(0.86, 0.86, 0.9)
const SIZE := 17
## How far one press of More time moves the clock.
const MORE := 600.0

var _settings: Settings
var _said: Label
var _program: Label
var _achievements: Label


static func make(settings: Settings) -> StoryDebugTab:
	var tab := StoryDebugTab.new()
	tab._settings = settings
	return tab


func _init() -> void:
	name = "Debug"


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
		["Next note", next_note],
		["One note back", note_back],
		["Unlock all notes", every_note],
		["No notes", no_notes],
		["Every note unread", all_unread],
		["Final Hand due", final_hand_due],
		["End the story", end_story],
		["Start the story over", start_over],
		["Invitation again", invitation_again],
	]:
		grid.add_child(_button(way))
	# The loyalty program, GAME.md 8.9.
	column.add_child(MenuTheme.subtitle("Loyalty program", Type.LABEL))
	_program = Label.new()
	_program.name = "Program"
	Type.set_font(_program, NotePage.TYPED, SIZE)
	_program.add_theme_color_override("font_color", INK)
	column.add_child(_program)
	var more := GridContainer.new()
	more.name = "ProgramButtons"
	more.columns = 3
	more.add_theme_constant_override("h_separation", 12)
	more.add_theme_constant_override("v_separation", 10)
	column.add_child(more)
	for way: Array in [
		["Get the card", get_card],
		["Welcome again", welcome_again],
		["Win every landmark", win_everything],
		["Bets a step short", bets_short],
		["Lost Property due", lost_due],
		["Next lap", next_lap],
		["An edition owed", edition_owed],
		["Program over", program_over],
	]:
		more.add_child(_button(way))
	# The achievements, GAME.md 8.10.
	column.add_child(MenuTheme.subtitle("Achievements", Type.LABEL))
	_achievements = Label.new()
	_achievements.name = "Earned"
	Type.set_font(_achievements, NotePage.TYPED, SIZE)
	_achievements.add_theme_color_override("font_color", INK)
	column.add_child(_achievements)
	var earned := GridContainer.new()
	earned.name = "AchievementButtons"
	earned.columns = 3
	earned.add_theme_constant_override("h_separation", 12)
	earned.add_theme_constant_override("v_separation", 10)
	column.add_child(earned)
	for way: Array in [
		["Earn every achievement", earn_every_achievement],
		["Take every one back", no_achievements],
		["Credit as from before", credit_again],
		["Toast the next", toast_next],
	]:
		earned.add_child(_button(way))
	# The camera, GAME.md 8.2: what it keeps the karts clear of, drawn over a match.
	column.add_child(MenuTheme.subtitle("Camera", Type.LABEL))
	var clearance := HBoxContainer.new()
	clearance.add_theme_constant_override("separation", 16)
	var words := Label.new()
	words.text = "Show what the camera keeps clear"
	Type.set_font(words, Type.TEXT, SIZE)
	words.add_theme_color_override("font_color", INK)
	words.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	clearance.add_child(words)
	var switch := MenuTheme.toggle(_settings.show_clearance)
	switch.name = "ShowClearance"
	switch.toggled.connect(func(on: bool) -> void: _settings.show_clearance = on)
	clearance.add_child(switch)
	column.add_child(clearance)
	say()


## A button of the page for [param way], its words and what it does.
func _button(way: Array) -> Button:
	var button := MenuTheme.button(str(way[0]), Type.LABEL)
	button.name = str(way[0]).replace(" ", "").replace("-", "Back").replace("+", "On")
	button.custom_minimum_size.x = 280.0
	button.pressed.connect(func() -> void: (way[1] as Callable).call())
	return button


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
		lines.append("Next note ...... 1, in map %d" % Story.FIRST_NOTE_MAP)
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
	_say_program()
	_say_achievements()


## How many achievements the profile playing has earned, and whether it was credited yet.
func _say_achievements() -> void:
	if _achievements == null:
		return
	var profile := _settings.profile
	_achievements.text = (
		"Earned ......... %d of %d, %s"
		% [
			Achievements.earned_count(profile),
			Achievements.all().size(),
			"credited" if profile.achievements.credited else "credited at the next title",
		]
	)


## Every achievement earned at once, quietly, each new.
func earn_every_achievement() -> void:
	for each: Achievement in Achievements.all():
		Achievements.earn(_settings.profile, each.id, -1, true)
	_kept()


## Every achievement taken back, the profile credited as ever.
func no_achievements() -> void:
	_settings.profile.achievements = AchievementState.new()
	_settings.profile.achievements.credited = true
	_kept()


## Every achievement taken back and the profile credited again at the next title, as one from
## before achievements is.
func credit_again() -> void:
	_settings.profile.achievements = AchievementState.new()
	_kept()


## The next achievement in the list not yet earned earned, with its toast.
func toast_next() -> void:
	for each: Achievement in Achievements.all():
		if Achievements.earn(_settings.profile, each.id):
			break
	_kept()


## Where the profile playing is in its loyalty program, line by line.
func _say_program() -> void:
	if _program == null:
		return
	var profile := _settings.profile
	var state := profile.loyalty
	var lines: Array[String] = []
	lines.append(
		"Card ........... %s" % (("No. %s" % state.member) if state.welcomed else "not yet")
	)
	var won := 0
	var open := 0
	for each: LoyaltyLandmark in Loyalty.map().landmarks:
		var standing := Loyalty.standing(profile, each)
		won += 1 if standing == Loyalty.Standing.WON else 0
		open += 1 if standing == Loyalty.Standing.OPEN else 0
	lines.append(
		"Landmarks ...... %d of %d won, %d open" % [won, Loyalty.map().landmarks.size(), open]
	)
	var met := 0
	for bet: Dictionary in state.ring:
		var come := Loyalty.ring_progress(profile, bet)
		met += 1 if come.x >= come.y else 0
	var ring := (
		"shut" if not Loyalty.ring_open(profile) else "%d of %d met" % [met, state.ring.size()]
	)
	lines.append("Roundabout ..... lap %d, %d to choose, ring %s" % [state.laps, state.owed, ring])
	_program.text = "\n".join(lines)


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


## The next note in the story's order found there and then, as if it had been picked up off the
## floor, new until it is read; nothing once every note is found.
func next_note() -> void:
	var number := StoryNotes.next_of(_story())
	if number == 0:
		return
	StoryNotes.file(_settings.profile, number)
	_kept()


## The last note found taken away again, read or not.
func note_back() -> void:
	var story := _story()
	if story.notes.is_empty():
		return
	var last := story.notes[0]
	for number: int in story.notes:
		last = maxi(last, number)
	story.notes.remove_at(story.notes.find(last))
	var read := story.notes_read.find(last)
	if read >= 0:
		story.notes_read.remove_at(read)
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


## The invitation that brought the player here, STORY.md 6.1a, owed again: up the next time the
## title comes up, its stub given a new number.
func invitation_again() -> void:
	var story := _story()
	story.invited = false
	story.invitation = ""
	_kept()


## The loyalty card at once, as Activate gives it: the profile a member, its card numbered, the
## letter kept in the folder and the slip road's bets open.
func get_card() -> void:
	LoyaltyWelcome.join(_settings.profile)
	_kept()


## The welcome owed again: up at the title the next time it comes up, as after a first map.
func welcome_again() -> void:
	var profile := _settings.profile
	profile.loyalty.welcomed = false
	profile.story.kept_letter = false
	profile.stats[&"maps"] = maxf(float(profile.stats.get(&"maps", 0.0)), 1.0)
	_kept()


## Every landmark won, the card first if there is none.
func win_everything() -> void:
	var profile := _settings.profile
	if not profile.loyalty.welcomed:
		LoyaltyWelcome.join(profile)
	for each: LoyaltyLandmark in Loyalty.map().landmarks:
		profile.loyalty.win(each.id)
	Loyalty.settle(profile)
	_kept()


## Every open bet a step short of its count, the next map to win them.
func bets_short() -> void:
	Loyalty.near_everything(_settings.profile)
	_kept()


## Every open thing of Lost Property in the next map of its room for certain.
func lost_due() -> void:
	Loyalty.lost_certain(_settings.profile)
	_kept()


## The next lap of the roundabout, an edition owed for it.
func next_lap() -> void:
	Loyalty.next_lap(_settings.profile)
	_kept()


## One more edition to choose at the roundabout.
func edition_owed() -> void:
	_settings.profile.loyalty.owed += 1
	_kept()


## The loyalty program from the beginning: no card, nothing won, the letter out of the folder.
func program_over() -> void:
	_settings.profile.loyalty = LoyaltyState.new()
	_settings.profile.story.kept_letter = false
	_kept()


## The story from the beginning, the switch left as it was.
func start_over() -> void:
	var was_on := _story().on
	_settings.profile.story = StoryState.new()
	_settings.profile.story.on = was_on
	_kept()
