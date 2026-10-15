class_name KartDialog
extends CanvasLayer
## The kart dialog, GAME.md 4.4a: the seat's own kart on the floor of the Garage's bay between the
## posts of its lift, big, to be dressed; a pegboard either side with a hook for each part of it,
## the piece worn hanging there over its painted outline and its name on tape, see [PartHook]; and
## the name, the color and the plate on the workbench at the foot. A dialog over whatever opens it:
## the Garage's lift and the pause menu in the Garage and the lobby, the kart wearing a change at
## once there and on every screen; and the title's Clubhouse, out of any room. Framed in steel while
## there is room round it, see [method BoardArt.draw_frame].
##
## A tab for each whose kart it dresses, see [KartOwner]: in a room each seat at this machine, out
## of one the profile playing, and after them every other profile kept here, each a key on the
## bay's key board, turned by the page keys or a click. A hook pressed hangs the rack of its part
## over the bench, a pegboard with every piece of it on a clip, the part's None or plain one first,
## then those won, then those not won yet, saying where they are won, GAME.md 8.9, see [PartTray];
## the mouse over a piece has the kart try it on for as long as it is there, and so does the cursor
## on one, pressed it is worn, and Close or Back puts the rack away. A hook looked at, its rack out
## or the cursor or the mouse on it, has a rope from it to its part on the kart, and has the kart
## turned quickly to where that part is best seen, see [method KartStage.view]. The shuffle's plate
## by the hooks, a big red push button, puts a piece of every part on at random, of those won, and
## a color at random. The color is a spray can on the bench, tried on while the mouse or the cursor
## is on it and kept when pressed, a paint chip card by the cans saying which; the name is written
## on masking tape, or rolled on the die at its end, and the plate is typed straight onto the plate,
## once there is a license for it.
##
## The kart turns by dragging it or by the right stick, which the binds over the bench's end show
## for the device in hand, sways where it stands when let go, and now and then does something
## nobody asked it to, see [KartStage]. Dressed as an old workshop rather than a showroom, see
## [BayArt].

## Put away, the cursor back where it was.
signal put_away

## Over a room's pause menu, with the other dialogs.
const LAYER := PauseMenu.LAYER + 5
## What the buttons that open it are called, on the title's Clubhouse and in the pause menu.
const ENTRY := "Your kart"
const SHADE := Color(0.0, 0.0, 0.0, 0.55)
const BACK := "Back"
const BACK_PRINTED := "BACK"
## The card back's part, past the kart's own parts, and the shuffle's hook past that.
const CARD_BACK := 6
const SHUFFLE := BoardArt.SHUFFLE
## What the bench says by the plate for a seat that cannot change its own.
const GUEST_PLATE := "of %s"
const DIE_TIP := "A name the house makes up"
## How far the right stick has to go before it turns the kart.
const STICK_DEAD := 0.25
## What presses the shuffle's push button from the keys or a pad, as the catalog's option is.
const SHUFFLE_ACTION := InputActions.MENU_OPTION
## The hooks down the left board and down the right, top to bottom, for the cursor's way between
## them.
const LEFT_HOOKS: Array[int] = [2, 4, 3, CARD_BACK]
const RIGHT_HOOKS: Array[int] = [1, 0, 5, SHUFFLE]

## Whose karts it dresses, a tab each, and the one it is on.
var owners: Array[KartOwner] = []
var current := 0
## The part whose tray is open, or -1.
var open_part := -1
var stage: KartStage
## A hook for each part, by the part, the card back's and the shuffle's after them.
var hooks: Array[PartHook] = []
var keys: Array[KeyTag] = []
var cans: Array[PaintCan] = []
var name_box: LineEdit
var die: NameDie
var plate_field: PlateField
var plate_note: Label
var back: Button
var tray: PartTray

var _room: Match
var _root: Control
var _shade: ColorRect
var _around: MarginContainer
var _pane: PanelContainer
var _bay: Control
var _cover: BayCover
## The bay built in 3D as the kart is filmed in it, under the cover's pegboards and bench, see
## [member KartStage.film].
var _backdrop: Control
var _stage_node: Control
## The hand of cards held up over the kart while the card back is looked at.
var _fan: CardFan
var _twine: Control
var _rail: KeyRail
var _page_hint: Control
var _turn_hint: Control
## The key or pad button that presses what the cursor is on, under it.
var _press_bind: Control
var _chip: Control
var _plate_shown: LicensePlate
## The learner's L where the plate goes before a license, see [method BayControls.learner_plate].
var _learner: Control
var _from: Control
var _closing := false
var _keyboard := true
var _pointer := false
## What the kart wears as its owner has it, the piece the cursor is trying on, and the name in the
## box as it was last kept.
var _style: KartStyle
var _name_shown := ""
var _rng := RandomNumberGenerator.new()
## The hook the cursor rests on without it being looked at, until it is moved: the one it starts
## on, and the card back's once its rack is put back, see [method _rest_on].
var _resting_on: Control
## The can the mouse is over, the one the cursor is on, and the color the kart is trying on from
## them, -1 for none.
var _can_over := -1
var _can_on := -1
var _color_tried := -1
## The card back the cursor or the mouse is on in its rack, held up in the kart's hand, or -1.
var _back_tried := -1


