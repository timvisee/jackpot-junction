class_name LoyaltyEditions
extends PanelContainer
## The editions a lap of the roundabout pays, GAME.md 8.9, chosen: the house's pane over the map,
## a button for each piece of dress the profile has won that a finish shows on, its paint, its hats
## and its flags, saying the finish it moves up to, Foil, then Holographic, then Polychrome, and one
## at its last finish not to be pressed; and Done. Chosen, the piece moves up and the next lap's
## edition waits, see [method Loyalty.spend_edition].

## An edition was chosen, or the pane put away.
signal chosen(piece: String)
signal done

const TITLE := "Choose an edition"
const LEFT := "%d to choose"
const AT_LAST := "%s  ·  %s, the last finish"
const MOVES := "%s  ·  %s"
const NONE_YET := "%s  ·  %s"
const DONE := "Done"
## The kinds of dress a finish shows on.
const SHOWN: Array[StringName] = [&"paint", &"hat", &"flag"]

var profile: Profile
var _rows: VBoxContainer
var _left: Label
var _done: Button


static func for_profile(whose: Profile) -> LoyaltyEditions:
	var editions := LoyaltyEditions.new()
	editions.profile = whose
	return editions


## Every piece of dress [param whose] has won that a finish shows on, "hat:Fedora", in the map's
## order.
static func pieces_of(whose: Profile) -> PackedStringArray:
	var pieces := PackedStringArray()
	for piece: String in Loyalty.unlocks_of(whose)["dress"]:
		if StringName(piece.get_slice(":", 0)) in SHOWN and piece not in pieces:
			pieces.append(piece)
	return pieces


func _ready() -> void:
	add_theme_stylebox_override("panel", MenuTheme.pane_style())
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	add_child(column)
	column.add_child(MenuTheme.title(TITLE, Type.HEADING))
	_left = MenuTheme.subtitle("", Type.LABEL)
	column.add_child(_left)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(560.0, 360.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	column.add_child(scroll)
	_rows = VBoxContainer.new()
	_rows.name = "Pieces"
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_theme_constant_override("separation", 6)
	scroll.add_child(_rows)
	_done = MenuTheme.button(DONE)
	_done.name = "Done"
	_done.pressed.connect(func() -> void: done.emit())
	column.add_child(_done)
	_fill()
	MenuTheme.deal(self)


func _fill() -> void:
	for child: Node in _rows.get_children():
		(child as Control).hide()
		child.queue_free()
	_left.text = LEFT % profile.loyalty.owed
	var first: Button = null
	# Its words start at the row's left, so clear of the chevron, as a box's are, see [HouseTheme].
	var looks := HouseTheme.button_looks()
	for state: StringName in looks:
		looks[state].content_margin_left = 38.0
	for piece: String in pieces_of(profile):
		var finish := Loyalty.finish_of(profile, piece)
		var named := (
			"%s: %s"
			% [
				LoyaltyPane.PARTS.get(StringName(piece.get_slice(":", 0)), ""),
				piece.get_slice(":", 1)
			]
		)
		var button := MenuTheme.button("", Type.BODY)
		button.name = piece.replace(":", "_")
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		for state: StringName in looks:
			button.add_theme_stylebox_override(state, looks[state])
		if finish >= Loyalty.FINISHES.size():
			button.text = AT_LAST % [named, Loyalty.FINISHES[-1]]
			button.disabled = true
		else:
			button.text = MOVES % [named, Loyalty.FINISHES[finish]]
			button.pressed.connect(_choose.bind(piece))
			if first == null:
				first = button
		_rows.add_child(button)
	(first if first != null else _done).grab_focus.call_deferred()


func _choose(piece: String) -> void:
	if not Loyalty.spend_edition(profile, piece):
		return
	Audio.play_sfx(&"stamp", -6.0, 0.05)
	chosen.emit(piece)
	if profile.loyalty.owed <= 0:
		done.emit()
		return
	_fill()
