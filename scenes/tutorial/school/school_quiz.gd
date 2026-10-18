class_name SchoolQuiz
extends Control
## The driving school's pop quiz, GAME.md 9.4a: three easy questions, one at a time, three answers
## each on buttons. A right answer lights green with a word; a wrong one shakes red, and after a
## moment the right one lights green and presses itself, with a word for that too, so nobody
## fails and everybody leaves knowing the answer. While the story is on, a fourth comes after the
## three, the House's, STORY.md 6.7. It waits for a pick as they do, but whatever is picked, the
## House's answer is the one pressed, in the House's gold: picked otherwise, the two trade places,
## the House's sliding over into the place pressed and held down there, answered for the player
## and not scored. Then the theory is passed, on a card that says so, the course's first step
## ticked and the other two still to come under it, with the one button on to the driving test.

signal passed

## Each question: the words, the three answers, and which of them is right.
const QUESTIONS: Array[Array] = [
	["What goes in your pot?", ["Chips", "Soup", "Regret"], 0],
	["What is safe from everybody?", ["Your pot", "Your bank", "Nothing, ever"], 1],
	["A Royal Flush is...", ["All four pads, held at once", "A plumbing matter", "Luck"], 0],
]
## The House's question, STORY.md 6.7: the words, the answers, and the one it gives for the player.
const HOUSE_QUESTION: Array = ["Will you come back after you lose?", ["Yes", "No", "Depends"], 0]
const HOUSE_QUIP := "Answered for you."
## How long the player's own pick on the House's question stands, held down in [constant PICK],
## before the House's answer trades places with it, and how long the trade takes.
const HOUSE_BEAT := 0.2
const SWAP := 0.35
## How far the two answers sway apart as they pass, and how much the House's is lifted, over the
## player's, as it goes.
const SWAY := 22.0
const LIFT := 0.05
## How long the House's question stays up answered before the theory is passed: longer than a
## question of the quiz's own, for reading whose answer it was.
const HOUSE_LINGER := 2.4
## The edge of the player's own pick on the House's question while it still stands.
const PICK := Color(0.88, 0.88, 0.92)
const RIGHT_QUIPS: Array[String] = ["Correct.", "Textbook.", "Look at you go."]
const WRONG_QUIPS: Array[String] = ["Close enough.", "We'll allow it.", "Bold. Wrong, but bold."]
const GREEN := Color(0.36, 0.9, 0.46)
const RED := Palette.CHIP_RED
## How long a wrong answer stands before the right one presses itself, and how long a question
## stays up answered before the next.
const THINK := 0.55
const LINGER := 1.4
const SHAKES := 4
const PASSED := "THEORY: PASSED"
const PASSED_LINE := "We're not picky. The road will be."
const ON := "To the driving test"
const WIDTH := 460.0

## Which question is up, and how many were answered right first time.
var index := 0
var right := 0
## The answers of the question up, for pressing one.
var answers: Array[Button] = []
## The button on to the driving test, once the quiz is done.
var on: Button
## Whether the House asks its question after the three, the story on, see [method house_asks].
var asked_by_house := false

var _column: VBoxContainer
var _caption: Label
var _question: Label
var _answers: VBoxContainer
var _quip: Label
var _locked := false


static func add_to(parent: Control) -> SchoolQuiz:
	var page := SchoolQuiz.new()
	page.name = "Quiz"
	parent.add_child(page)
	return page


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# In the middle, shrunk where a short screen has no room for it, as the school's pages are.
	var center := FitScale.filling(self)
	var pane := MenuTheme.pane()
	center.add_child(pane)
	_column = VBoxContainer.new()
	_column.add_theme_constant_override("separation", 16)
	_column.custom_minimum_size = Vector2(WIDTH + 40.0, 0.0)
	pane.add_child(_column)
	_caption = MenuTheme.subtitle("", Type.LABEL)
	_column.add_child(_caption)
	_question = MenuTheme.title("", Type.HEADING)
	_question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_column.add_child(_question)
	_answers = VBoxContainer.new()
	_answers.add_theme_constant_override("separation", 10)
	_column.add_child(_answers)
	_quip = MenuTheme.subtitle(" ", Type.BODY)
	_column.add_child(_quip)
	asked_by_house = house_asks()
	_show(0)


## Whether the House asks its question at this machine, see [method Story.told_here].
static func house_asks() -> bool:
	return Story.told_here()