## The dialog over [param parent], for the karts at this machine in [param room] or out of one, on
## the tab of [param seat], with the cursor on its flag, the top left hook.
static func open(parent: Node, room: Match = null, seat := 0) -> KartDialog:
	var dialog := KartDialog.new()
	dialog.name = "KartDialog"
	dialog._room = room
	dialog.owners = KartOwner.everybody(room)
	for i: int in dialog.owners.size():
		if dialog.owners[i].seat == seat:
			dialog.current = i
			break
	if parent.is_inside_tree():
		dialog._from = parent.get_viewport().gui_get_focus_owner()
	parent.add_child(dialog)
	return dialog


## Every choice of [param part], the card back's past the kart's own.
static func choices_of(part: int) -> Array[String]:
	var found: Array[String] = []
	found.assign(CardBack.STYLES if part == CARD_BACK else KartStyle.CHOICES[part])
	return found


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	# A finger on it is its own, on the kart turning it wherever the dialog was opened from: the
	# lists and the touch controls under it leave the touches to it.
	TouchInput.keep_touches(self)
	_rng.randomize()
	_keyboard = Game.last_input_keyboard
	_pointer = Game.last_input_pointer
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_shade = ColorRect.new()
	_shade.name = "Shade"
	_shade.color = SHADE
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_shade.gui_input.connect(_on_shade_input)
	_root.add_child(_shade)
	_around = MarginContainer.new()
	_around.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_around.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_around)
	_pane = PanelContainer.new()
	_pane.name = "Pane"
	_pane.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_pane.mouse_filter = Control.MOUSE_FILTER_STOP
	# The grain of the bay and the patterns of the paints are tiles, laid over and over.
	_pane.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_around.add_child(_pane)
	_bay = Control.new()
	_bay.name = "Bay"
	_bay.clip_contents = true
	_bay.mouse_filter = Control.MOUSE_FILTER_PASS
	_backdrop = Control.new()
	_backdrop.name = "Backdrop"
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop.draw.connect(_draw_backdrop)
	_pane.add_child(_backdrop)
	_cover = BayCover.new()
	_cover.name = "Cover"
	_pane.add_child(_cover)
	_pane.add_child(_bay)
	_stage_node = Control.new()
	_stage_node.name = "Stage"
	_stage_node.size = BayArt.STAGE
	_stage_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bay.add_child(_stage_node)
	stage = KartStage.new()
	stage.name = "Kart"
	stage.position = BayArt.VIEW.position
	stage.size = BayArt.VIEW.size
	_stage_node.add_child(stage)
	_fan = CardFan.new()
	_fan.name = "Cards"
	_stage_node.add_child(_fan)
	for part: int in SHUFFLE + 1:
		var hook := PartHook.make(part)
		hook.pressed.connect(_on_hook.bind(part))
		_stage_node.add_child(hook)
		hooks.append(hook)
	_twine = Control.new()
	_twine.name = "Twine"
	_twine.size = BayArt.STAGE
	_twine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_twine.draw.connect(_draw_twine)
	_stage_node.add_child(_twine)
	_build_bench()
	_build_keys()
	tray = PartTray.new()
	tray.name = "Tray"
	tray.visible = false
	tray.tried.connect(_try)
	tray.left.connect(_untry)
	tray.chosen.connect(_choose)
	tray.done.connect(close_tray)
	var well := PartTray.well()
	_stage_node.add_child(well)
	well.add_child(tray)
	back = BayControls.back_plate(BACK_PRINTED, BACK)
	back.pressed.connect(close)
	ButtonBinds.mark(back, &"ui_cancel")
	ButtonBinds.mark(hooks[SHUFFLE], SHUFFLE_ACTION)
	_stage_node.add_child(back)
	_show_binds()
	_link_cursor()
	_root.resized.connect(_fit_screen)
	_bay.resized.connect(_fit)
	_fit_screen()
	show_owner(current)
	MenuTheme.deal(_pane)
	_focus_first.call_deferred()
	Input.joy_connection_changed.connect(_on_pad_plugged)
	get_viewport().gui_focus_changed.connect(func(_control: Control) -> void: _show_press_bind())


func _exit_tree() -> void:
	PlayerInput.typing = false
	if Input.joy_connection_changed.is_connected(_on_pad_plugged):
		Input.joy_connection_changed.disconnect(_on_pad_plugged)


