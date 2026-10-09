class_name LoyaltyPane
extends PanelContainer
## The pane beside the loyalty program's map, GAME.md 8.9: the house's pane of 8.3 as in the
## catalog, describing the landmark under the cursor. Its name and its district, the bet and how far
## it has come, what it pays with the picture of each, the cards it adds and its part of the dress;
## and for a closed one, which shows what it pays but not what it asks, which roads would open it.

## The roundabout's edition asked for, from its pane's button.
signal edition_asked
## The Pin button was pressed: what the pane says to be pinned, or unpinned.
signal pin_asked

const WIDTH := 380.0
const HINT := JokerDetail.HINT
## The words for each district, as the pane's header says them, and each one's color there.
const DISTRICTS := {
	LoyaltyLandmark.District.SLIP: ["", HouseTheme.WORDS],
	LoyaltyLandmark.District.STRIP: ["The Strip", HouseTheme.FOIL],
	LoyaltyLandmark.District.DEPARTMENT: ["Dept. of Karts", Color("#8fb2ff")],
	LoyaltyLandmark.District.OFF_THE_BOOKS: ["Off the books", Color(0.78, 0.78, 0.8)],
}
## How it stands, said over its bet.
const CLOSED := "Closed"
const OPEN := "Open"
const WON := "Won"
const KEYSTONE := "Keystone"
const ASKS_LATER := "What it asks shows once a road into it is won."
## What a closed one needs: any road in, or for a keystone every one.
const OPENS_BY := "Opens with a road from %s."
const OPENS_BY_ALL := "Opens once every road in is won: %s."
const OR := " or "
const AND := " and "
const PAYS := "PAYS"
## The words for each kind of dress a landmark pays, by the name it gives it.
const PARTS := {
	&"paint": "Paint",
	&"hat": "Hat",
	&"flag": "Flag",
	&"trail": "Trail",
	&"frame": "Plate",
	&"marks": "Tire marks",
	&"card_back": "Card back",
}
const SHOWROOM := "The Showroom, a bay off the Garage"
const NOTE := "A loose note"
const ONTO_THE_MAP := "The roads onto the map"
const CARD := "Joker card: %s"
const ITEM := "Power-up: %s"
const PICTURE := 34.0
## The roundabout's pane: its name and place, how it opens, a lap's bets and what a lap pays.
const ROUNDABOUT := "The Roundabout"
const POT := "JACKPOT"
const LAP := "LAP %d"
const RING_OPENS := "Opens once %s are won."
const RING_ASKS := "Win all seven bets of the ring to go round."
const RING_COME := "%d of %d won"
const RING_PAYS := "An edition: a piece of your dress moves up a finish"
const EDITION := "Choose an edition (%d)"
## Pinning what the pane says, GAME.md 8.9: the button's words for it unpinned and pinned, and its
## bind for keys and pads.
const PIN := "Pin"
const PINNED := "Pinned"
const PIN_ACTION := &"ui_accept"

const CATALOG: JokerCatalog = preload("res://data/jokers/catalog.tres")
const FIRST: PowerUpTable = preload("res://data/powerups/first_set.tres")
const LATER: PowerUpTable = preload("res://data/powerups/later_set.tres")


## A picture of one thing a landmark pays, square in its room: [member draw_with] is called with
## the canvas and the box, the rest of what it needs bound to it.
class Picture:
	extends Control

	var draw_with: Callable

	func _draw() -> void:
		var side := minf(size.x, size.y)
		draw_with.call(self, Rect2((size - Vector2.ONE * side) * 0.5, Vector2.ONE * side))


## The landmark the pane says, by id.
var shown: StringName
## The button that pins what the pane says, see [signal pin_asked].
var pin: Button