## The question up at [param i]: the quiz's own three, then the House's.
static func question_at(i: int) -> Array:
	return QUESTIONS[i] if i < QUESTIONS.size() else HOUSE_QUESTION


## Question [param i] up, with fresh buttons.
func _show(i: int) -> void:
	index = i
	_locked = false
	for old: Node in _answers.get_children():
		_answers.remove_child(old)
		old.queue_free()
	answers.clear()
	var question := question_at(i)
	# The House's question comes past the count the quiz gave: four of three.
	_caption.text = "Pop quiz  ·  %d of %d" % [i + 1, QUESTIONS.size()]
	_question.text = question[0]
	_quip.text = " "
	_quip.modulate = Color.WHITE
	for j: int in (question[1] as Array).size():
		var button := MenuTheme.button(question[1][j], Type.LARGE)
		button.custom_minimum_size = Vector2(WIDTH, 56.0)
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.pressed.connect(answer.bind(j))
		_answers.add_child(button)
		answers.append(button)
	answers[0].grab_focus()


## Answers the question up with its answer [param j]. The House's, past the quiz's own, is
## answered for the player whatever [param j] is, see [method _answered_for_you].
func answer(j: int) -> void:
	if _locked or j < 0 or j >= answers.size():
		return
	_locked = true
	for button: Button in answers:
		button.disabled = true
		button.focus_mode = Control.FOCUS_NONE
	if index >= QUESTIONS.size():
		_answered_for_you(j)
		return
	var which: int = QUESTIONS[index][2]
	if j == which:
		right += 1
		_light(answers[j], GREEN)
		_say(RIGHT_QUIPS[index % RIGHT_QUIPS.size()], GREEN)
		get_tree().create_timer(LINGER).timeout.connect(_next)
		return
	_light(answers[j], RED)
	_shake(answers[j])
	MenuTheme.back_sound()
	# The right one, a moment later, pressing itself.
	var think := get_tree().create_timer(THINK)
	think.timeout.connect(
		func() -> void:
			if not is_inside_tree():
				return
			_light(answers[which], GREEN)
			MenuTheme.hold(answers[which], true)
			Audio.play_sfx(&"ui_click", MenuTheme.CLICK_DB, 0.0)
			_say(WRONG_QUIPS[index % WRONG_QUIPS.size()], Color(0.88, 0.88, 0.92))
			get_tree().create_timer(LINGER).timeout.connect(_next)
	)


## The House's question answered with [param j], STORY.md 6.7: whatever the player picked, the
## House's answer is the one pressed. Its own lights in gold where it stands; any other is held
## down a beat, then the House takes over, see [method _taken_over], and the two trade places,
## the House's sliding over the player's into the place pressed, so the House is seen to answer
## for them. Nothing can be pressed meanwhile.
func _answered_for_you(j: int) -> void:
	var which: int = HOUSE_QUESTION[2]
	if j == which:
		_overruled(j)
		return
	var house := answers[which]
	var pick := answers[j]
	_light(pick, PICK)
	MenuTheme.hold(pick, true)
	var trade := create_tween()
	trade.tween_interval(HOUSE_BEAT)
	trade.tween_callback(_taken_over.bind(house, pick))
	var slide := trade.tween_method(_slide.bind(house, pick), 0.0, 1.0, SWAP)
	slide.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	trade.tween_callback(_traded.bind(which, j))


## The House taking the question over from the player as the trade begins: its answer
## [param house] lit in its gold and drawn over the rest, the player's [param pick] let go of and
## unlit, and the shove of a card.
func _taken_over(house: Button, pick: Button) -> void:
	MenuTheme.hold(pick, false)
	_unlight(pick)
	_light(house, HouseTheme.FOIL)
	house.z_index = 1
	Audio.play_sfx(&"page", -10.0, 0.05)


## The House's answer [param house] and the player's [param pick] at [param t] of their trade,
## from where each rests to where the other does: laid out first, so a layout changed on the way
## is where they end up, then drawn apart sideways and the House's lifted, most at halfway.
func _slide(t: float, house: Button, pick: Button) -> void:
	_answers.notification(Container.NOTIFICATION_SORT_CHILDREN)
	var apart := sin(t * PI)
	var by := (pick.position.y - house.position.y) * t
	house.position += Vector2(SWAY * apart, by)
	pick.position += Vector2(-SWAY * apart, -by)
	house.pivot_offset = house.size * 0.5
	house.scale = Vector2.ONE * (1.0 + LIFT * apart)