## The bench's things: the name box over its tape and the die at its end, a can of each color and
## the paint chip card by them, and the plate.
func _build_bench() -> void:
	name_box = LineEdit.new()
	name_box.name = "Name"
	name_box.position = BayArt.NAME_TAPE.position
	name_box.size = BayArt.NAME_TAPE.size
	name_box.max_length = PlayerNames.MAX_LENGTH
	name_box.select_all_on_focus = true
	name_box.add_theme_font_override("font", BayArt.marker_font())
	name_box.add_theme_font_size_override("font_size", 28)
	name_box.add_theme_color_override("font_color", BayArt.MARKER)
	name_box.add_theme_color_override("font_placeholder_color", Color(BayArt.MARKER, 0.38))
	name_box.add_theme_color_override("caret_color", BayArt.MARKER)
	name_box.add_theme_color_override("selection_color", Color(HouseTheme.FOIL, 0.45))
	# Clear of the die at the tape's right end.
	var room_for_die := BayArt.NAME_TAPE.end.x - BayArt.DIE.position.x + 8.0
	for look: StringName in [&"normal", &"read_only", &"focus"]:
		var box: StyleBox = FocusGlide.look() if look == &"focus" else StyleBoxEmpty.new()
		box.content_margin_left = 18.0
		box.content_margin_right = room_for_die
		name_box.add_theme_stylebox_override(look, box)
	name_box.add_to_group(FocusGlide.GROUP)
	name_box.text_submitted.connect(func(_typed: String) -> void: _keep_name())
	name_box.focus_entered.connect(_typing.bind(true))
	name_box.focus_exited.connect(
		func() -> void:
			_typing(false)
			_keep_name()
	)
	_stage_node.add_child(name_box)
	die = NameDie.new()
	die.name = "Die"
	die.position = BayArt.DIE.position
	die.size = BayArt.DIE.size
	die.tooltip_text = DIE_TIP
	die.pressed.connect(roll_name)
	_stage_node.add_child(die)
	for color: int in Palette.PLAYER_COLORS.size():
		var can := PaintCan.make(color)
		can.pressed.connect(pick_color.bind(color))
		can.mouse_entered.connect(_over_can.bind(color, true))
		can.mouse_exited.connect(_over_can.bind(color, false))
		can.focus_entered.connect(_on_can.bind(color, true))
		can.focus_exited.connect(_on_can.bind(color, false))
		_stage_node.add_child(can)
		cans.append(can)
	_chip = Control.new()
	_chip.name = "ColorChip"
	_chip.position = BayArt.CHIP.position
	_chip.size = BayArt.CHIP.size
	_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chip.draw.connect(_draw_chip)
	_stage_node.add_child(_chip)
	plate_field = PlateField.make("", BayArt.PLATE_WIDE)
	plate_field.name = "Plate"
	plate_field.position = BayArt.PLATE_AT
	plate_field.plate_changed.connect(_on_plate_typed)
	plate_field.focus_entered.connect(_typing.bind(true))
	plate_field.focus_exited.connect(_typing.bind(false))
	_stage_node.add_child(plate_field)
	_plate_shown = LicensePlate.of("", BayArt.PLATE_WIDE)
	_plate_shown.name = "PlateShown"
	_plate_shown.position = BayArt.PLATE_AT
	_plate_shown.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage_node.add_child(_plate_shown)
	_learner = BayControls.learner_plate()
	_learner.position = BayArt.PLATE_AT + Vector2(BayArt.PLATE_WIDE - _learner.size.x, 0.0) * 0.5
	_stage_node.add_child(_learner)
	# On the bench, after the word PLATE over it: whose it is, or what it comes with.
	plate_note = Label.new()
	plate_note.name = "PlateNote"
	plate_note.position = BayArt.PLATE_AT + Vector2(48.0, -24.0)
	plate_note.size = Vector2(BayArt.PLATE_WIDE - 48.0, 20.0)
	plate_note.clip_text = true
	plate_note.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	Type.strong(plate_note, 12, BayArt.WORDS_ON_WALL)
	_stage_node.add_child(plate_note)


## A key on the key board for each whose kart it dresses, see [KeyRail].
func _build_keys() -> void:
	_rail = KeyRail.new()
	_rail.name = "Keys"
	_rail.position = Vector2(BayArt.KEYS_FROM - KeyRail.LEAD, BayArt.RAIL.position.y)
	_rail.size = Vector2(BayArt.RAIL.end.x - _rail.position.x, BayArt.RAIL.size.y + KeyRail.DEEP)
	_rail.picked.connect(show_owner)
	_stage_node.add_child(_rail)
	for i: int in owners.size():
		var key := KeyTag.make(owners[i], i)
		_rail.add_key(key)
		keys.append(key)


## The cursor's ways between the hooks up and down either board, across the kart between them, and
## up to Back from the top hooks; the ways onto the bench are its own, see [method _link_bench].
func _link_cursor() -> void:
	for i: int in LEFT_HOOKS.size():
		var left := hooks[LEFT_HOOKS[i]]
		var right := hooks[RIGHT_HOOKS[i]]
		_way(left, SIDE_RIGHT, right)
		_way(left, SIDE_LEFT, left)
		_way(right, SIDE_LEFT, left)
		_way(right, SIDE_RIGHT, right)
	for column: Array[int] in [LEFT_HOOKS, RIGHT_HOOKS]:
		for i: int in column.size():
			_way(hooks[column[i]], SIDE_TOP, hooks[column[i - 1]] if i > 0 else back)
			if i + 1 < column.size():
				_way(hooks[column[i]], SIDE_BOTTOM, hooks[column[i + 1]])
	_way(back, SIDE_BOTTOM, hooks[RIGHT_HOOKS[0]])
	_way(back, SIDE_LEFT, hooks[LEFT_HOOKS[0]])
	_way(back, SIDE_RIGHT, back)
	_way(back, SIDE_TOP, back)