var _style: TicketStyle
var _name: Label
var _district: Label
var _standing: Label
var _bet: Label
var _bar: ProgressBar
var _come: Label
var _opens: Label
var _pays: VBoxContainer
var _ring: VBoxContainer
var _edition: Button
var _box: VBoxContainer


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style = TicketStyle.cut(MenuTheme.PANE_BG, 10.0, 18.0, 18.0)
	_style.frame_inset = 5.0
	_style.bite = 8.0
	_style.waves = 64.0
	_style.shadow = 12.0
	add_theme_stylebox_override("panel", _style)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 10)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_box)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 14)
	_box.add_child(heading)
	_name = _line(28, Color(0.97, 0.97, 1.0))
	_name.name = "Name"
	Type.set_font(_name, Type.display_font(), 28)
	_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.add_child(_name)
	_district = _line(16, Color.WHITE)
	_district.name = "District"
	Type.set_font(_district, Type.STRONG, 16)
	_district.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heading.add_child(_district)
	var tear := MenuTheme.perforation()
	tear.custom_minimum_size.x = WIDTH
	_box.add_child(tear)
	_standing = _line(15, HINT)
	_standing.name = "Standing"
	Type.set_font(_standing, Type.STRONG, 15)
	_box.add_child(_standing)
	_bet = _line(20, HouseTheme.WORDS)
	_bet.name = "Bet"
	_bet.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bet.custom_minimum_size.x = WIDTH
	_box.add_child(_bet)
	_bar = ProgressBar.new()
	_bar.name = "Bar"
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(WIDTH, 10.0)
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(_bar)
	_come = _line(16, HINT)
	_come.name = "Come"
	_box.add_child(_come)
	var pays := _line(14, HINT)
	pays.text = PAYS
	Type.set_font(pays, Type.STRONG, 14)
	_box.add_child(pays)
	_pays = VBoxContainer.new()
	_pays.name = "Pays"
	_pays.add_theme_constant_override("separation", 8)
	_pays.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(_pays)
	_opens = _line(16, HINT)
	_opens.name = "Opens"
	_opens.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_opens.custom_minimum_size.x = WIDTH
	_box.add_child(_opens)
	_ring = VBoxContainer.new()
	_ring.name = "Ring"
	_ring.add_theme_constant_override("separation", 4)
	_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(_ring)
	_edition = MenuTheme.primary(MenuTheme.button("", Type.BODY))
	_edition.name = "Edition"
	_edition.focus_mode = Control.FOCUS_NONE
	_edition.pressed.connect(func() -> void: edition_asked.emit())
	ButtonBinds.mark(_edition, PIN_ACTION)
	_edition.visible = false
	_box.add_child(_edition)
	pin = MenuTheme.button(PIN, Type.LABEL)
	pin.name = "Pin"
	pin.toggle_mode = true
	pin.focus_mode = Control.FOCUS_NONE
	pin.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	pin.custom_minimum_size.x = 160.0
	pin.pressed.connect(func() -> void: pin_asked.emit())
	ButtonBinds.mark(pin, PIN_ACTION)
	pin.visible = false
	_box.add_child(pin)


