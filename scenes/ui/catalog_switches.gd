class_name CatalogSwitches
extends GridContainer
## The switches under the catalog's joker pane, GAME.md 8.8, in rows of three, what each is, the
## control, and what is said after it, so they stand one over the other: Detailed, and beside it
## whether the cards are laid out by suit; the stack's field; and the suit the cards are shown for,
## see [SuitFilter]. Each calls on the dialog, which keeps what they say.

## How far the words of the switch beside Detailed stand from it.
const BESIDE := 8

var detailed_switch: CheckButton
var stepper: StackStepper
var stack_note: Label
var suits: SuitFilter
var by_suit_switch: CheckButton


## The switches of [param dialog], at the foot of [param column].
static func add_to(column: Control, dialog: CatalogDialog) -> CatalogSwitches:
	var switches := CatalogSwitches.new()
	switches.name = "Switches"
	switches.columns = 3
	switches.add_theme_constant_override("h_separation", CatalogDialog.SWITCHES_ACROSS)
	switches.add_theme_constant_override("v_separation", CatalogDialog.SWITCHES_DOWN)
	switches.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	column.add_child(switches)
	switches.detailed_switch = _switch(CatalogDialog.detailed, dialog.set_detailed)
	switches.detailed_switch.name = "Detailed"
	switches.by_suit_switch = _switch(CatalogDialog.by_suit, dialog.set_by_suit)
	switches.by_suit_switch.name = "BySuit"
	var beside := HBoxContainer.new()
	beside.add_theme_constant_override("separation", BESIDE)
	var words := Label.new()
	words.text = CatalogDialog.BY_SUIT
	Type.strong(words, Type.LABEL, HouseTheme.WORDS)
	beside.add_child(words)
	beside.add_child(switches.by_suit_switch)
	switches._row(CatalogDialog.DETAILED, switches.detailed_switch, beside)
	switches.stepper = StackStepper.new()
	switches.stepper.on_paper = true
	switches.stepper.name = "Stack"
	switches.stepper.stepped.connect(dialog.stack_by)
	switches.stack_note = Label.new()
	switches.stack_note.name = "Held"
	Type.text(switches.stack_note, Type.LABEL, JokerDetail.hint_ink())
	switches._row(CatalogDialog.STACK, switches.stepper, switches.stack_note)
	switches.suits = SuitFilter.new(CatalogDialog.suit_shown)
	switches.suits.name = "Suits"
	switches.suits.chosen.connect(dialog.show_suit)
	switches._row(CatalogDialog.SUIT, switches.suits)
	return switches


## A row: [param words] for what it is, [param control], and [param after] it or nothing.
func _row(words: String, control: Control, after: Control = null) -> void:
	var named := Label.new()
	named.text = words
	named.custom_minimum_size.x = CatalogDialog.NAMES_WIDE
	Type.strong(named, Type.BODY, HouseTheme.WORDS)
	add_child(named)
	add_child(control)
	add_child(after if after != null else Control.new())


## A switch on as [param on] says, calling [param flip] when it is flipped, its words beside it
## rather than on it: a pill of the House's paper on the mat, as the loyalty program's List switch
## is on its cover. Left to the mouse and a finger: keys and a pad have its bind, see [method
## CatalogDialog._input], drawn in the row of tabs.
static func _switch(on: bool, flip: Callable) -> CheckButton:
	var switch := MenuTheme.toggle(on)
	switch.focus_mode = Control.FOCUS_NONE
	switch.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	# No room round the picture, the way the stack's field has none, so the two line up.
	for state: StringName in [&"normal", &"hover", &"pressed", &"hover_pressed", &"disabled"]:
		switch.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	switch.toggled.connect(flip)
	AtlasTicketStyle.dress_switch(switch)
	return switch