## [param from]'s way to [param side] leads to [param to].
func _way(from: Control, side: Side, to: Control) -> void:
	var path := from.get_path_to(to)
	match side:
		SIDE_LEFT:
			from.focus_neighbor_left = path
		SIDE_RIGHT:
			from.focus_neighbor_right = path
		SIDE_TOP:
			from.focus_neighbor_top = path
		SIDE_BOTTOM:
			from.focus_neighbor_bottom = path


## The bench's ways, as it is now: two rows of it, the cans over the name, its die and the plate
## where it can be typed into. Along each row, the cans on out to the bottom hooks either side;
## down from every can to the name, up from the name to the first can and from the die to the
## last; down to the cans from the bottom of the left board, the card back's hook or the trail's
## where there is no card back here, and between the shuffle's plate and the plate, or the last
## can where there is no plate to type.
func _link_bench() -> void:
	var card_back := hooks[CARD_BACK]
	var trail := hooks[LEFT_HOOKS[-2]]
	var shuffle := hooks[SHUFFLE]
	var bottom_left := card_back if card_back.visible else trail
	var typed := plate_field.visible
	for i: int in cans.size():
		_way(cans[i], SIDE_LEFT, cans[i - 1] if i > 0 else bottom_left)
		_way(cans[i], SIDE_RIGHT, cans[i + 1] if i + 1 < cans.size() else shuffle)
		_way(cans[i], SIDE_TOP, bottom_left if i * 2 < cans.size() else shuffle)
		_way(cans[i], SIDE_BOTTOM, name_box)
	_way(name_box, SIDE_LEFT, name_box)
	_way(name_box, SIDE_RIGHT, die)
	_way(name_box, SIDE_TOP, cans[0])
	_way(name_box, SIDE_BOTTOM, name_box)
	_way(die, SIDE_LEFT, name_box)
	_way(die, SIDE_RIGHT, plate_field if typed else shuffle)
	_way(die, SIDE_TOP, cans[-1])
	_way(die, SIDE_BOTTOM, die)
	_way(plate_field, SIDE_LEFT, die)
	_way(plate_field, SIDE_RIGHT, plate_field)
	_way(plate_field, SIDE_TOP, shuffle)
	_way(plate_field, SIDE_BOTTOM, plate_field)
	_way(trail, SIDE_BOTTOM, card_back if card_back.visible else cans[0])
	_way(card_back, SIDE_BOTTOM, cans[0])
	_way(shuffle, SIDE_LEFT, bottom_left)
	_way(shuffle, SIDE_BOTTOM, plate_field if typed else cans[-1])


## The pane over nearly all the screen, or all of it short of room, see
## [method CatalogDialog.fill_screen].
func _fit_screen() -> void:
	CatalogDialog.fill_screen(_pane, _around, _root.size)


## The stage as big as the bay has room for, in its middle, the wall and the floor running on to
## the bay's edges round it; inside the dialog's frame while there is room round the dialog for
## the frame, and from edge to edge of a short screen, as a phone's.
func _fit() -> void:
	var room := _bay.size
	if room.x <= 0.0 or room.y <= 0.0:
		return
	var framed := _root.size.y >= CatalogDialog.SHORT
	var inside := Rect2(Vector2.ZERO, room).grow(-BoardArt.EDGE if framed else 0.0)
	var by := minf(inside.size.x / BayArt.STAGE.x, inside.size.y / BayArt.STAGE.y)
	var place := (inside.position + (inside.size - BayArt.STAGE * by) * 0.5).round()
	_stage_node.scale = Vector2.ONE * by
	_stage_node.position = place
	_cover.place(place, by, framed)
	if tray != null:
		tray.warm()
	stage.film = Rect2((inside.position - place) / by, inside.size / by)
	_backdrop.queue_redraw()


## The bay built in 3D, filmed over the whole of the bay inside the frame, see [member _backdrop].
func _draw_backdrop() -> void:
	_backdrop.draw_set_transform(_stage_node.position, 0.0, _stage_node.scale)
	_backdrop.draw_texture_rect(stage.picture(), stage.film, false)


# --- whose kart ----------------------------------------------------------------------------------


## The tab of [param index] up: its kart, its hooks, its bench.
func show_owner(index: int) -> void:
	if index < 0 or index >= owners.size():
		return
	if index != current:
		_keep_name()
		if open_part >= 0:
			close_tray(false)
	current = index
	_color_tried = -1
	var owner := owners[current]
	for i: int in keys.size():
		keys[i].set_here(i == current)
	# Scrolled to it at once as the dialog opens, before it shows any kart.
	_rail.follow(current, _style == null)
	_style = owner.style()
	name_box.text = owner.given_name()
	_name_shown = name_box.text
	name_box.placeholder_text = owner.display_name() if name_box.text.is_empty() else ""
	hooks[CARD_BACK].visible = owner.has_card_back()
	_show_dress()
	_show_color()
	_show_plate()
	_link_bench()
	_try_color()
	if open_part >= 0:
		open_tray(open_part)