## The trade done: the House's answer, at [param which], put where the player pressed,
## [param j], for good, and the player's where the House's was. Then the House's presses itself
## there.
func _traded(which: int, j: int) -> void:
	var house := answers[which]
	var pick := answers[j]
	_answers.move_child(house, j)
	_answers.move_child(pick, which)
	answers[which] = pick
	answers[j] = house
	house.z_index = 0
	house.scale = Vector2.ONE
	_answers.notification(Container.NOTIFICATION_SORT_CHILDREN)
	Audio.play_sfx(&"ui_click", MenuTheme.CLICK_DB, 0.0)
	_overruled(j)


## The House's answer, at [param j] where the player pressed, lit in the House's gold rather than
## the quiz's green and held down, "Answered for you." under it and said, and the theory passed a
## while later, see [constant HOUSE_LINGER]. Not scored.
func _overruled(j: int) -> void:
	var house := answers[j]
	_light(house, HouseTheme.FOIL)
	MenuTheme.hold(house, true)
	_say(HOUSE_QUIP, HouseTheme.FOIL)
	ScreenReader.say(self, "%s %s" % [house.text, HOUSE_QUIP])
	get_tree().create_timer(HOUSE_LINGER).timeout.connect(_next)


## [param button] lit with an edge of [param color], disabled as it is.
func _light(button: Button, color: Color) -> void:
	var lit := MenuTheme.button_style(MenuTheme.BUTTON_HOVER, color)
	button.add_theme_stylebox_override("disabled", lit)
	button.add_theme_stylebox_override("pressed", lit)
	button.add_theme_color_override("font_disabled_color", Color.WHITE)


## [param button] as it was before [method _light], disabled as the rest are.
func _unlight(button: Button) -> void:
	button.remove_theme_stylebox_override("disabled")
	button.remove_theme_stylebox_override("pressed")
	button.remove_theme_color_override("font_disabled_color")


## A wrong answer shakes its head.
func _shake(button: Button) -> void:
	button.pivot_offset = button.size * 0.5
	var shake := create_tween()
	for i: int in SHAKES:
		var way := 0.035 if i % 2 == 0 else -0.035
		shake.tween_property(button, "rotation", way, 0.05)
	shake.tween_property(button, "rotation", 0.0, 0.05)


func _say(words: String, color: Color) -> void:
	_quip.text = words
	_quip.modulate = color


func _next() -> void:
	if not is_inside_tree():
		return
	if index + 1 < QUESTIONS.size() or (index + 1 == QUESTIONS.size() and asked_by_house):
		_show(index + 1)
	else:
		_finish()


## What the card says of [param right] of [param asked] answered right first time: all of them
## is a word for a show-off, none of them a word of comfort, and in between, the rest came
## eventually.
static func score_words(right: int, asked: int) -> String:
	if right >= asked:
		return "%d of %d right the first time. Nobody likes a show-off." % [right, asked]
	if right <= 0:
		return "%d of %d right the first time. You'll get them, eventually." % [right, asked]
	return (
		"%d of %d right the first time. The other %d, eventually." % [right, asked, asked - right]
	)


## Passed, as everybody is: the card says so, and the one button goes on to the driving test.
func _finish() -> void:
	for old: Node in _column.get_children():
		_column.remove_child(old)
		old.queue_free()
	_column.add_child(MenuTheme.title(PASSED, Type.TITLE))
	_column.add_child(MenuTheme.subtitle(PASSED_LINE, Type.BODY))
	_column.add_child(MenuTheme.subtitle(score_words(right, QUESTIONS.size()), Type.LABEL))
	# The course, with its first step ticked and the other two still to come.
	_column.add_child(SchoolEnrollment.course(1))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0.0, 6.0)
	_column.add_child(gap)
	# On to the driving test, the way on from a passed quiz, in foil as Enroll is, GAME.md 8.1a.
	on = MenuTheme.primary(MenuTheme.button(ON, Type.HEADING))
	on.name = "On"
	on.custom_minimum_size = Vector2(WIDTH, 60.0)
	on.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	on.pressed.connect(func() -> void: passed.emit())
	_column.add_child(on)
	on.grab_focus()
	Audio.play_sfx(&"ready", -6.0, 0.0)
