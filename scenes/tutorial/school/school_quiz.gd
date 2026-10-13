class_name SchoolQuiz
extends Control
## The driving school's pop quiz, GAME.md 9.4a: three easy questions, one at a time, three answers
## each on buttons. A right answer lights green with a word; a wrong one shakes red, and after a
## moment the right one lights green and presses itself, with a word for that too, so nobody
## fails and everybody leaves knowing the answer. Three down, the theory is passed, on a card
## that says so, the course's first step ticked and the other two still to come under it, with
## the one button on to the driving test.

signal passed

## Each question: the words, the three answers, and which of them is right.
const QUESTIONS: Array[Array] = [
	["What goes in your pot?", ["Chips", "Soup", "Regret"], 0],
	["What is safe from everybody?", ["Your pot", "Your bank", "Nothing, ever"], 1],
	["A Royal Flush is...", ["All four pads, held at once", "A plumbing matter", "Luck"], 0],
]
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
	_show(0)


## Question [param i] up, with fresh buttons.
func _show(i: int) -> void:
	index = i
	_locked = false
	for old: Node in _answers.get_children():
		_answers.remove_child(old)
		old.queue_free()
	answers.clear()
	var question: Array = QUESTIONS[i]
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


## Answers the question up with its answer [param j].
func answer(j: int) -> void:
	if _locked or j < 0 or j >= answers.size():
		return
	_locked = true
	var which: int = QUESTIONS[index][2]
	for button: Button in answers:
		button.disabled = true
		button.focus_mode = Control.FOCUS_NONE
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


## [param button] lit with an edge of [param color], disabled as it is.
func _light(button: Button, color: Color) -> void:
	var lit := MenuTheme.button_style(MenuTheme.BUTTON_HOVER, color)
	button.add_theme_stylebox_override("disabled", lit)
	button.add_theme_stylebox_override("pressed", lit)
	button.add_theme_color_override("font_disabled_color", Color.WHITE)


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
	if index + 1 < QUESTIONS.size():
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