## Turns [param step] tabs on, round at the ends.
func switch_owner(step: int) -> void:
	if owners.size() > 1:
		show_owner(posmod(current + step, owners.size()))
		Audio.play_sfx(&"page", -8.0, 0.05)


func kart_owner() -> KartOwner:
	return owners[current]


## The color its kart is shown in: its own, or for one with no favorite yet its seat's place.
func shown_color() -> int:
	var picked := kart_owner().color()
	var seat := maxi(kart_owner().seat, 0)
	return picked if picked >= 0 else posmod(seat, Palette.PLAYER_COLORS.size())


## The color the kart on the floor is in just now: one being tried on from the cans, or its own.
func kart_color() -> int:
	return _color_tried if _color_tried >= 0 else shown_color()


func _show_dress() -> void:
	var owner_now := kart_owner()
	var color := Palette.player_color(shown_color())
	var worn := _style.to_array()
	for part: int in KartStyle.CHOICES.size():
		var index := worn[part]
		hooks[part].say(index, choices_of(part)[index], color, _style.finish(part))
	var back_now := owner_now.card_back()
	hooks[CARD_BACK].say(back_now, CardBack.STYLES[back_now], color, 0)
	stage.show_kart(_style, kart_color(), owner_now.plate())


func _show_color() -> void:
	var owner_now := kart_owner()
	var picked := owner_now.color()
	for can: PaintCan in cans:
		can.say(can.color == picked, owner_now.color_taker(can.color))
	_chip.queue_redraw()


## The paint chip card by the cans, see [method BayControls.draw_chip].
func _draw_chip() -> void:
	BayControls.draw_chip(_chip, kart_owner().color(), _color_tried)


func _show_plate() -> void:
	var owner_now := kart_owner()
	var typed := owner_now.has_plate()
	plate_field.visible = typed and open_part < 0
	_plate_shown.visible = not typed and open_part < 0 and owner_now.plate() != "L"
	_learner.visible = not typed and open_part < 0 and owner_now.plate() == "L"
	# Whose plate a guest wears; the learner's L says itself.
	plate_note.visible = _plate_shown.visible and owner_now.is_guest()
	plate_note.text = GUEST_PLATE % Game.settings.profile.display_name()
	if typed:
		plate_field.text = owner_now.plate()
	else:
		_plate_shown.set_text(owner_now.plate())


# --- the tray ------------------------------------------------------------------------------------


## A hook pressed: its part's tray set down on the bench, or put back if it is out already; the
## shuffle's puts a piece of every part on at random.
func _on_hook(part: int) -> void:
	if part == SHUFFLE:
		shuffle()
	else:
		open_tray(part)


## The tray of [param part] set down on the bench, the cursor on the piece worn; pressed again, its
## hook puts it back.
func open_tray(part: int) -> void:
	if part == open_part and tray.is_out() and tray.part == part:
		close_tray()
		return
	open_part = part
	var owner_now := kart_owner()
	var worn := owner_now.card_back() if part == CARD_BACK else _style.to_array()[part]
	tray.fill(part, owner_now, worn, Palette.player_color(shown_color()))
	tray.slide_in()
	_bench_shown(false)
	for i: int in hooks.size():
		hooks[i].set_lit(i == part)
	for cell: PartTray.TrayCell in tray.cells:
		_way(cell, SIDE_TOP, hooks[part])
		_way(cell, SIDE_BOTTOM, cell)
	var landing := tray.cell_at(worn)
	if not tray.cells.is_empty():
		_way(tray.cells[0], SIDE_LEFT, tray.cells[0])
		_way(tray.cells[-1], SIDE_RIGHT, tray.cells[-1])
		# Down off the bottom of either board onto the rack, while it is out over the bench.
		var onto: Control = landing if landing != null else tray.cells[0]
		var card_back := hooks[CARD_BACK]
		_way(card_back if card_back.visible else hooks[LEFT_HOOKS[-2]], SIDE_BOTTOM, onto)
		_way(hooks[SHUFFLE], SIDE_BOTTOM, onto)
	if landing != null:
		landing.grab_focus.call_deferred()
	Audio.play_sfx(&"ui_click", -6.0, 0.05)


## The tray put back, the kart in what it wears again and the cursor on the hook, unless
## [param refocus] says otherwise: the card back's hand of cards put down with its rack.
func close_tray(refocus := true) -> void:
	if open_part < 0:
		return
	var part := open_part
	open_part = -1
	_back_tried = -1
	tray.slide_out()
	for hook: PartHook in hooks:
		hook.set_lit(false)
	_bench_shown(true)
	_link_bench()
	stage.show_kart(_style, kart_color(), kart_owner().plate())
	if refocus and part == CARD_BACK:
		_rest_on(hooks[part])
	elif refocus:
		hooks[part].grab_focus()