## Fills the pane for the roundabout on [param profile]'s map, GAME.md 8.9: shut, which keystones
## open it; open, its lap, the ring's seven bets with how far each has come, what a lap pays, and
## the button to choose an edition while one is owed.
func show_roundabout(profile: Profile) -> void:
	shown = Loyalty.ROUNDABOUT
	_name.text = ROUNDABOUT
	_district.text = POT
	_district.add_theme_color_override("font_color", HouseTheme.FOIL)
	_style.frame = Color(HouseTheme.FOIL, JokerDetail.FRAME)
	_style.frame_body = Color(HouseTheme.FOIL, JokerDetail.FRAME_BODY)
	_style.engraving = Color(HouseTheme.FOIL, JokerDetail.ENGRAVED)
	_clear_rows()
	var open := Loyalty.ring_open(profile)
	var state := profile.loyalty
	var standing := CLOSED
	if open:
		standing = LAP % state.laps if state.laps > 0 else OPEN
	_standing.text = standing.to_upper()
	_opens.visible = not open
	if not open:
		var keystones := PackedStringArray()
		for each: LoyaltyLandmark in Loyalty.map().landmarks:
			if each.keystone and Loyalty.map().reaches_roundabout(each.id):
				keystones.append(each.title)
		_opens.text = RING_OPENS % _listed(keystones, AND)
	_bet.text = RING_ASKS if open else ASKS_LATER
	_bet.add_theme_color_override("font_color", HouseTheme.WORDS if open else HINT)
	var met := 0
	for bet: Dictionary in state.ring:
		var come := Loyalty.ring_progress(profile, bet)
		met += 1 if come.x >= come.y else 0
		if open:
			var line := _line(16, HouseTheme.WORDS if come.x < come.y else HINT)
			line.text = "%s  ·  %s" % [Loyalty.ring_bet_of(bet), _so_far(profile, bet)]
			_ring.add_child(line)
	_bar.visible = open and not state.ring.is_empty()
	_bar.max_value = maxf(float(state.ring.size()), 1.0)
	_bar.value = met
	_come.visible = _bar.visible
	_come.text = RING_COME % [met, state.ring.size()]
	_pays.add_child(_paid_row(RING_PAYS, IconShapes.star.bind(0.5, 0.5, 0.6, HouseTheme.FOIL)))
	_edition.visible = state.owed > 0
	_edition.text = EDITION % state.owed
	_show_pin(profile)


## How far a ring's bet has come in words, done once it is: so its count is not said twice.
static func _so_far(profile: Profile, bet: Dictionary) -> String:
	var come := Loyalty.ring_progress(profile, bet)
	if come.x >= come.y:
		return WON.to_lower()
	return Loyalty.ring_progress_text(profile, bet).get_slice(" / ", 0) + " so far"


func _clear_rows() -> void:
	for container: Container in [_pays, _ring]:
		for row: Node in container.get_children():
			(row as Control).hide()
			row.queue_free()


## The Pin button for what the pane says, where it may be pinned, pressed while it is.
func _show_pin(profile: Profile) -> void:
	pin.visible = Loyalty.can_pin(profile, shown)
	var pinned := profile.loyalty.pinned == shown
	pin.set_pressed_no_signal(pinned)
	pin.text = PINNED if pinned else PIN
	# The same key chooses an edition while one is owed, so it pins nothing then.
	if _edition.visible:
		pin.remove_meta(&"bind_action")
	else:
		ButtonBinds.mark(pin, PIN_ACTION)


## The pane's buttons that have a bind, for [method ButtonBinds.show]: pinning, and choosing an
## edition, whichever the key does now.
func bound() -> Array[Button]:
	return [pin, _edition]


## Fills the pane for [param landmark] on [param profile]'s map.
func show_landmark(profile: Profile, landmark: LoyaltyLandmark) -> void:
	shown = landmark.id
	_edition.visible = false
	for row: Node in _ring.get_children():
		(row as Control).hide()
		row.queue_free()
	var stands := Loyalty.standing(profile, landmark)
	_name.text = landmark.title
	var district: Array = DISTRICTS.get(landmark.district, DISTRICTS[LoyaltyLandmark.District.SLIP])
	_district.text = str(district[0]).to_upper()
	_district.add_theme_color_override("font_color", district[1])
	_style.frame = Color(district[1], JokerDetail.FRAME)
	_style.frame_body = Color(district[1], JokerDetail.FRAME_BODY)
	_style.engraving = Color(district[1], JokerDetail.ENGRAVED)
	var said: String = [CLOSED, OPEN, WON][stands]
	_standing.text = (said + "  ·  " + KEYSTONE if landmark.keystone else said).to_upper()
	var closed := stands == Loyalty.Standing.CLOSED
	_bet.text = ASKS_LATER if closed else Loyalty.bet_of(landmark)
	_bet.add_theme_color_override("font_color", HINT if closed else HouseTheme.WORDS)
	var come := Loyalty.progress(profile, landmark)
	_bar.visible = not closed and come.y > 0.0
	_bar.max_value = maxf(come.y, 1.0)
	_bar.value = come.y if stands == Loyalty.Standing.WON else come.x
	_come.text = Loyalty.progress_text(profile, landmark)
	_show_pin(profile)
	_come.visible = _bar.visible
	_opens.text = opens_by(profile, landmark) if closed else ""
	_opens.visible = closed and not _opens.text.is_empty()
	# Left in the tree to go with it, hidden, so nothing is left belonging to nothing.
	for row: Node in _pays.get_children():
		(row as Control).hide()
		row.queue_free()
	for paid: Array in pays_of(landmark):
		_pays.add_child(_paid_row(paid[0], paid[1]))


