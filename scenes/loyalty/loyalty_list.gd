class_name LoyaltyList
extends ScrollContainer
## The loyalty program's open bets in a list, GAME.md 8.9, in the map's place for a player who only
## wants to know what is next: nearest done first, each its picture, its name, its bet and its bar;
## and once the roundabout is open, at its foot for good, the roundabout, its lap and how far its
## ring has come, there being always another lap. It reads the same however the map is drawn,
## and is what a phone at a big UI scale opens on.

## The cursor has come to the row of [param id], and the pane says it.
signal looked_at(id: StringName)
## The row of [param id] was pressed: the map, at it.
signal chosen(id: StringName)

const ROW_TALL := 74.0
const PICTURE := 44.0
## What the list says with no bet open, which is a program won to its end.
const NONE_OPEN := "Every bet on the map is won."


## One open bet, a row of the list, or the roundabout's.
class Row:
	extends Control

	signal looked_at(row: Row)
	signal chosen(row: Row)

	## The landmark it is, or none for the roundabout; what it is called and what its bet asks.
	var landmark: LoyaltyLandmark
	var id: StringName
	var title := ""
	## Whether it is the one pinned, GAME.md 8.9, which wears a pin and comes first.
	var pinned := false
	var bet := ""
	var come := Vector2.ZERO
	var said := ""
	## The editions owed for laps of the roundabout, for its row: calling while there are any.
	var owed := 0
	var _frame := FocusGlide.look()

	func _init() -> void:
		focus_mode = Control.FOCUS_ALL
		mouse_filter = Control.MOUSE_FILTER_PASS
		custom_minimum_size.y = LoyaltyList.ROW_TALL
		add_to_group(FocusGlide.GROUP)

	func _ready() -> void:
		focus_entered.connect(
			func() -> void:
				queue_redraw()
				looked_at.emit(self)
		)
		focus_exited.connect(queue_redraw)
		mouse_entered.connect(grab_focus)
		set_process(owed > 0)

	func _process(_delta: float) -> void:
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		var click := event as InputEventMouseButton
		if click != null and click.button_index == MOUSE_BUTTON_LEFT and not click.pressed:
			chosen.emit(self)
			accept_event()
		elif event.is_action_pressed(&"ui_accept"):
			chosen.emit(self)
			accept_event()

	func _draw() -> void:
		if has_focus():
			draw_style_box(_frame, Rect2(Vector2.ZERO, size))
		var room := 12.0
		var side := LoyaltyList.PICTURE
		var picture := Rect2(Vector2(room, (size.y - side) * 0.5), Vector2.ONE * side)
		if pinned:
			LoyaltyArt.draw_pin(self, picture.position + Vector2(-4.0, side * 0.42), 22.0)
		if landmark != null:
			LoyaltyArt.draw_reward(self, picture, landmark, HouseTheme.FOIL)
		else:
			# The roundabout: its ring, and the pot's star in it.
			var middle := picture.get_center()
			draw_arc(middle, side * 0.46, 0.0, TAU, 40, HouseTheme.FOIL, 3.0, true)
			draw_arc(middle, side * 0.32, 0.0, TAU, 32, Color(HouseTheme.FOIL, 0.5), 1.5, true)
			IconShapes.star(self, picture, 0.5, 0.5, 0.42, HouseTheme.FOIL)
			if owed > 0:
				# Calling, as on the map, an edition owed.
				var gone := LoyaltyBeacon.gone()
				var ink := Color(HouseTheme.FOIL, 1.0 - gone)
				draw_arc(middle, side * (0.5 + gone * 0.3), 0.0, TAU, 40, ink, 2.5, true)
		var left := picture.end.x + room * 1.5
		var wide := size.x - left - room
		var name_size := Type.LARGE - 4
		var top := room + Type.display_font().get_ascent(name_size) * 0.9
		draw_string(
			Type.display_font(),
			Vector2(left, top),
			title,
			HORIZONTAL_ALIGNMENT_LEFT,
			wide * 0.55,
			name_size,
			HouseTheme.WORDS
		)
		var bet_size := Type.LABEL
		draw_string(
			Type.TEXT,
			Vector2(left, top + 24.0),
			bet,
			HORIZONTAL_ALIGNMENT_LEFT,
			wide,
			bet_size,
			HouseTheme.FOIL if owed > 0 else HouseTheme.QUIET
		)
		if come.y <= 0.0:
			return
		var track := Rect2(Vector2(left + wide * 0.58, top - 9.0), Vector2(wide * 0.3, 6.0))
		draw_rect(track, Color(HouseTheme.WORDS, 0.15))
		draw_rect(
			Rect2(track.position, Vector2(track.size.x * come.x / come.y, 6.0)), HouseTheme.FOIL
		)
		draw_string(
			Type.STRONG,
			Vector2(track.end.x + 10.0, top - 2.0),
			said,
			HORIZONTAL_ALIGNMENT_LEFT,
			size.x - track.end.x - 10.0 - room,
			Type.LABEL - 1,
			HouseTheme.WORDS
		)