func _bench_shown(on: bool) -> void:
	name_box.visible = on
	die.visible = on
	_chip.visible = on
	if _turn_hint != null:
		_turn_hint.visible = on
	for can: PaintCan in cans:
		can.visible = on
	_show_plate()
	_show_button_binds()


## The cursor or the mouse on [param index] of the open tray: the kart tries it on, or for one not
## won stays as it is.
func _try(index: int) -> void:
	if open_part < 0:
		return
	var owner_now := kart_owner()
	if open_part == CARD_BACK:
		_back_tried = index if owner_now.owns(CARD_BACK, index) else -1
		return
	if owner_now.owns(open_part, index):
		stage.show_kart(owner_now.trying(_style, open_part, index), kart_color(), owner_now.plate())
	else:
		stage.show_kart(_style, kart_color(), owner_now.plate())


## The mouse gone off a piece of the open tray: the kart in what it wears again.
func _untry(_index: int) -> void:
	_back_tried = -1
	if open_part >= 0:
		stage.show_kart(_style, kart_color(), kart_owner().plate())


## [param index] of the open tray worn, and the kart cheers; one not won only says it is not.
func _choose(index: int) -> void:
	if open_part < 0:
		return
	var owner_now := kart_owner()
	var part := open_part
	var done := owner_now.turn_back(index) if part == CARD_BACK else owner_now.wear(part, index)
	if not done:
		Audio.play_sfx(&"ui_back", -4.0, 0.05)
		return
	Audio.play_sfx(&"stamp", -6.0, 0.05)
	_style = owner_now.style()
	tray.wear(index)
	_show_dress()
	stage.show_kart(_style, kart_color(), owner_now.plate(), true)


## A piece of every part on the tab up's kart at random, of those it has won, a card back where it
## has its own, and a color nobody else in the room is in, another than its own where there is one;
## the kart does a donut in it, and its push button rolls, pressed or by its key.
func shuffle() -> void:
	hooks[SHUFFLE].roll()
	var owner_now := kart_owner()
	var values := PackedInt32Array()
	for part: int in KartStyle.CHOICES.size():
		values.append(owner_now.any_piece(part, _rng))
	owner_now.dress(values)
	if owner_now.has_card_back():
		owner_now.turn_back(owner_now.any_piece(CARD_BACK, _rng))
	var color := owner_now.any_color(_rng)
	if color >= 0 and owner_now.recolor(color):
		keys[current].say(owner_now)
		_color_tried = -1
		_show_color()
	Audio.play_sfx(&"stamp", -6.0, 0.05)
	_style = owner_now.style()
	_show_dress()
	stage.perform(KartStage.Move.DONUT)
	if open_part >= 0:
		open_tray(open_part)


## Wears [param index] of [param part] for the tab up, as the tray does, for tests and tools.
func wear(part: int, index: int) -> bool:
	open_tray(part)
	var before := _style.to_array()
	_choose(index)
	return _style.to_array() != before or part == CARD_BACK


# --- the bench -----------------------------------------------------------------------------------


## [param color] for the tab up, if nobody else in the room is in it.
func pick_color(color: int) -> void:
	if not kart_owner().recolor(color):
		Audio.play_sfx(&"ui_back", -4.0, 0.05)
		return
	Audio.play_sfx(&"ui_click", -6.0, 0.05)
	keys[current].say(kart_owner())
	_color_tried = -1
	_show_color()
	_show_dress()
	stage.play(KartStage.Move.SPIN)


## The mouse gone over [param color]'s can, for [param on], or off it.
func _over_can(color: int, on: bool) -> void:
	if on:
		_can_over = color
	elif _can_over == color:
		_can_over = -1
	_try_color()


## The cursor come to [param color]'s can, for [param on], or gone from it.
func _on_can(color: int, on: bool) -> void:
	if on:
		_can_on = color
	elif _can_on == color:
		_can_on = -1
	_try_color()


## The kart in the color of the can the mouse is over, or else of the one the cursor is on, for as
## long as it is there, and in its own again once neither is: tried on, kept only when pressed. A
## can somebody else in the room is in is not tried on.
func _try_color() -> void:
	var tried := _can_over if _can_over >= 0 else _can_on
	var owner_now := kart_owner()
	if tried == owner_now.color() or tried >= 0 and not owner_now.color_free(tried):
		tried = -1
	if tried == _color_tried:
		return
	_color_tried = tried
	stage.show_kart(_style, kart_color(), owner_now.plate())
	_chip.queue_redraw()


## A name the house makes up for the tab up, none the other tabs go by, written on the tape.
func roll_name() -> void:
	var taken: Array[String] = []
	for each: KartOwner in owners:
		taken.append(each.display_name())
	name_box.text = PlayerNames.pick(_rng, taken)
	_keep_name()
	Audio.play_sfx(&"ui_click", -6.0, 0.05)