## Which roads would open [param landmark], closed on [param profile]'s map, in words: any road in
## from the landmarks it is joined to, or for a keystone every one of them.
static func opens_by(profile: Profile, landmark: LoyaltyLandmark) -> String:
	var map := Loyalty.map()
	var names := PackedStringArray()
	for id: StringName in map.roads_of(landmark.id):
		var other := map.landmark(id)
		if other != null and Loyalty.is_drawn(profile, other):
			if not (landmark.keystone and profile.loyalty.has_won(id)):
				names.append(other.title)
	if names.is_empty():
		return ""
	if landmark.keystone:
		return OPENS_BY_ALL % _listed(names, AND)
	return OPENS_BY % _listed(names, OR)


## What [param landmark] pays, a line each with the way to draw its picture: the cards it adds and
## the items, its part of the dress and any more, the Showroom, a loose note.
static func pays_of(landmark: LoyaltyLandmark) -> Array[Array]:
	var paid: Array[Array] = []
	for id: StringName in landmark.jokers:
		var joker := CATALOG.by_id(id)
		var named := joker.display_name if joker != null else String(id)
		paid.append([CARD % named, JokerArt.draw_into.bind(id, Color.WHITE)])
	for id: StringName in landmark.items:
		paid.append([ITEM % _item_name(id), PowerUpArt.draw_into.bind(id, Color.WHITE)])
	var dress: Array[String] = []
	if landmark.dress_part != &"":
		dress.append("%s:%s" % [landmark.dress_part, landmark.dress])
	dress.append_array(landmark.also)
	for piece: String in dress:
		var part := StringName(piece.get_slice(":", 0))
		var words := "%s: %s" % [PARTS.get(part, String(part)), piece.get_slice(":", 1)]
		paid.append([words, DressArt.draw_into.bind(LoyaltyArt.PARTS.get(part, 0), Color.WHITE)])
	if landmark.showroom:
		paid.append([SHOWROOM, LoyaltyArt.roller_door.bind(Color.WHITE)])
	if landmark.note != &"":
		paid.append([NOTE, LoyaltyArt.scrap.bind(Color.WHITE)])
	if landmark.kind == LoyaltyLandmark.Kind.CARD:
		paid.append(
			[ONTO_THE_MAP, DressArt.draw_into.bind(LoyaltyArt.PARTS[&"card_back"], Color.WHITE)]
		)
	return paid


static func _item_name(id: StringName) -> String:
	for item: PowerUp in FIRST.entries + LATER.entries:
		if item.id == id:
			return item.display_name
	return String(id)


## [param names] as a list in words, the last two joined by [param last].
static func _listed(names: PackedStringArray, last: String) -> String:
	if names.size() <= 1:
		return "".join(names)
	return ", ".join(names.slice(0, names.size() - 1)) + last + names[-1]


func _paid_row(words: String, draw_with: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var picture := Picture.new()
	picture.draw_with = draw_with
	picture.custom_minimum_size = Vector2.ONE * PICTURE
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(picture)
	var line := _line(18, HouseTheme.WORDS)
	line.text = words
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(line)
	return row


func _line(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