var _rows: VBoxContainer
var _none: Label


func _init() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	follow_focus = true
	_rows = VBoxContainer.new()
	_rows.name = "Rows"
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_theme_constant_override("separation", 4)
	add_child(_rows)
	_none = Label.new()
	_none.name = "None"
	_none.text = NONE_OPEN
	_none.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Type.text(_none, Type.BODY, HouseTheme.QUIET)
	_rows.add_child(_none)


## The open bets of [param profile]'s map, nearest done first, and on the map's order between two
## as near.
static func open_bets(profile: Profile) -> Array[LoyaltyLandmark]:
	var open: Array[LoyaltyLandmark] = []
	for each: LoyaltyLandmark in Loyalty.map().landmarks:
		if (
			Loyalty.is_drawn(profile, each)
			and Loyalty.standing(profile, each) == Loyalty.Standing.OPEN
		):
			open.append(each)
	var order := Loyalty.map().landmarks
	open.sort_custom(
		func(a: LoyaltyLandmark, b: LoyaltyLandmark) -> bool:
			var near_a := Loyalty.nearness(profile, a)
			var near_b := Loyalty.nearness(profile, b)
			if not is_equal_approx(near_a, near_b):
				return near_a > near_b
			return order.find(a) < order.find(b)
	)
	return open


## Fills the list for [param profile]'s map.
func fill(profile: Profile) -> void:
	# Left in the tree to go with it, hidden, so nothing is left belonging to nothing.
	for row: Node in _rows.get_children():
		if row != _none:
			(row as Control).hide()
			row.queue_free()
	var open := open_bets(profile)
	var ring := Loyalty.ring_open(profile)
	_none.visible = open.is_empty() and not ring
	# What is pinned first, then the rest nearest done first, and the roundabout last of all, being
	# the furthest off, however far round it has come.
	var pinned := Loyalty.pinned_of(profile)
	var landmark_rows: Array[Row] = []
	for each: LoyaltyLandmark in open:
		var row := Row.new()
		row.name = String(each.id)
		row.landmark = each
		row.id = each.id
		row.title = each.title
		row.bet = Loyalty.bet_of(each)
		row.come = Loyalty.progress(profile, each)
		row.said = Loyalty.progress_text(profile, each)
		row.pinned = each.id == pinned
		if row.pinned:
			landmark_rows.push_front(row)
		else:
			landmark_rows.append(row)
	for row: Row in landmark_rows:
		_add(row)
	if ring:
		var ring_row := _ring_row(profile)
		ring_row.pinned = pinned == Loyalty.ROUNDABOUT
		_add(ring_row)


## The roundabout's row: its lap, what a lap asks or the editions owed, calling while there are
## any, and how many of its ring's bets are met.
static func _ring_row(profile: Profile) -> Row:
	var row := Row.new()
	row.name = "Roundabout"
	row.id = Loyalty.ROUNDABOUT
	var laps := profile.loyalty.laps
	row.title = LoyaltyPane.ROUNDABOUT
	if laps > 0:
		row.title += "  ·  " + LoyaltyCard.LAP % laps
	row.bet = LoyaltyPane.RING_ASKS
	row.owed = profile.loyalty.owed
	if row.owed > 0:
		row.bet = LoyaltyPane.EDITION % row.owed
	var met := 0
	for bet: Dictionary in profile.loyalty.ring:
		var come := Loyalty.ring_progress(profile, bet)
		met += 1 if come.x >= come.y else 0
	var of := maxi(profile.loyalty.ring.size(), Loyalty.RING_BETS)
	row.come = Vector2(met, of)
	row.said = LoyaltyPane.RING_COME % [met, of]
	return row


func _add(row: Row) -> void:
	row.looked_at.connect(func(at: Row) -> void: looked_at.emit(at.id))
	row.chosen.connect(func(at: Row) -> void: chosen.emit(at.id))
	_rows.add_child(row)


## The rows: the open bets in order, then the roundabout's once it is open.
func rows() -> Array[Row]:
	var all: Array[Row] = []
	for child: Node in _rows.get_children():
		if child is Row and not child.is_queued_for_deletion():
			all.append(child as Row)
	return all


## The cursor on the row of [param id], or the first row; false with none.
func focus_on(id: StringName) -> bool:
	var all := rows()
	if all.is_empty():
		return false
	for row: Row in all:
		if row.id == id:
			row.grab_focus()
			return true
	all[0].grab_focus()
	return true