## The name in the box kept, if it is not the one it showed.
func _keep_name() -> void:
	if name_box == null or name_box.text == _name_shown:
		return
	_name_shown = name_box.text
	kart_owner().rename(name_box.text)
	keys[current].say(kart_owner())
	name_box.placeholder_text = kart_owner().display_name() if name_box.text.is_empty() else ""


func _on_plate_typed(cleaned: String) -> void:
	kart_owner().replate(cleaned)
	stage.show_kart(_style, kart_color(), kart_owner().plate())


# --- input, the twine, coming and going ----------------------------------------------------------


func _process(delta: float) -> void:
	var stick := 0.0
	for pad: int in Input.get_connected_joypads():
		stick += Input.get_joy_axis(pad, JOY_AXIS_RIGHT_X)
	if absf(stick) > STICK_DEAD:
		var pushed := (absf(stick) - STICK_DEAD) / (1.0 - STICK_DEAD)
		stage.turn(signf(stick) * pushed * KartStage.STICK_TURN * delta)
	var looked := _part_looked_at()
	stage.view(looked)
	# The card back held up in a hand of cards, the one tried on or the one worn; and the kart left
	# to do things by itself but while a rack is out.
	if looked == CARD_BACK:
		_fan.hold(_back_tried if _back_tried >= 0 else kart_owner().card_back())
	else:
		_fan.put_down()
	stage.restless = open_part < 0
	# How to turn it, only while it can be, not off on its laps.
	if _turn_hint != null:
		_turn_hint.visible = open_part < 0 and stage.can_turn()
	_twine.queue_redraw()


## The part the kart is shown for: the one whose tray is out, or whose hook the cursor is on, the
## card back's with a hand of cards held up, see [CardFan]; none for the shuffle's, nor for the
## hook the cursor rests on, see [method _rest_on], so the dialog opens on the kart standing.
func _part_looked_at() -> int:
	if open_part >= 0:
		return open_part
	var hook := get_viewport().gui_get_focus_owner() as PartHook
	if hook != null and hook.part <= CARD_BACK and hook != _resting_on:
		return hook.part
	return -1


## The parts with a rope to the kart now: those whose hook is looked at, see
## [method PartHook.looked_at], but for the hook the cursor rests on; the card back's to its cards.
func roped_parts() -> Array[int]:
	var found: Array[int] = []
	for part: int in CARD_BACK + 1:
		var hook := hooks[part]
		if not hook.visible:
			continue
		if hook.looked_at() and (hook != _resting_on or hook.is_hovered()):
			found.append(part)
	return found


## Whether the bay is in its frame, the dialog leaving room round it.
func is_framed() -> bool:
	return _cover.framed


## A rope from each hook looked at to its part on the kart, see [method roped_parts]: gold from the
## one whose tray is out or the cursor is on, twine from the one the mouse is over.
func _draw_twine() -> void:
	for part: int in roped_parts():
		var hook := hooks[part]
		var to := stage.anchor(part)
		if part == CARD_BACK:
			to = _fan.anchor() if _fan.is_held() else KartStage.NO_ANCHOR
		if to == KartStage.NO_ANCHOR:
			continue
		var lit := part == open_part or hook.has_focus()
		BayArt.draw_twine(
			_twine, BoardArt.eye_of(part), to, HouseTheme.FOIL if lit else BayArt.TWINE
		)


## The dialogs' keys, see [DialogBinds]: WASD moves the cursor, the page keys turn the tabs and
## the option key shuffles, except while a box is being typed into.
func _input(event: InputEvent) -> void:
	var keyboard := LicenseView.keyboard_after(event, _keyboard)
	var pointer := ButtonBinds.pointer_after(event, _pointer)
	if keyboard != _keyboard or pointer != _pointer:
		_keyboard = keyboard
		_pointer = pointer
		_show_binds()
	if _closing or PlayerInput.typing:
		return
	if DialogBinds.moved_focus(event, get_viewport()):
		get_viewport().set_input_as_handled()
		return
	if event.is_echo():
		return
	if event.is_action_pressed(InputActions.MENU_PAGE_PREV):
		switch_owner(-1)
	elif event.is_action_pressed(InputActions.MENU_PAGE_NEXT):
		switch_owner(1)
	elif event.is_action_pressed(SHUFFLE_ACTION):
		shuffle()
	else:
		return
	get_viewport().set_input_as_handled()


## B on a pad, or Escape: the tray put back if it is out, and the dialog put away if not. Nothing
## gets past it to the screen under it.
func _unhandled_input(event: InputEvent) -> void:
	if _closing:
		return
	var viewport := get_viewport()
	if event.is_action_pressed(&"ui_cancel"):
		MenuTheme.back_sound()
		if open_part >= 0:
			close_tray()
		else:
			close()
	elif not (event is InputEventKey or event is InputEventJoypadButton):
		return
	viewport.set_input_as_handled()


func _on_shade_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	var touch := event as InputEventScreenTouch
	if (click != null and click.pressed) or (touch != null and touch.pressed):
		_shade.accept_event()
		close()


func _on_pad_plugged(_device: int, _connected: bool) -> void:
	_show_binds()


## The page keys' binds at the left end of the key board while keys are in hand or a pad is
## plugged in, none for the mouse alone; nor with one tab. And the binds that turn the kart, see
## [method _show_turn].
func _show_binds() -> void:
	_show_turn()
	_show_button_binds()
	if tray != null:
		var touch := TouchInput.enabled
		tray.show_binds(touch, _keyboard or not SettingsScreen.pad_plugged_in(), _pointer)
	if _page_hint != null:
		_page_hint.queue_free()
		_page_hint = null
	var pad := SettingsScreen.pad_plugged_in()
	var keys_in_hand := _keyboard and not _pointer
	# The rail's back sign beside them where they go, at its end without; none while a box is typed
	# into, their letters typed rather than turning the tabs.
	_rail.hinted = owners.size() > 1 and (keys_in_hand or pad) and not TouchInput.enabled
	if not _rail.hinted or PlayerInput.typing:
		return
	_page_hint = DialogBinds.pages(keys_in_hand, Color(1, 1, 1, 0.7), SettingsScreen.TAB_HINT_SIZE)
	_page_hint.name = "PageHint"
	_page_hint.position = Vector2(BayArt.RAIL.position.x + 6.0, BayArt.RAIL.end.y + 30.0)
	_stage_node.add_child(_page_hint)


## A box typed into, or no longer: the binds of the keys that are letters hidden while it is.
func _typing(on: bool) -> void:
	PlayerInput.typing = on
	_show_binds()


## Back's key or pad button hung under it, and the shuffle's under its push button, as the other
## dialogs' buttons have theirs, see [ButtonBinds]: while keys or a pad are in hand, none for the
## mouse and never on a touch screen.
func _show_button_binds() -> void:
	_show_press_bind()
	# Escape puts the rack away while it is out, and only puts the dialog away when it is not.
	ButtonBinds.show([back] as Array[Button], _keyboard, not _pointer and open_part < 0)
	ButtonBinds.show(
		[hooks[SHUFFLE]] as Array[Button], _keyboard, not _pointer and not PlayerInput.typing
	)
	BayControls.under_push(hooks[SHUFFLE])


## The key or pad button that presses what the cursor is on, Enter or A, hung under it as Back has
## its own: under the piece on a hook, which opens its part's rack, a can, the name's tape, the die
## and the plate; so a player with keys or a pad in hand sees what pressing it does there. Only
## under that one, none for the mouse and never on a touch screen.
func _show_press_bind() -> void:
	if _press_bind != null:
		_press_bind.queue_free()
		_press_bind = null
	if not is_inside_tree() or _closing or _pointer or TouchInput.enabled:
		return
	var on := get_viewport().gui_get_focus_owner()
	var edge := Vector2(-1.0, -1.0)
	var hook := on as PartHook
	if hook != null and hook.part <= CARD_BACK:
		var outline := BoardArt.outline_of(hook.part)
		edge = Vector2(outline.get_center().x, outline.end.y)
	elif on is PaintCan and not (on as PaintCan).disabled or on in [name_box, die, plate_field]:
		var rect := (on as Control).get_rect()
		edge = Vector2(rect.get_center().x, rect.end.y)
	if edge.x >= 0.0:
		_press_bind = BayControls.press_bind(edge, _keyboard)
		_stage_node.add_child(_press_bind)


## How the kart is turned, over the bench's right end, for the device in hand, see
## [method BayControls.turn_hint]; under the rack, which comes out over it.
func _show_turn() -> void:
	if _turn_hint != null:
		_turn_hint.queue_free()
	var touch := TouchInput.enabled
	var pad := not (touch or _keyboard or not SettingsScreen.pad_plugged_in())
	_turn_hint = BayControls.turn_hint(touch, pad)
	_turn_hint.visible = open_part < 0
	_stage_node.add_child(_turn_hint)
	if tray != null:
		_stage_node.move_child(_turn_hint, tray.get_index())


## Puts the dialog away, the cursor going back to whatever had it before.
func close() -> void:
	if _closing:
		return
	_keep_name()
	_closing = true
	PlayerInput.typing = false
	var shades: Array[CanvasItem] = [_shade]
	MenuTheme.put_away(_pane, _gone, shades)


func is_closing() -> bool:
	return _closing


func _gone() -> void:
	if _from != null and is_instance_valid(_from) and _from.is_inside_tree():
		_from.grab_focus()
	put_away.emit()
	queue_free()


func _focus_first() -> void:
	if is_inside_tree() and not _closing:
		_rest_on(hooks[LEFT_HOOKS[0]])


## The cursor put on [param hook] without its part looked at, until it is moved: the kart standing,
## no rope from it and no hand of cards held up.
func _rest_on(hook: Control) -> void:
	_resting_on = hook
	hook.grab_focus()
	get_viewport().gui_focus_changed.connect(
		func(_control: Control) -> void: _resting_on = null, CONNECT_ONE_SHOT
	)
